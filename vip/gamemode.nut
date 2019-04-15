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
    self.PrecacheModel("models/hostage/v_vip_arm.mdl");
    self.PrecacheModel("models/hostage/vip_carry.mdl");
    self.PrecacheModel("models/hostage/vip_ground.mdl");
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
::VIP_DEATHTIMER <- 8;
::VIP_BOTGRACETIME <- 10;
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
    vipCarrier = null;
    
    secondChance = true; // determine if VIP has second chance
    vipJustDowned = false;
    vipDowned = false; // used for starting bleeding out the VIP
	vipBleedOutHP = 100.0; // starting HP when VIP gets downed
    vipHostage = null; // is set when VIP first drops
    vipDownedTime = null; // set when VIP gets downed
    vipDownedOnce = false; // has VIP fallen once yet?
    vipJustBledOut = false; // toggled the instant VIP dies from bleeding
    vipSaved = false; // has VIP been saved from bleeding out?
    //vipInstaKill = false; // used to instantly kill the hostage if he dies for a second time.
	
    vipDiedToWorld = false;

    vipRunGraceTime = false;
    vipSetGraceTime = true;
    vipBotGraceTime = null; // window of time in seconds during which you can steal VIP status
    vipCanTransfer = true;

    isLive = false; // is set to true after freeze time
    shouldEndOnTeamWipe = false; // don't end on team wipe if we don't have anyone on one of the teams to begin with

    eClientCommand = null;
    lastIllegalWeapon = null; // allows us to drop the second time we switch to an illegal weapon
    lastIllegalTime = 0;
    lastHealthVIP = null; // used in case VIP disconnects
    spawnPositionVIP = null; // used in case VIP disconnects
    lastSeenPositionVIP = null; // used for taking over bots
    lastSeenAnglesVIP = null;
    hasHostageJustBeenPickedUp = false;

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
            lastSeenAnglesVIP = vip.GetAngles();
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
                EntFireByHandle(eGameRoundEnd, "EndRound_CounterTerroristsWin", "7", 0.0, null, null);
                
                //GAME_TEXT
                SendGameText("The Terrorists have been eliminated!", "2", "10");
                
                setLive(false);

                ::GiveMoneyCT(ECONOMY.ELIMINATION_CT, "Reward for eliminating the enemy team");
                ended = true;
            }
            if (!ended && IsRoundOver()) {
                
                //ALL HELICOPTERS DEPART
                local ent = Entities.FindByName(null, "*vip_relay_heli_takeoff");
                while (ent != null) {
                    // for some reason "*vip_rescue" matches some non-matching entities
                    local entName = ent.GetName();
                    if (entName != null && entName.find("vip_relay_heli_takeoff") == entName.len() - "vip_relay_heli_takeoff".len()) {
                        if (isLive) {
                            EntFireByHandle(ent, "Trigger", "", 0.0, null, null);
                        }
                    }
                    ent = Entities.FindByName(ent, "*vip_relay_heli_takeoff");
                }

                EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "7", 0.0, null, null);
                
                //GAME_TEXT
                SendGameText("The VIP failed to escape!", "1", "10");

                
                setLive(false);

                ::GiveMoneyT(ECONOMY.NO_ESCAPE, "Reward for not letting VIP escape");
                ended = true;
            }
            if (!ended && cts.len() == 0 && ts.len() == 0) {
                EntFireByHandle(eGameRoundEnd, "EndRound_Draw", "7", 0.0, null, null);
                setLive(false);
            }
        }

        // it takes 1 frame for the hostage to be spawned after VIP is downed - we also kill VIP's ragdoll here
        if (hasHostageJustBeenPickedUp == true) {
            local vip_hostage = Entities.FindByName(null, "vip_hostage");
            //local vip_hostage_dmg_filter = Entities.FindByName(null,"vip_filter_damage");
            if (vip_hostage!=null){
                vipHostage = vip_hostage;
                vip_hostage.SetModel("models/hostage/vip_ground.mdl");
                EntFireByHandle(vipHostage, "SetDamageFilter", "vip_filter_damage",0.0,null,null);
                vip_hostage.SetAngles(lastSeenAnglesVIP.x, lastSeenAnglesVIP.y, lastSeenAnglesVIP.z);


                hasHostageJustBeenPickedUp = false;
        
            }
        }

        // can only kill entity owners after 1 frame, this kills VIP Hostage main body after BecomeRagdoll
        if (vipJustBledOut){
            local tempHostage = Entities.FindByName(null,"vip_hostage");
            if (tempHostage!=null){
                EntFireByHandle(tempHostage,"kill","",0.0,null,null);
                vipJustBledOut = false;
            } else {
                printl("[VIP] Couldn't find tempHostage to destroy! WHAT!?");
            }
        }

        if (vipRunGraceTime){
            OnGraceTime();
        }

        if (vipDowned && !vipSaved){
            BleedOutVIP();
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
    
    // activate grace time
    function OnGraceTime(){
        if (vipSetGraceTime){
            vipBotGraceTime = Time()+::VIP_BOTGRACETIME;
            vipSetGraceTime = false;
        }

        local graceTime = vipBotGraceTime - Time();
        if (Time() >= vipBotGraceTime){
            printl("[VIP] Grace time is over");
            vipRunGraceTime = false;
        } else if (Time() < vipBotGraceTime){
            //print("[VIP] Can steal VIP status from BOTs in the next "+graceTime+" seconds");
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
        vipCarrier = null;

        lastIllegalWeapon = null;
        lastIllegalTime = 0;

        vipHostage = null;
        vipDowned = false;
        vipBleedOutHP = 100;
        vipSaved = false;

        vipDiedToWorld = false;
        secondChance = true;

        vipSetGraceTime = true;
        vipBotGraceTime = null;
        
        lastHealthVIP = null;
        spawnPositionVIP = null;

        local entVIP = null;
        while ((entVIP = Entities.FindByName(entVIP, ::VIP_TARGETNAME)) != null) {
            entVIP.SetHealth(100);
            EntFireByHandle(entVIP, "AddOutput", "targetname default", 0.0, null, null);
            if (entVIP.ValidateScriptScope()) {
                local scope = entVIP.GetScriptScope();
                if ("_vipPrevModel" in scope) {
                    entVIP.SetModel(scope._vipPrevModel);
                }
            }
        }
        /*local entCarrier = null;
        while ((entCarrier = Entities.FindByName(entCarrier, vipCarrier)) != null) {
            EntFireByHandle(entCarrier, "AddOutput", "targetname default", 0.0, null, null);
        }*/
    }

    // sets a player to be VIP
    function SetVIP(player) {
        printl("[VIP] Setting VIP to "+player);
        ResetVIP();

        SetEntityToVIP(player);
        
        vip.SetHealth(::VIP_MAXHEALTH);
        ::ShowMessageSome("Protect "+Players.FindDisplayName(vip)+" at all costs!", function(ply) {
            if (ply.GetTeam() == TEAM_CT) {
                return true;
            }
            return false;
        });
        ::ShowMessageSome(Players.FindDisplayName(vip) + " claims to have fucked your mother. Kill him!", function(ply) {
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

    function TransferVIP(newVIP){
        ResetVIP();
        SetVIP(newVIP);
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
    
    function OnVIPDowned(){
        printl("[VIP] VIP has been downed!");

        if (isLive){
            //This starts draining VIPs HP
            vipDowned = true;
            vipJustDowned = true;
            
            //GAME_TEXT
                    SendGameText("The VIP has been downed!", "1", "2");
                    
            //PLAY SOUND
            local ambientVipDown = Entities.FindByName(null, "vip_down_snd");
            if (ambientVipDown) {
                EntFireByHandle(ambientVipDown, "PlaySound", "", 0.5, null, null);
            } else {
                printl("[VIP] Couldn't find VIP DOWN sound");
            }
            
            local hMaker = Entities.FindByName(null, "vip_entity_maker");
            hMaker.SetOrigin(Vector(lastSeenPositionVIP.x,lastSeenPositionVIP.y,lastSeenPositionVIP.z + 16.0));
            //hMaker.SetAngles(lastSeenAnglesVIP.pitch, lastSeenAnglesVIP.yaw, lastSeenAnglesVIP.roll);
            EntFireByHandle(hMaker, "ForceSpawn","",0.0,null,null);
            DispatchParticleEffect("blood_pool",lastSeenPositionVIP,lastSeenAnglesVIP);
            
            

            local vipRagdoll = Entities.FindByClassnameNearest("cs_ragdoll", lastSeenPositionVIP, 256.0);
            if (vipRagdoll != null) {
                vipRagdoll.Destroy();
            }

            if (hasHostageJustBeenPickedUp == false){
                hasHostageJustBeenPickedUp = true;
            }
        }
    }
    
	function BleedOutVIP(){
        
        local bleedOutHP = null;
        local timeleft = null;

        if (vipJustDowned == true){
            vipDownedTime = Time();
            print("[VIP] Downed time = "+vipDownedTime);
            vipJustDowned = false;
        }
        
        if (vipBleedOutHP>0 && vipHostage != null){

            bleedOutHP = Time()-vipDownedTime;
            vipBleedOutHP = 100.0 - (bleedOutHP*(100.0/::VIP_DEATHTIMER));
            EntFireByHandle(vipHostage,"AddOutput","health "+vipBleedOutHP,0.0,null,null);

            local health = ceil(vipBleedOutHP);

            timeleft = ::VIP_DEATHTIMER - bleedOutHP;

            local textColor = "#990000";
            local msg1 = "VIP down and bleeding!\n You have <font color='"+textColor+"'>"+ format("%.1f", timeleft) + " sec" + "</font> to pick him up!";
            ::ShowMessageSome(msg1, function(ply){
                return ply.GetTeam() == TEAM_CT;
            });
        
            printl("[VIP] VIP HP = " +health );
        } 

        if (vipBleedOutHP<=0){
            FaintVIP();
        } 
	}
    
    function FaintVIP(){

        //This makes the hostage VIP collapse into its death.
        printl("[VIP] GAME IS OVER - VIP DIED");
        printl("[VIP] GAME IS OVER - VIP DIED");
        printl("[VIP] GAME IS OVER - VIP DIED");

        EntFireByHandle(vipHostage, "BecomeRagdoll", "",0.0,null,null);
        vipJustBledOut = true;
        
        vipDowned = false;
        secondChance = false;

        OnVIPDeath(null);
    }

    
    
    function OnVIPPickedUp(data){
        printl("[VIP] VIP has been picked up!");
        //local vip_vip_carrier = Entities.FindByName(null,"vip_carrier");
        local vip_hostage_carriable_prop = Entities.FindByClassname(null,"hostage_carriable_prop");
        local vip_hostage_viewmodel = Entities.FindByModel(null,"models/hostage/v_hostage_arm.mdl");
        
        if (vip_hostage_viewmodel!=null){
            vip_hostage_viewmodel.SetModel("models/hostage/v_vip_arm.mdl");
        } else printl("[VIP] There's no model called vip_hostage_viewmodel in the map");
        
        if (vip_hostage_carriable_prop!=null){
            vip_hostage_carriable_prop.SetModel("models/hostage/vip_carry.mdl");
        } else printl("[VIP] There's no entity called hostage_carriable_prop in the map");
        
        local vip_prop_pos = vip_hostage_carriable_prop.GetOrigin();
        //local vip_carrier = Entities.FindByClassnameNearest("player",vip_prop_pos,256.0);

        vipSaved = true;

        vipCarrier = ::Players.FindByUserid(data.userid);
        EntFireByHandle(vipCarrier, "AddOutput", "targetname vip_vip",0.0, null,null); 
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
		
        // TUNE HOSTAGE CVARS
        // I'd be very upset had Valve not implemented these _O_ Bless Gaben
        // Sorry aparently paragraphs break the code so all I have is this very long string of server commands
        local hostageCVars = "mp_hostages_rescuetime 0; mp_hostages_takedamage 1; cash_player_damage_hostage 0; cash_player_interact_with_hostage 0; cash_player_killed_hostage 0; cash_player_rescued_hostage 0; cash_team_hostage_alive 0; cash_team_hostage_interaction 0; cash_team_rescued_hostage 0; hostage_is_silent 1";
        EntFireByHandle(eServerCommand, "Command", hostageCVars, 0.0, null, null);

        SetVIP(SelectRandomCT());
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
        vipRunGraceTime = true;
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
                command = "slot3;slot2;"; //we switch to knife first in case player doesn't have a pistol
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

    function OnVIPDroppedByCarrier(data){
        local killedUnit = ::Players.FindByUserid(data.userid);
        if (killedUnit != null && killedUnit == vipCarrier){
            printl("[VIP] VIP WAS DROPPED, GAME OVER.");
            printl("[VIP] VIP WAS DROPPED, GAME OVER.");
            printl("[VIP] VIP WAS DROPPED, GAME OVER.");

            //End Round
            EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "7", 0.0, null, null);

            //Make him collapse
            FaintVIP();

            //Resets VIP Carrier
            EntFireByHandle(vipCarrier,"AddOutput", "targetname default", 0.0, null, null);

            //GAME_TEXT
            SendGameText("The VIP was assassinated!", "1", "10");

            
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
                EntFireByHandle(eGameRoundEnd, "EndRound_TerroristsWin", "7", 0.0, null, null);
                
                //GAME_TEXT
                SendGameText("The VIP was assassinated!", "1", "10");

                //HUD INFO
                ::ShowMessageSome("You let the VIP die dummy!", function(ply){
                return ply.GetTeam() == TEAM_CT;
                });
            
                setLive(false);
                

                ::GiveMoneyT(ECONOMY.VIP_KILLED, "You got that motherfucker!");
            } else {
                SubstituteVIP(newVIP);
            }
        }
        if (vipDiedToWorld == false && secondChance == true){
            secondChance = false;
            OnVIPDowned();
        }
        
    }

    // called when the VIP is hurt
    // used to display updates to the CTs

    function OnVIPHurt(data) {
        local health = data.health;
        printl("[VIP] VIP hurt! "+health);
        
        lastHealthVIP = data.health;

        local damage = data.dmg_health;
        if (damage > 600){
            printl("[VIP] VIP was killed by Trigger_Hurt");
            secondChance = false;
            vipDiedToWorld = true;
        }
        

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


    // called when the VIP is rescued - must be called by the map
    function OnVIPRescued() {
        printl("[VIP] VIP rescued!");
        EntFireByHandle(eClientCommand, "Command", "cheer", 0.0, vip, null);
        
        //GAME_TEXT
        SendGameText("The VIP escaped!", "2", "10");
        
        
        
        //ResetVIP();

        if (isLive) {
            EntFireByHandle(eGameRoundEnd, "EndRound_CounterTerroristsWin", "7", 0.0, null, null);
            setLive(false);

            ::GiveMoneyCT(ECONOMY.VIP_ESCAPED, "Reward for helping the VIP escape");
        }
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

    ::AddEventListener("player_use", function(data) {
        local user = ::Players.FindByUserid(data.userid);
        local ent = Entities.First();
        while (ent != null) {
            if (ent.entindex() == data.entity) {
                printl(""+user+" pressed use on "+ent);
                printl("("+(ent == ::gamemode_vip.vip)+"|"+(Players.FindIsBot(ent))+")");
                if (ent == ::gamemode_vip.vip && Players.FindIsBot(ent) == true) {
                    ::gamemode_vip.TransferVIP(user);
                }
                break;
            }
            ent = Entities.Next(ent);
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
        if (player != null && player == ::gamemode_vip.vipCarrier){
            ::gamemode_vip.OnVIPDroppedByCarrier(data);
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
       printl("[VIP] SOMEONE TOOK THE HOSTAGE");
       printl("[VIP] SOMEONE TOOK THE HOSTAGE");
       printl("[VIP] SOMEONE TOOK THE HOSTAGE");

        ::gamemode_vip.OnVIPPickedUp(data);

    });

    ::AddEventListener("hostage_stops_following", function(data) {
       printl("[VIP] HOSTAGE FELL!!!");
       printl("[VIP] HOSTAGE FELL!!!");
       printl("[VIP] HOSTAGE FELL!!!");

       //local vipCarrier = Players.FindByUserid(data.userid);
        //if (vipCarrier != null) {
            //::gamemode_vip.OnVIPPickedUp(data);
            //EntFireByHandle(vipCarrier, "AddOutput", "targetname " + ::VIP_TARGETNAME, 0.0, null, null);
        //}
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

    ::AddEventListener("player_connect", function(data) {
        local playerUserID = data.userid;
        local playerName = data.name;
        //local playerOldName = data.oldname;
        printl("[VIP] UserID "+playerUserID+"s nickname is: "+playerName);
    });
}