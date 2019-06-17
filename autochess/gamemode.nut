DoIncludeScript("autochess/cursors.nut", null);

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
    if ("gamemode_autochess" in root) {
        ::gamemode_autochess.Think();
    }	
}

class GameModeAutoChess {
    function Think() {

    }
}

if (!("gamemode_vip" in getroottable())) {
    ::gamemode_vip <- GameModeAutoChess();
}