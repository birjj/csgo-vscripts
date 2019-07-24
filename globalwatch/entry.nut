/**
 * https://github.com/birjolaxew/csgo-vscripts
 * Entrypoint for the Globalwatch gamemode
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/precache.nut", null);
DoIncludeScript("globalwatch/gamemode.nut", null);

function Precache() {
    PerformPrecache(self);
}

function Think() {
    local root = getroottable();
    if ("Players" in root) {
        ::Players.Think();
    }
    if ("_LOADED_MODULE_TIMER" in root) {
        ::_timer_Think();
    }
    if ("_LOADED_MODULE_CURSORS" in root) {
        ::_cursors_Think();
    }
    if ("_LOADED_GAMEMODE_GLOBALWATCH" in root) {
        ::gamemode_globalwatch.Think();
    }
}

if (!("_LOADED_GAMEMODE_GLOBALWATCH" in getroottable())) {
    ::_LOADED_GAMEMODE_GLOBALWATCH <- true;
    ::gamemode_globalwatch <- GamemodeGlobalwatch();
} else {
    ::gamemode_globalwatch.OnRoundStart();
}