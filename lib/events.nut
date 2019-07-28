/**
 * https://github.com/birjolaxew/csgo-vscripts
 * == Event listener
 * Listen for in-game events
 * The callback functions are called directly with the event data
 * In order for this to work, you must manually add logic_eventlistener to your world
 * This logic_eventlistener should have the following keyvalues:
 *   - EventName the_event_you_want_to_listen_to
 *   - FetchEventData 1
 * It should also have the following output:
 *   - OnEventFired name_of_your_logic_eventlistener RunScriptCode ::TriggerEvent(THE_EVENT_YOU_WANT_TO_LISTEN_TO, event_data)
 * Note that !self does *not* work for name_of_your_logic_eventlistener.
 *
 * SPECIAL CASE: If an event is triggered twice in the same frame, the data will be that of the last trigger
 *               Notably this happens on multikills (killing two players with one bullet) and player_death event.
 *               For that case, create a trigger_brush in your map with the name "game_playerdie"
 *               This will trigger the event "game_playerdie" with the victim ent as the only parameter
 *
 * Exposes:
 *   ::AddEventListener("event-name", function(){})
 *   ::RemoveEventListener("event-name", function(){})
 *   ::TriggerEvent("event-name")
 */

::ITEM_EQUIP <- "item_equip";
::PLAYER_USE <- "player_use";
::PLAYER_DEATH <- "player_death";
::PLAYER_CONNECT <- "player_connect";
::PLAYER_CONNECT_FULL <- "player_connect_full";
::PLAYER_CONNECT_CLIENT <- "player_connect_client";
::PLAYER_DISCONNECT <- "player_disconnect";
::PLAYER_CHANGENAME <- "player_changename";
::PLAYER_TEAM <- "player_team";
::ROUND_START <- "round_start";
::ROUND_FREEZE_END <- "round_freeze_end";
::PLAYER_SPAWN <- "player_spawn";
::PLAYER_HURT <- "player_hurt";
::BOT_TAKEOVER <- "bot_takeover";
::INSPECT_WEAPON <- "inspect_weapon";
::ROUND_END <- "round_end";
::HOSTAGE_FOLLOWS <- "hostage_follows";
::HOSTAGE_STOPS_FOLLOWING <- "hostage_stops_following";

DoIncludeScript("lib/debug.nut",null);

if (!("_eventsScope" in getroottable())) {
    // each event is an array of listeners
    ::_eventsScope <- {};
    ::_eventsScope.listeners <- {};

    ::AddEventListener <- function(name, cb) {
        Log("[Events] Adding event listener for " + name);
        if (!(name in ::_eventsScope.listeners)) {
            ::_eventsScope.listeners[name] <- [];
        }
        ::_eventsScope.listeners[name].push(cb);
    };
    ::RemoveEventListener <- function(name, cb) {
        if (name in ::_eventsScope.listeners) {
            local ind = ::_eventsScope.listeners[name].find(cb);
            if (ind != null) {
                ::_eventsScope.listeners[name].remove(ind);
            }
        }
    };
    ::TriggerEvent <- function(name, data=null) {
        Log("[Events] Triggering event for " + name);
        local listener = Entities.FindByName(null, name+"_listener");
        local event_data = data;
        if (event_data == null && listener != null) {
            if (listener.ValidateScriptScope()) {
                event_data = listener.GetScriptScope().event_data;
            }
        }
        if (name in ::_eventsScope.listeners) {
            foreach (listener in ::_eventsScope.listeners[name]) {
                listener(event_data);
            }
        }
    }

    Log("[Events] Initialized");
}

// bind game_playerdie (see special case)
local ent = null;
while ((ent = Entities.FindByName(ent, "game_playerdie")) != null) {
    Log("[Events] Found game_playerdie "+ent+", binding");
    if (ent.ValidateScriptScope()) {
        local scope = ent.GetScriptScope();
        scope.OnPlayerDie <- function() {
            ::TriggerEvent("game_playerdie", activator);
        };
        ent.ConnectOutput("OnUse", "OnPlayerDie");
    }
}