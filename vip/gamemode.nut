DoIncludeScript("vip/events.nut", null);
DoIncludeScript("vip/debug.nut", null);
DoIncludeScript("vip/players.nut", null);
DoIncludeScript("vip/ui.nut", null);
DoIncludeScript("vip/money.nut", null);
DoIncludeScript("vip/chat.nut", null);

function Think() {
    local root = getroottable();
    if ("Players" in root) {
        ::Players.Think();
    }
    if ("gamemode_vip" in root) {
        ::gamemode_vip.Think();
    }
}

::VIP_TARGETNAME <- "vip_vip";
::VIP_VERSION <- "v0.0.1";

::VIP_WEAPON_WHITELIST <- [
    // pistols
    "hkp2000",
    "usp_silencer",
    // knives
    "knife",
    "taser",
    // nades
    "hegrenade",
    "flashbang",
    "decoy",
    "incgrenade",
    "molotov",
    "smokegrenade"
];
::VIP_MAXHEALTH <- 200;

class GameModeVIP {
    vip = null;
    isLive = false; // is set to true after freeze time
    shouldEndOnTeamWipe = false; // don't end on team wipe if we don't have anyone on one of the teams to begin with

    eClientCommand = null;
    lastIllegalWeapon = null; // allows us to drop the second time we switch to an illegal weapon
    lastIllegalTime = 0;

    eGameRoundEnd = null;
    eServerCommand = null;
	
	timeLimit = null;
	resetClock = false;
	
	//Saving VIP info in case he disconnects
	lastHealthVIP = null;
	spawnPositionVIP = null;

    function Think() {
        // VIP entity could go invalid for a multitude of reasons (disconnect, etc.)
        if (vip != null && !vip.IsValid()) {
            printl("[VIP] === VIP INVALID!");
            ResetVIP();
			SelectRandomVIP();
        }
		
        // check if one of the teams have been wiped off
        if (isLive) {
            local cts = Players.GetPlayers(function(ply){
                return ply.GetTeam() == TEAM_CT && ply.GetHealth() > 0;
            });
            local ts = Players.GetPlayers(function(ply){
                return ply.GetTeam() == TEAM_T && ply.GetHealth() > 0;
            });
            // printl("[VIP] We have "+cts.len()+" CTs, "+ts.len()+" Ts alive ("+shouldEndOnTeamWipe+")");

            local ended = false;
            if (shouldEndOnTeamWipe && cts.len() == 0) {
                EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "5", 0.0, null, null);
                isLive = false;

                ::GiveMoneyT(3000, "Reward for eliminating the enemy team");
                ended = true;
            }
            if (shouldEndOnTeamWipe && ts.len() == 0) {
                EntFireByHandle(eGameRoundEnd, "EndRound_CounterTerroristsWin", "5", 0.0, null, null);
                isLive = false;

                ::GiveMoneyCT(3000, "Reward for eliminating the enemy team");
                ended = true;
            }
            if (!ended && cts.len() == 0 && ts.len() == 0) {
                EntFireByHandle(eGameRoundEnd, "EndRound_Draw", "5", 0.0, null, null);
                isLive = false;
            }
			
			if (RoundOverCheck() && isLive){
				EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "5", 0.0, null, null);
				::GiveMoneyT(6969, "Reward for not letting VIP escape");
				isLive = false;
				ended = true;
			}
        }
    }

    function OnRoundStart() {
        printl("[VIP] Starting " + ::VIP_VERSION + " on " + _version_);
        eClientCommand = Entities.CreateByClassname("point_clientcommand");
        eGameRoundEnd = Entities.CreateByClassname("game_round_end");
        eServerCommand = Entities.CreateByClassname("point_servercommand");
        isLive = false;
		resetClock = true;

        EntFireByHandle(eServerCommand, "Command", "mp_ignore_round_win_conditions 0", 0.0, null, null);

        SelectRandomVIP();
    }

	function SelectRandomVIP(){
		local cts = Players.GetCTs();
        if (cts.len() != 0) {
            printl("[VIP] Picking from "+cts.len()+" CTs.");
            local vipPly = null;
            while (vipPly == null || !vipPly.IsValid()) {
                vipPly = cts[RandomInt(0, cts.len() - 1)];
            }
            SetVIP(vipPly);
        }
	}
	
	// Reselects VIP if VIP disconnect AND VIP has not taken any damage. New VIP should not gain any HP, just gets VIP status and is teleported to original VIP spawn.
	/*
		Under the following conditions:
		- Original VIP 	must NOT have taken damage in the last 10 seconds.
		- New VIP 		must NOT have taken damage in the last 10 seconds.
		- Round must NOT have more than 30 seconds played.
		- New VIP takes the lowest HP between his and Original VIP. Example: If Original VIP had 1 hp before disconnect, new VIP must have 1 hp too.
		- New VIP is teleported back to Original VIP spawn position and all VIP restrictions are applied.
	*/
	
	function ReselectRandomVIP(){
	
	
	}
	
	function SetSubVIP(player){
        printl("[VIP] Setting Sub VIP to "+player);
        ResetVIP();
        vip = player;
		
		// If Original VIP had less HP than new VIP - replace with Original VIP HP
		
		local healthSubVIP = vip.GetHealth();
		if (healthSubVIP > lastHealthVIP){ 
			vip.SetHealth(lastHealthVIP);
		}
		
        ::ShowMessageSome("Substitute VIP has been selected, protect him!", function(ply) {
            if (ply.GetTeam() == TEAM_CT) {
                EntFireByHandle(ply, "color", "0 0 255", 0.0, null, null);
                return true;
            }
            return false;
        });
        ::ShowMessageSome("The VIP claims to have fucked your mother. Kill him!", function(ply) {
            if (ply.GetTeam() == TEAM_T) {
                EntFireByHandle(ply, "color", "255 0 0", 0.0, null, null);
                return true;
            }
            return false;
        });
        ::ShowMessage("You're the VIP. Don't fuck it up now", vip, "color='#F00'");
        EntFireByHandle(vip, "color", "0 255 0", 0.0, null, null);
        EntFireByHandle(vip, "AddOutput", "targetname " + ::VIP_TARGETNAME, 0.0, null, null);
    }
	
    function OnFreezeEnd() {
        if (vip && vip.IsValid() && !ScriptIsWarmupPeriod()) {
            isLive = true;
            printl("[VIP] Round freeze ended");
            EntFireByHandle(eServerCommand, "Command", "mp_ignore_round_win_conditions 1", 0.0, null, null);

            // check to make sure we have enough players to play
            local cts = Players.GetPlayers(function(ply){
                return ply.GetTeam() == TEAM_CT && ply.GetHealth() > 0;
            });
            local ts = Players.GetPlayers(function(ply){
                return ply.GetTeam() == TEAM_T && ply.GetHealth() > 0;
            });
            if (cts.len() != 0 && ts.len() != 0) {
                shouldEndOnTeamWipe = true;
            }

            // we switch to knife on VIP once freeze time ends
            // this ensures that our item_equip listener cannot trigger before we know of the VIPs 
            EntFireByHandle(eClientCommand, "Command", "slot3", 0.0, vip, null);
        }
    }
	
	function RoundOverCheck(){
		
		if (resetClock){
			timeLimit = Time()+timeLimit;
			resetClock = false;
		}
		local currentTime = Time();
		if (currentTime<timeLimit){
		return false;}
		if(currentTime>=timeLimit){return true;}
	}

    // removes the current VIP, resetting all state
    function ResetVIP() {
        printl("[VIP] Resetting VIP");
        vip = null;
        lastIllegalWeapon = null;
        lastIllegalTime = 0;
		
		lastHealthVIP = null;
		spawnPositionVIP = null;

        local ent = null;
        while ((ent = Entities.FindByName(ent, ::VIP_TARGETNAME)) != null) {
            EntFireByHandle(ent, "AddOutput", "targetname default", 0.0, null, null);
        }
    }
	
	
	function CheckDisconnectVIP(){
		printl("Checking if VIP disconnected");
		if (vip != null ){
			printl("Someone disconnect but was not the VIP - Proceed.")
		}
		if (vip == null ){
			printl("VIP DISCONNECTED!!!")
			
		}
	}
	
	

    // sets a player to be VIP
    function SetVIP(player) {
        printl("[VIP] Setting VIP to "+player);
        ResetVIP();
        vip = player;
		
		vip.SetHealth(::VIP_MAXHEALTH);
        ::ShowMessageSome("Protect the VIP at all costs!", function(ply) {
            if (ply.GetTeam() == TEAM_CT) {
                EntFireByHandle(ply, "color", "0 0 255", 0.0, null, null);
                return true;
            }
            return false;
        });
        ::ShowMessageSome("The VIP claims to have fucked your mother. Kill him!", function(ply) {
            if (ply.GetTeam() == TEAM_T) {
                EntFireByHandle(ply, "color", "255 0 0", 0.0, null, null);
                return true;
            }
            return false;
        });
        ::ShowMessage("You're the VIP. Don't fuck it up now", vip, "color='#F00'");
        EntFireByHandle(vip, "color", "0 255 0", 0.0, null, null);
        EntFireByHandle(vip, "AddOutput", "targetname " + ::VIP_TARGETNAME, 0.0, null, null);
    }

    // switches/drops away from illegal weapons
    function OnVIPWeapon(data) {
        printl("[VIP] Got VIP weapon switch");
        ::printtable(data);

        local isLegal = false;
        foreach (item in VIP_WEAPON_WHITELIST) {
            if (data.item == item) {
                isLegal = true;
                break;
            }
        }
        if (!isLegal) {
            local timeDelta = Time() - lastIllegalTime;
            printl("[VIP] That man, officer! " + lastIllegalWeapon + " - " + timeDelta);
            local command = "drop";
            local message = "Only USP/P2000 is allowed when you're the VIP";
            if (lastIllegalWeapon != data.item || timeDelta > 5 || timeDelta == 0) {
                command = "slot3";
                message = message + "\nYou can drop the weapon by switching to it again";
            } else {
                ::GiveMoney(100, vip);
            }
            ::ShowMessage(message, vip, "color='#F00'", 0.05);
            EntFireByHandle(eClientCommand, "Command", command, 0.0, vip, null);
            if (command == "drop") {
                lastIllegalWeapon = null;
                lastIllegalTime = 0;
            } else {
                lastIllegalWeapon = data.item;
                lastIllegalTime = Time();
            }
        }
    }

    // called when the VIP is RIP
    function OnVIPDeath(data) {
        printl("[VIP] VIP dieded :(");
        ResetVIP();

        if (isLive) {
            EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "5", 0.0, null, null);
            isLive = false;

            ::GiveMoneyT(4999, "You got that motherfucker!");
        }
    }

    // called when the VIP is rescued - must be called by the map
    function OnVIPRescued() {
        printl("[VIP] VIP rescued!");
        ResetVIP();

        if (isLive) {
            EntFireByHandle(eGameRoundEnd, "EndRound_CounterTerroristsWin", "5", 0.0, null, null);
            isLive = false;

            ::GiveMoneyCT(1337, "Reward for helping the VIP escape");
        }
    }

    // called when the VIP is hurt
    // used to display updates to the CTs
    function OnVIPHurt(data) {
        local health = data.health;
        printl("[VIP] VIP hurt! "+health);
		
		lastHealthVIP = data.health;

        // colors go hsl(0, 100%, 30%), hsl(0, 100%, 45%), hsl(25,100%,50%), hsl(55,100%,47%), hsl(70, 100%, 47%, 1), hsl(100, 100%, 45%, 1)
        //           dark red         , red              , orange          , yellow          , yellow-green         , green
        local color = null;
        if (health <= 0.05 * ::VIP_MAXHEALTH) { color = "#990000"; }
        if (color == null && health <= 0.1 * ::VIP_MAXHEALTH) { color = "#E60000"; }
        if (color == null && health <= 0.25 * ::VIP_MAXHEALTH) { color = "#FF6A00"; }
        if (color == null && health <= 0.5 * ::VIP_MAXHEALTH) { color = "#F0DC00"; }
        if (color == null && health <= 0.75 * ::VIP_MAXHEALTH) { color = "#C8F000"; }
        if (color == null) { color = "#4CE600"; }

        local msg = "VIP has <font color='"+color+"'>"+ health + " HP" + "</font> left.";
        if (health == 0) {
            msg = "VIP is <font color='"+color+"'>DEAD</font>!";
        }
        ::ShowMessageSome(msg, function(ply){
            return ply.GetTeam() == TEAM_CT;
        });
    }

    // called when a player spawns
    // used to pick a new VIP during warmup or freezetime
    function OnPlayerSpawn(data) {
        printl("[VIP] Player spawned " + ::Players.FindByUserid(data.userid));
        local player = ::Players.FindByUserid(data.userid);
        if (player.GetTeam() == TEAM_CT) {
            // if we don't have a VIP, and we aren't live (warmup or freezetime), pick this new guy as VIP
            if (!isLive && vip == null) {
                printl("[VIP] Setting respawned player to VIP during warmup/freezetime");
                SetVIP(player);
            }
        }
    }
}

if (!("gamemode_vip" in getroottable())) {
    ::gamemode_vip <- GameModeVIP();

    ::AddEventListener("item_equip", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player != null && player == ::gamemode_vip.vip) {
            ::gamemode_vip.OnVIPWeapon(data);
        }
    });
    ::AddEventListener("player_death", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player != null && player == ::gamemode_vip.vip) {
            ::gamemode_vip.OnVIPDeath(data);
        }
    });
    ::AddEventListener("player_spawn", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player != null) {
            ::gamemode_vip.OnPlayerSpawn(data);
        }
    });
    ::AddEventListener("player_hurt", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player != null && player == ::gamemode_vip.vip) {
            ::gamemode_vip.OnVIPHurt(data);
        }
    });
    ::AddEventListener("player_disconnect", function(data) {
		::gamemode_vip.CheckDisconnectVIP();
    });
	
	::AddEventListener("round_start", function(data) {
		//timeLimit = data.timelimit;
		::gamemode_vip.timeLimit = data.timelimit;
        ::gamemode_vip.RoundOverCheck();
    });
	
    ::AddEventListener("round_freeze_end", function(data) {
        ::gamemode_vip.OnFreezeEnd();
    });
}