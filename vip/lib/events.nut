// https://github.com/birjolaxew/csgo-vscripts
// == Event listener
// Listen for in-game events
// The callback functions are called directly with the event data
// In order for this to work, you must manually add logic_eventlistener to your world
// This logic_eventlistener should have the following keyvalues:
//   - targetname the_event_you_want_to_listen_to_listener
//   - EventName the_event_you_want_to_listen_to
//   - FetchEventData 1
// It should also have the following output:
//   - OnEventFired name_of_your_logic_script RunScriptCode ::TriggerEvent(THE_EVENT_YOU_WANT_TO_LISTEN_TO)
//
// Exposes:
//   ::AddEventListener("event-name", function(){})
//   ::RemoveEventListener("event-name", function(){})
//   ::TriggerEvent("event-name")
// ==

::ITEM_EQUIP <- "item_equip";
::PLAYER_USE <- "player_use";
::PLAYER_DEATH <- "player_death";
::PLAYER_DISCONNECT <- "player_disconnect";
::ROUND_START <- "round_start";
::ROUND_FREEZE_END <- "round_freeze_end";
::PLAYER_SPAWN <- "player_spawn";
::PLAYER_HURT <- "player_hurt";
::BOT_TAKEOVER <- "bot_takeover";
::INSPECT_WEAPON <- "inspect_weapon";

DoIncludeScript("vip/lib/debug.nut",null);

if (!("_eventsScope" in getroottable())) {
    // each event is an array of listeners
    ::_eventsScope <- {};
    ::_eventsScope.listeners <- {};

    ::AddEventListener <- function(name, cb) {
        printl("[Events] Adding event listener for " + name);
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
        // printl("[Events] Triggering event for " + name);
        local listener = Entities.FindByName(null, name+"_listener");
        local event_data = data;
        if (event_data == null && listener != null) {
            if (listener.ValidateScriptScope()) {
                event_data = listener.GetScriptScope().event_data;
            }
        }
        // ::printtable(event_data);
        if (name in ::_eventsScope.listeners) {
            foreach (listener in ::_eventsScope.listeners[name]) {
                listener(event_data);
            }
        }
    }


    printl("[Events] Initialized");
}