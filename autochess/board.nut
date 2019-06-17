/**
 * Handles all board-related stuff. This includes allocating boards as they are needed.
 * Exposes:
 *   - FindBoardOfPlayer(player)
 *   - AssignBoardToPlayer(player)
 *   - RemoveBoardFromPlayer(player)
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/polyfills.nut", null);
DoIncludeScript("autochess/cursors.nut", null);

::BOARD_POSITIONS <- [ // update this to match the position of the boards in your map
    Vector(0, 0, 0)
];
::BOARD_SQUARE_SIZE <- 64;

/**
 * Gets the board that is bound to a particular player entity
 * If no board is bound, returns null
 */
::FindBoardOfPlayer <- function(player) {
    if (player == null) { return null; }
    if (!player.ValidateScriptScope()) { return null; }
    local scope = player.GetScriptScope();
    if ("board" in scope) {
        return scope.board;
    }
    return null;
};

/**
 * Assigns a free board to a player and returns it
 * If no free board is available, returns null
 * If player already has a board, it is returned without assigning a new one
 */
::AssignBoardToPlayer <- function(player) {
    if (::FREE_BOARD_POSITIONS.len() == 0) { return null; }
    if (player == null) { return null; }
    if (!player.ValidateScriptScope()) { return null; }
    Log("[Board] Assigning board to "+player);
    local scope = player.GetScriptScope();
    if ("board" in scope) {
        Log("[Board] Player already has a board");
        return scope.board;
    }

    local boardPosition = ::FREE_BOARD_POSITIONS.pop();
    scope.board <- Board(player, boardPosition);
    ::ASSIGNED_BOARDS.push(scope.board);
    return scope.board;
}

/**
 * Removes a board from a player, returning it to the pool of free boards
 * If player doesn't have a board, nothing is done
 */
::RemoveBoardFromPlayer <- function(player) {
    Log("[Board] Removing board from "+player);
    local board = ::FindBoardOfPlayer(player);
    if (board == null) { return; }
    local scope = player.GetScriptScope();
    remove_elm_from_array(::ASSIGNED_BOARDS, board);
    ::FREE_BOARD_POSITIONS.push(board.origin);
    delete scope.board;
}

class Board {
    ePlayer = null;
    cursor = null;

    highlightedSquare = null;
    origin = Vector(0, 0, 0);

    constructor(player, orig) {
        this.ePlayer = player;
        this.origin = orig;
        this.cursor = ::FindCursorOfPlayer(this.ePlayer);
    }

    function Think() {
        // update our reading of what the player is aiming at
        if (this.cursor == null) { this.cursor = ::FindCursorOfPlayer(this.ePlayer); }
        if (this.cursor != null) {
            local lookingAt = this.cursor.GetLookingAt();
            this.highlightedSquare = this.GetSquareOfPosition(lookingAt);
        } else {
            Log("[Board] Couldn't find cursor of player "+player);
        }

        // higlight the square the user is aiming at
        if (this.highlightedSquare != null) {
            local position = this.GetPositionOfSquare(this.highlightedSquare);
            local size = Vector(BOARD_SQUARE_SIZE, BOARD_SQUARE_SIZE, 16);
            DebugDrawBox(
                position + Vector(0, 0, 8),
                size * -0.5,
                size * 0.5,
                0,
                255,
                0,
                255,
                0.15
            );
        }
    }

    /**
     * Returns the square that a particular position resides in
     * Returned square is an [x,y] array, or null if outside of board
     */
    function GetSquareOfPosition(position) {
        local mouseX = position.x - (origin.x - 4 * BOARD_SQUARE_SIZE);
        local mouseY = position.y - (origin.y - 4 * BOARD_SQUARE_SIZE);

        if (mouseX < 0 || mouseY < 0) { return null; }

        local x = (mouseX / BOARD_SQUARE_SIZE).tointeger();
        local y = (mouseY / BOARD_SQUARE_SIZE).tointeger();

        if (x >= 8 || y >= 8) { return null; }
        return [x, y];
    }

    /**
     * Returns the center of a square. Square is an [x,y] array
     */
    function GetPositionOfSquare(square) {
        local x = (origin.x - 4 * BOARD_SQUARE_SIZE) + (square[0] + 0.5) * BOARD_SQUARE_SIZE;
        local y = (origin.y - 4 * BOARD_SQUARE_SIZE) + (square[1] + 0.5) * BOARD_SQUARE_SIZE;

        return Vector(x, y, this.origin.z);
    }
}

if (!("_LOADED_MODULE_BOARD" in getroottable())) {
    ::_LOADED_MODULE_BOARD <- true;

    ::ASSIGNED_BOARDS <- [];
    ::FREE_BOARD_POSITIONS <- [];
    foreach (position in ::BOARD_POSITIONS) {
        ::FREE_BOARD_POSITIONS.push(position);
    }

    ::_board_Think <- function() {
        foreach(board in ::ASSIGNED_BOARDS) {
            board.Think();
        }
    }
}