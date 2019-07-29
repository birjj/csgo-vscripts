/**
 * https://github.com/birjolaxew/csgo-vscripts
 * Entrypoint for the Portal gamemode
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/events.nut", null);
DoIncludeScript("lib/precache.nut", null);
DoIncludeScript("portal/gamemode.nut", null);

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
    if ("gamemode_portal" in root) {
        ::gamemode_portal.Think();
    }

    local ent = null;
    while (ent = Entities.FindByClassname(ent, "hegrenade_projectile")) {
        Log("  "+ent+" | "+ent.GetName());
    }
}

if (!("_LOADED_GAMEMODE_PORTAL" in getroottable())) {
    ::_LOADED_GAMEMODE_PORTAL <- true;
    ::gamemode_portal <- GamemodePortal();
} else {
    ::gamemode_portal.OnRoundStart();
}