/**
 * Entrypoint for the Auto Chess gamemode
 * Handles assigning boards to users, handling inputs and precaching/delegating think functions
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("autochess/cursors.nut", null);
DoIncludeScript("autochess/board-ui.nut", null);

::BOARD_POSITIONS <- [ // update this to match the position of the boards in your map
    Vector(0, 0, 0)
];

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
    if ("_board_Think" in root) {
        ::_board_Think();
    }
}

/**
 * Gets the board that is bound to a particular player entity
 * If no board is bound, returns null
 */
::FindBoardOfPlayer <- function(player) {
    if (player == null) { return null; }
    if (!player.ValidateScriptScope()) { return null; }
    local scope = player.GetScriptScope();
    if (!("userid" in scope)) {
        Log("[AutoChess] Tried to find board of player "+player+" that has no userid");
        return null;
    }
    local userid = scope.userid;
    if (!(userid in ::ASSIGNED_BOARDS)) {
        Log("[AutoChess] Tried to find board of player "+player+" that has no board");
        return null;
    }
    return ::ASSIGNED_BOARDS[userid];
};

/**
 * Assigns a free board to a player and returns it
 * If no free board is available, returns null
 * If player already has a board, it is returned without assigning a new one
 */
::AssignBoardToUserid <- function(userid) {
    if (::FREE_BOARD_POSITIONS.len() == 0) { return null; }
    Log("[AutoChess] Assigning board to "+userid);
    if (userid in ::ASSIGNED_BOARDS) {
        Log("[AutoChess] Player already has a board");
        return ::ASSIGNED_BOARDS[userid];
    }

    local boardPosition = ::FREE_BOARD_POSITIONS.pop();
    ::ASSIGNED_BOARDS[userid] <- BoardUI(userid, boardPosition);
    return ::ASSIGNED_BOARDS[userid];
}

/**
 * Removes a board from a player, returning it to the pool of free boards
 * If player doesn't have a board, nothing is done
 */
::RemoveBoardFromUserid <- function(userid) {
    Log("[AutoChess] Removing board from "+userid);
    if (!(userid in ::ASSIGNED_BOARDS)) {
        Log("[AutoChess] Player "+userid+" has no board");
        return;
    }
    local board = ::ASSIGNED_BOARDS[userid];
    ::FREE_BOARD_POSITIONS.push(board.origin);
    delete ::ASSIGNED_BOARDS[userid];
}

function OnAttack1() {
    local cursor = ::FindCursorOfPlayer(activator);
    if (cursor == null) { return; }
    local board = ::FindBoardOfPlayer(activator);
    if (board == null) { return; }

    board.OnClicked(cursor.GetLookingAt());
}

if (!("_LOADED_GAMEMODE_AUTOCHESS" in getroottable())) {
    ::_LOADED_GAMEMODE_AUTOCHESS <- true;

    ::AddEventListener("player_spawn", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player == null) { return; }
        local board = ::AssignBoardToUserid(data.userid);
        Log("[AutoChess] Assigned board "+board+" to "+player+" ("+data.userid+")");
    });

    ::ASSIGNED_BOARDS <- {};
    ::FREE_BOARD_POSITIONS <- [];
    foreach (position in ::BOARD_POSITIONS) {
        ::FREE_BOARD_POSITIONS.push(position);
    }

    ::_board_Think <- function() {
        foreach (board in ::ASSIGNED_BOARDS) {
            board.Think();
        }
    }
} else {
    foreach (board in ::ASSIGNED_BOARDS) {
        board.OnRoundStart();
    }
}