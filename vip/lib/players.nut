// https://github.com/birjolaxew/csgo-vscripts
// == PlayerManager
// Keeps track of players, allowing you to find players by team or userid
// Note that in order for the Userid binding to work, you *must* have your VMF
//  setup such that we can attach a listener to each of the following (see events.nut):
// - player_use (used for binding userids)
// - player_changename (used for getting player names)
// - player_team (used for getting player names)
// 
// Exposes:
//   ::Players (instance of PlayerManager)

::TEAM_T <- 2;
::TEAM_CT <- 3;

DoIncludeScript("vip/lib/events.nut",null);
DoIncludeScript("vip/lib/debug.nut",null);

// represents a single player, bound to a player entity
class Player {
    ent = null;
    userid = null;
    name = null;
    bot = false;

    constructor(ply) {
        ent = ply;
        ply.ValidateScriptScope();
        local scope = ply.GetScriptScope();
        scope.player_instance <- this;
    }

    function SetUserid(usrid) { userid = usrid; }
    function GetUserid() {
        if (userid == null) {
            return -1;
        }
        return userid;
    }

    function SetDisplayName(nme) { name = nme; }
    function GetDisplayName() {
        if (name == null) {
            return "[Unknown]";
        }
        return name;
    }

    function SetBot(bt) { bot = bt; }
    function IsBot() {
        return bot;
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
        local ent = Entities.First();;
        while (ent != null) {
            if (ent.GetClassname() == "player" && ent.IsValid() && ent.ValidateScriptScope()) {
                local scope = ent.GetScriptScope();
                if ("userid" in scope) {
                    delete scope.userid;
                }
                if ("generating_userid" in scope) {
                    delete scope.generating_userid;
                }
            }
            ent = Entities.Next(ent);
        }
    }

    function FindByUserid(userid) {
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player" && ent.ValidateScriptScope()) {
                local scope = ent.GetScriptScope();
                if (("userid" in scope) && scope.userid == userid) {
                    return ent;
                }
            }
            ent = Entities.Next(ent);
        }
        return null;
    }

    function FindInstanceByEntity(ent) {
        if (ent == null) { return null; }
        if (!ent.ValidateScriptScope()) { return null; }
        local scope = ent.GetScriptScope();
        if (!("player_instance" in scope)) { return null; }
        return scope.player_instance;
    }

    function FindDisplayName(ent) {
        local instance = FindInstanceByEntity(ent);
        if (instance == null) { return "<Unknown>"; }
        return instance.GetDisplayName();
    }

    function FindIsBot(ent) {
        local instance = FindInstanceByEntity(ent);
        if (instance == null) {
            log("[Players] Couldn't find entity while checking bot " + ent);
            return false;
        }
        return instance.IsBot();
    }

    function GetPlayers(filter = null) {
        local outp = [];
        local ent = Entities.First();
        while (ent != null) {
            if (filter == null || filter(ent)) {
                outp.push(ent);
            }
            ent = Entities.Next(ent);
        }
        return outp;
    }

    function GetPlayersInRadius(origin, radius, filter = null) {
        local outp = [];
        local players = PlayerManager.GetPlayers();
        foreach (ply in players) {
            local deltaVector = origin - ply.GetOrigin();
            if (deltaVector.Length() <= radius) {
                outp.push(ply);
            }
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
        // only check if we have an entity to check with
        if (eventProxy == null || !eventProxy.IsValid()) {
            return;
        }
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player" && ent.IsValid() && ent.ValidateScriptScope()) {
                local scope = ent.GetScriptScope();
                if (!("userid" in scope) && !("generating_userid" in scope)) {
                    // log("[Players] Found new player "+ent+" - getting his userid");
                    scope.generating_userid <- true;
                    eventProxy_boundPlayer = ent;
                    EntFireByHandle(eventProxy, "GenerateGameEvent", "", 0.0, ent, null);
                    return; // can only bind one per think because we need the output to fire first
                } else {
                    if ("userid" in scope) {
                        // log("[Players] Already know userid of player "+ent+": "+scope.userid);
                    } else {
                        // log("[Players] Awaiting userid of player "+ent);
                    }
                }
            }
            ent = Entities.Next(ent);
        }
    }
}

if (!("Players" in getroottable())) {
    log("[Players] Binding");
    ::_players_instances <- [];
    ::_players_userid_to_name <- {};
    ::_players_userid_to_bot <- {};

    // listen for name changes, or whether a player is a bot
    ::_players_name_updater <- function(userid, name) {
        log("[Players] Setting name of "+userid+" to "+name);
        ::_players_userid_to_name[userid] <- name;
        local instance = ::Players.FindInstanceByEntity(::Players.FindByUserid(userid));
        if (instance != null) {
            instance.SetDisplayName(name);
        }
    };
    ::_players_bot_updater <- function(userid, isbot) {
        log("[Players] Setting bot of "+userid+" to "+isbot);
        ::_players_userid_to_bot[userid] <- isbot;
        local instance = ::Players.FindInstanceByEntity(::Players.FindByUserid(userid));
        if (instance != null) {
            instance.SetBot(isbot);
        }
    };

    ::AddEventListener("player_connect", function(data) {
        ::_players_name_updater(data.userid, data.name);
    });
    ::AddEventListener("player_changename", function(data) {
        ::_players_name_updater(data.userid, data.newname);
    });
    ::AddEventListener("player_team", function(data) {
        if ("isbot" in data) {
            ::_players_bot_updater(data.userid, data.isbot);
        }
        if ("name" in data) {
            ::_players_name_updater(data.userid, data.name);
        }
    });

    // listen for our fake player_use, which gives us userid
    ::AddEventListener("player_use", function(data){
        // if this is caused by our fake event
        if (::Players.eventProxy_boundPlayer != null && data.entity == 0) {
            local ply = ::Players.eventProxy_boundPlayer;
            log("[Players] Got player "+ply+" for userid "+data.userid);
            local scope = ply.GetScriptScope();
            if ("generating_userid" in scope) {
                scope.userid <- data.userid;
                delete scope.generating_userid;
                if (ply.GetHealth() > 0) {
                    ::TriggerEvent("player_spawn", { userid = scope.userid });
                }
                local instance = Player(ply);
                instance.SetUserid(data.userid);
                if (data.userid in ::_players_userid_to_name) {
                    instance.SetDisplayName(::_players_userid_to_name[data.userid]);
                }
                if (data.userid in ::_players_userid_to_bot) {
                    instance.SetBot(::_players_userid_to_bot[data.userid]);
                }
                ::_players_instances.append(instance);
                ::Players.eventProxy_boundPlayer = null;
            }
        }
    });

    ::Players <- PlayerManager();
} else {
    log("[Players] Already has global instance - not rebinding");
    ::Players.GenerateEventProxy();
}