DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("autochess/cursors.nut", null);
DoIncludeScript("autochess/board.nut", null);

function Precache() {
    self.PrecacheModel("models/player/ctm_fbi.mdl");
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
    if ("_LOADED_MODULE_BOARD" in root) {
        ::_board_Think();
    }
    if ("gamemode_autochess" in root) {
        ::gamemode_autochess.Think();
    }	
}

function OnAttack1() {
    local cursor = ::FindCursorOfPlayer(activator);
    if (cursor == null) { return; }
    local board = ::FindBoardOfPlayer(activator);
    if (board == null) { return; }

    board.OnClicked(cursor.GetLookingAt());
}

class GameModeAutoChess {
    function Think() {

    }
}

if (!("gamemode_vip" in getroottable())) {
    ::gamemode_vip <- GameModeAutoChess();

    ::AddEventListener("player_spawn", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player == null) { return; }
        local board = ::AssignBoardToPlayer(player);
        Log("[AutoChess] Assigned board "+board+" to "+player);
    });
}