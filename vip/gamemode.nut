/**
 * https://github.com/birjolaxew/csgo-vscripts
 * VIP Gamemode
 * ---
 * CTs must escort the VIP to the chopper - Ts must assassinate the VIP before that happens.
 */
DoIncludeScript("vip/lib/events.nut", null);
DoIncludeScript("vip/lib/debug.nut", null);
DoIncludeScript("vip/lib/players.nut", null);
DoIncludeScript("vip/lib/ui.nut", null);
DoIncludeScript("vip/lib/money.nut", null);
DoIncludeScript("vip/lib/chat.nut", null);

function Think() {
    local root = getroottable();
    if ("Players" in root) {
        ::Players.Think();
    }
    if ("gamemode_vip" in root) {
        ::gamemode_vip.Think();
    }
}

function Precache(){
    self.PrecacheModel("models/player/custom_player/legacy/ctm_heavy2.mdl");
}


::VIP_TARGETNAME <- "vip_vip";
::VIP_VERSION <- "v0.0.1";

::VIP_WEAPON_WHITELIST <- [
    // pistols
    "hkp2000",
    "usp_silencer",
    "elite",
    "cz75a",
    "p250",
    "tec9",
    "fiveseven",
    "deagle",
    "revolver",
    
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
::VIP_MAXHEALTH <- 150;
::ECONOMY <- {
    ELIMINATION_CT = 2000, // reward for CTs when they kill all Ts
    ELIMINATION_T = 2000, // reward for Ts when they kill all CTs
    NO_ESCAPE = 2000, // reward for Ts when the time runs out without an escape
    VIP_KILLED = 2000, // reward for Ts when the VIP is killed
    VIP_KILLER = 2500, // extra reward for the one person who killed the VIP
    VIP_ESCAPED = 3500 // reward for CTs when the VIP escapes
};

class GameModeVIP {
    vip = null;
	
	secondChance = true; // determine if VIP has second chance
    isLive = false; // is set to true after freeze time
    shouldEndOnTeamWipe = false; // don't end on team wipe if we don't have anyone on one of the teams to begin with

    eClientCommand = null;
    lastIllegalWeapon = null; // allows us to drop the second time we switch to an illegal weapon
    lastIllegalTime = 0;
    lastHealthVIP = null; // used in case VIP disconnects
    spawnPositionVIP = null; // used in case VIP disconnects
    lastSeenPositionVIP = null; // used for taking over bots

    eGameRoundEnd = null;
    eServerCommand = null;
    
    timeLimit = null; // amount of time a round lasts
    roundEndTime = null; // timestamp at which current round ends
    

    function Think() {
        // VIP entity could go invalid for a multitude of reasons (disconnect, etc.)
        if (vip != null && !vip.IsValid()) {
            printl("[VIP] === VIP INVALID!");
            OnVIPDeath(null);
        }

        if (vip != null && vip.GetHealth() > 0) {
            lastSeenPositionVIP = vip.GetOrigin();
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
            if (!ended && shouldEndOnTeamWipe && ts.len() == 0) {
                EntFireByHandle(eGameRoundEnd, "EndRound_CounterTerroristsWin", "5", 0.0, null, null);
				
				//GAME_TEXT
				SendGameText("The Terrorists have been eliminated!", "2", "10");
				
                setLive(false);

                ::GiveMoneyCT(ECONOMY.ELIMINATION_CT, "Reward for eliminating the enemy team");
                ended = true;
            }
            if (!ended && IsRoundOver()) {
                EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "5", 0.0, null, null);
				
				//GAME_TEXT
				SendGameText("The VIP failed to escape!", "1", "10");

				
                setLive(false);

                ::GiveMoneyT(ECONOMY.NO_ESCAPE, "Reward for not letting VIP escape");
                ended = true;
            }
            if (!ended && cts.len() == 0 && ts.len() == 0) {
                EntFireByHandle(eGameRoundEnd, "EndRound_Draw", "5", 0.0, null, null);
                setLive(false);
            }
        }
    }
	
	function SendGameText (message, color, duration){
	//GAME_TEXT
	local vip_text_round_end = Entities.FindByName(null, "vip_text_round_end");
	local presetColor = null;
			if (color == "0"){ presetColor = "255 255 255";} 
	else 	if (color == "1"){ presetColor = "188 168 116";} 
	else 	if (color == "2"){ presetColor = "168 197 221";}
	EntFireByHandle(vip_text_round_end, "SetTextColor", presetColor, 0.0,null,null);			// Sets color 0 = WHITE || 1 = YELLOW || 2 = BLUE
	EntFireByHandle(vip_text_round_end, "SetText", message,0.0,null,null);							// Sets message
	EntFireByHandle(vip_text_round_end, "AddOutput", "holdtime "+ duration, 0.0,null,null);	// Sets duration
	EntFireByHandle(vip_text_round_end, "Display", "",0.0,null,null);									// Displays Game_Text

	}

    // sets `isLive` to a value, updating necessary entities
    function setLive(value) {
        isLive = value;
        local ent = Entities.FindByName(null, "*vip_rescue");
        while (ent != null) {
            // for some reason "*vip_rescue" matches some non-matching entities
            local entName = ent.GetName();
            if (entName != null && entName.find("vip_rescue") == entName.len() - "vip_rescue".len()) {
                printl("[VIP] Enabling rescue trigger "+ent);
                if (isLive) {
                    EntFireByHandle(ent, "Enable", "", 0.0, null, null);
                } else {
                    EntFireByHandle(ent, "Disable", "", 0.0, null, null);
                }
            }
            ent = Entities.FindByName(ent, "*vip_rescue");
        }
    }
    
    // checks if the round is over due to time
    function IsRoundOver(){
        local currentTime = Time();
        if (currentTime < roundEndTime) {
            return false;
        }
        return true;
    }

    // returns a random alive CT player
    function SelectRandomCT(){
        local cts = Players.GetCTs();
        if (cts.len() != 0) {
            printl("[VIP] Picking from "+cts.len()+" CTs.");
            local vipPly = null;
            local tries = 0;
            while (vipPly == null || !vipPly.IsValid() || vipPly.GetHealth() == 0) {
                if (++tries > cts.len()) {
                    printl("[VIP] Couldn't find a random CT");
                    return null;
                }
                vipPly = cts[RandomInt(0, cts.len() - 1)];
            }
            return vipPly;
        }
        return null;
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
            ent.SetHealth(100);
            EntFireByHandle(ent, "AddOutput", "targetname default", 0.0, null, null);
            if (ent.ValidateScriptScope()) {
                local scope = ent.GetScriptScope();
                if ("_vipPrevModel" in scope) {
                    ent.SetModel(scope._vipPrevModel);
                }
            }
        }
    }

    // sets a player to be VIP
    function SetVIP(player) {
        printl("[VIP] Setting VIP to "+player);
        ResetVIP();

        SetEntityToVIP(player);
        
        vip.SetHealth(::VIP_MAXHEALTH);
        ::ShowMessageSome("Protect the VIP at all costs!", function(ply) {
            if (ply.GetTeam() == TEAM_CT) {
                return true;
            }
            return false;
        });
        ::ShowMessageSome("The VIP claims to have fucked your mother. Kill him!", function(ply) {
            if (ply.GetTeam() == TEAM_T) {
                return true;
            }
            return false;
        });
        ::ShowMessage("You're the VIP. Don't fuck it up now", vip, "color='#F00'");
		local vip_text_notification = Entities.FindByName(null, "vip_text_notification");
		EntFireByHandle(vip_text_notification, "Display", "",0.0,player,player);
        EntFireByHandle(eClientCommand, "Command", "coverme", 0.0, vip, null);
        
        local hint_protect = Entities.FindByName(null, "vip_hint_protect");
        EntFireByHandle(hint_protect, "AddOutput", "hint_target ::GameModeVIP.vip", 0.5, null, null);
        EntFireByHandle(hint_protect, "ShowHint", "", 0.5, player, player);
        
        local ambient = Entities.FindByName(null, "vip_snd");
        if (ambient) {
            ambient.SetOrigin(player.EyePosition());
            EntFireByHandle(ambient, "PlaySound", "", 0.5, player, player);
        } else {
            printl("[VIP] Couldn't find VIP sound");
        }
    }

    // sets a player to be substitute VIP if the current VIP becomes invalid for some reason (e.g. disconnect)
    function SubstituteVIP(player){
        printl("[VIP] Setting substitute VIP to "+player);

        // make sure we grab last health before overwriting stuff
        local lastHealth = lastHealthVIP;
        if (lastHealth == null || lastHealth == 0) {
            lastHealth = VIP_MAXHEALTH;
        }

        ResetVIP();
        SetEntityToVIP(player);
        EntFireByHandle(eClientCommand, "Command", "slot2", 0.0, vip, null);
        
        // If original VIP had less HP than new VIP - replace with original VIP HP
        local healthSubVIP = vip.GetHealth();
        if (healthSubVIP > lastHealth){ 
            vip.SetHealth(lastHealth);
        }
        
        ::ShowMessage("You're the VIP. Don't fuck it up now", vip, "color='#F00'");
    }

    // updates an entity so it's VIP (sets local reference, updates targetname, updates model, etc.)
    // does *not* set the health of the entity
    function SetEntityToVIP(ent) {
        vip = ent;
        EntFireByHandle(ent, "AddOutput", "targetname " + ::VIP_TARGETNAME, 0.0, null, null);
        if (ent.ValidateScriptScope()) {
            local scope = ent.GetScriptScope();
            scope._vipPrevModel <- ent.GetModelName();
        }
        ent.SetModel("models/player/custom_player/legacy/ctm_heavy2.mdl");
    }
	
	function SurrenderVIP(){
		printl("[VIP] VIP has been downed!");
		
		//GAME_TEXT
				SendGameText("The VIP was downed!", "1", "2");
				
		
		//PLAY SOUND
		local ambientVipDown = Entities.FindByName(null, "vip_down_snd");
        if (ambientVipDown) {
            EntFireByHandle(ambientVipDown, "PlaySound", "", 0.5, null, null);
        } else {
            printl("[VIP] Couldn't find VIP DOWN sound");
        }
		
		//local hostage = Entities.CreateByClassname("hostage_entity");
		//printl("<<<<< THIS HERE THE FUKEN HOSTAGE_ENTITY: " + hostage + " >>>>>");
		//hostage.SetOrigin(lastSeenPositionVIP);
		
		
		//local entMaker = Entities.FindByName(null, "vip_entity_maker");
		//EntFireByHandle(entMaker, "SpawnEntityAtLocation","lastSeenPositionVIP, 0 0 0",0.0,null,null);
		
		
		//entMaker.SpawnEntityAtLocation(lastSeenPositionVIP, 0 0 0);
		
		
		
		
		
		//local vip_hostage = Entities.CreateByClassname("vip_hostage_entity");
		//vip_hostage.SetOrigin(::gamemode_vip.lastSeenPositionVIP);
		
		//SpawnEntity();
		
		//local hostage = Entities.CreateByClassname("hostage_entity");
		//hostage.SetOrigin(lastSeenPositionVIP);

	
		//local vip_hostage = Entities.FindByName(null, "vip_hostage");
		
		//local vip_hostage_dummy = Entities.FindByName(null,"vip_hostage_dummy");
		
		//EntFireByHandle(vip_hostage, "DisableDraw", "", 0.0, null, null);
		
		
        //vip_hostage.SetModel("models/player/custom_player/legacy/ctm_heavy2.mdl");
		//EntFireByHandle(vip_hostage_dummy, "SetAnimation", "surrender", 0.0, null, null);
		
		
	}
	
	function PickupVIP(){
		printl("[VIP] VIP has been picked up!");
		
	}
	
	
	

    // ***
    // Event listeners
    // ***

    // fired when round starts
    function OnRoundStart() {
        printl("[VIP] Starting " + ::VIP_VERSION + " on " + _version_);
        eClientCommand = Entities.CreateByClassname("point_clientcommand");
        eGameRoundEnd = Entities.CreateByClassname("game_round_end");
        eServerCommand = Entities.CreateByClassname("point_servercommand");
        setLive(false);

        EntFireByHandle(eServerCommand, "Command", "mp_ignore_round_win_conditions 0", 0.0, null, null);

        SetVIP(SelectRandomCT());
		//SurrenderVIP();
    }
    
    
    // fired when round actually starts (freeze time is over)
    function OnFreezeEnd() {
        if (vip && vip.IsValid() && !ScriptIsWarmupPeriod()) {
            setLive(true);
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
            EntFireByHandle(eClientCommand, "Command", "slot2", 0.0, vip, null);
        }

        if (timeLimit != null && timeLimit > 0) {
            printl("[VIP] Updating round end time: "+timeLimit);
            roundEndTime = Time() + timeLimit; // timeLimit has been updated before this is called
        }
    }
    
    // fired when VIP switches weapons
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
            local message = "Only pistols are allowed when you're the VIP";
            if (lastIllegalWeapon != data.item || timeDelta > 5 || timeDelta == 0) {
                command = "slot2";
                message = message + "\nYou can drop the weapon by switching to it again";
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

        // if it is warmup, pick a random CT player to be the new VIP
        local newVIP = SelectRandomCT();

		
		if (secondChance == false){
			if (isLive || newVIP == null) {
				ResetVIP();
				EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "5", 0.0, null, null);
				
				//GAME_TEXT
				SendGameText("The VIP was assassinated!", "1", "10");
			
				setLive(false);
				

				::GiveMoneyT(ECONOMY.VIP_KILLED, "You got that motherfucker!");
			} else {
				SubstituteVIP(newVIP);
			}
		} else if (secondChance == true){
		SurrenderVIP();
		}
    }

    // called when the VIP is rescued - must be called by the map
    function OnVIPRescued() {
        printl("[VIP] VIP rescued!");
        EntFireByHandle(eClientCommand, "Command", "cheer", 0.0, vip, null);
		
		//GAME_TEXT
		SendGameText("The VIP escaped!", "2", "10");
		
		
		
        //ResetVIP();

        if (isLive) {
            EntFireByHandle(eGameRoundEnd, "EndRound_CounterTerroristsWin", "5", 0.0, null, null);
            setLive(false);

            ::GiveMoneyCT(ECONOMY.VIP_ESCAPED, "Reward for helping the VIP escape");
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
            local attacker = ::Players.FindByUserid(data.attacker);
            ::gamemode_vip.OnVIPDeath(data);
            if (attacker != null) {
                ::GiveMoney(ECONOMY.VIP_KILLER, attacker);
            }
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
        // ::gamemode_vip.CheckDisconnectVIP();
    });
    
    ::AddEventListener("round_start", function(data) {
        ::gamemode_vip.timeLimit = data.timelimit;
        ::gamemode_vip.OnRoundStart();
    });
	
	::AddEventListener("hostage_follows", function(data) {
        ::gamemode_vip.PickupVIP();
    });
    
    ::AddEventListener("round_end", function(data) {
        ::gamemode_vip.ResetVIP();
    });
    
    ::AddEventListener("bot_takeover", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        local botguy = ::Players.FindByUserid(data.botid);
        if (botguy == ::gamemode_vip.vip){
            ::gamemode_vip.SubstituteVIP(player);
            printl("[VIP] Human took over bot VIP");
        }
    });
    
    ::AddEventListener("round_freeze_end", function(data) {
        ::gamemode_vip.OnFreezeEnd();
    });
}