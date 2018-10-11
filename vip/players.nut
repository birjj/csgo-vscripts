// Keeps track of players, allowing you to find players by team or userid
// Note that in order for the Userid binding to work, you *must* have your VMF
//  setup such that we can attach a listener to player_use (see events.nut)
// 
// Exposes:
//   ::Players.FindByUserid(userid)

::TEAM_T <- 2;
::TEAM_CT <- 3;

DoIncludeScript("vip/events.nut",null);

// represents a single player, bound to a player entity
class Player {
    Ent = null;
    Health = 0;
    PrevHealth = 0;
    Alive = false;
    Team = 0;

    Events = {};

    constructor(ply) {
        Ent = ply;
        Health = PrevHealth = Ent.GetHealth();
        Alive = Health > 0;
        Team = Ent.GetTeam();
    }
}

class PlayerManager {
    eventProxy = null;
    eventProxy_boundPlayer = null;
    userIdMappings = {};

    constructor() {
        GenerateEventProxy();
    }

    function GenerateEventProxy() {
        // create an info_game_event_proxy - we use this to fake player_use events
        eventProxy = Entities.CreateByClassname("info_game_event_proxy");
        eventProxy.__KeyValueFromString("event_name", "player_use");
        eventProxy.__KeyValueFromInt("range", 0);
        eventProxy_boundPlayer = null;

        // reset everything so that we don't have lingering outputs giving us false userids
        local ent = Entities.First();
        while (ent != null) {
            if (ent.IsValid() && ent.GetClassname() == "player") {
                if (ent.ValidateScriptScope()) {
                    local scope = ent.GetScriptScope();
                    if ("userid" in scope) {
                        delete scope.userid;
                    }
                    if ("generating_userid" in scope) {
                        delete scope.generating_userid;
                    }
                }
            }
            ent = Entities.Next(ent);
        }
    }

    function FindByUserid(userid) {
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player") {
                if (ent.ValidateScriptScope()) {
                    local scope = ent.GetScriptScope();
                    if (("userid" in scope) && scope.userid == userid) {
                        return ent;
                    }
                }
            }
            ent = Entities.Next(ent);
        }
        return null;
    }

    function GetPlayers(filter = null) {
        local outp = [];
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player") {
                if (filter == null || filter(ent)) {
                    outp.push(ent);
                }
            }
            ent = Entities.Next(ent);
        }
        return outp;
    }

    function GetCTs() {
        return GetPlayers(function(ply){
            return ply.GetTeam() == TEAM_CT;
        });
    }

    function GetTs() {
        return GetPlayers(function(ply){
            return ply.GetTeam() == TEAM_T;
        });
    }

    function Think() {
        local ent = Entities.First();
        // only check if we have an entity to check with
        if (eventProxy == null || !eventProxy.IsValid()) {
            return;
        }
        while (ent != null) {
            if (ent.IsValid() && ent.GetClassname() == "player") {
                if (ent.ValidateScriptScope()) {
                    local scope = ent.GetScriptScope();
                    if (!("userid" in scope) && !("generating_userid" in scope)) {
                        // printl("[Players] Found new player "+ent+" - getting his userid");
                        scope.generating_userid <- true;
                        eventProxy_boundPlayer = ent;
                        EntFireByHandle(eventProxy, "GenerateGameEvent", "", 0.0, ent, null);
                        return; // can only bind one per think because we need the output to fire first
                    } else {
                        if ("userid" in scope) {
                            // printl("[Players] Already know userid of player "+ent+": "+scope.userid);
                        } else {
                            // printl("[Players] Awaiting userid of player "+ent);
                        }
                    }
                }
            }
            ent = Entities.Next(ent);
        }
    }
}

if (!("Players" in getroottable())) {
    printl("[Players] Binding");
    ::AddEventListener("player_use", function(data){
        // if this is caused by our fake event
        if (::Players.eventProxy_boundPlayer != null && data.entity == 0) {
            printl("[Players] Got player "+::Players.eventProxy_boundPlayer+" for userid "+data.userid);
            local scope = ::Players.eventProxy_boundPlayer.GetScriptScope();
            if ("generating_userid" in scope) {
                scope.userid <- data.userid;
                delete scope.generating_userid;
                ::Players.eventProxy_boundPlayer = null;
            }
        }
    });
    ::Players <- PlayerManager();
} else {
    printl("[Players] Already has global instance - not rebinding");
    ::Players.GenerateEventProxy();
}