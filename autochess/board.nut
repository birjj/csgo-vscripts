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
::BOARD_BENCH_OFFSET <- Vector(0, -128, 0);
::BOARD_SHOP_OFFSET <- Vector(0, -256, 0);

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
    lowerLeft = Vector(0, 0, 0);
    benchLowerLeft = Vector(0, 0, 0);
    shopLowerLeft = Vector(0, 0, 0);

    constructor(player, orig) {
        this.ePlayer = player;
        this.cursor = ::FindCursorOfPlayer(this.ePlayer);

        this.origin = orig;
        this.lowerLeft = this.origin - Vector(4 * BOARD_SQUARE_SIZE, 4 * BOARD_SQUARE_SIZE, 0);
        this.benchLowerLeft = this.lowerLeft + BOARD_BENCH_OFFSET;
        this.shopLowerLeft = this.lowerLeft + BOARD_SHOP_OFFSET;
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
            Log("[Board] Highlighting "+this.highlightedSquare);
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

    /** Returns the square that a particular position is on, if it is on the board */
    function GetBoardSquareOfPosition(position) {
        // board squares range from [0,8] in both x and y
        local dX = position.x - this.lowerLeft.x;
        local dY = position.y - this.lowerLeft.y;
        if (dX < 0 || dY < 0) { return null; }

        local x = (dX / BOARD_SQUARE_SIZE).tointeger();
        local y = (dY / BOARD_SQUARE_SIZE).tointeger();

        if (x >= 8 || y >= 8) { return null; }
        return Vector(x, y, 0);
    }

    /** Returns the square that a particular position is on, if it is on the bench */
    function GetBenchSquareOfPosition(position) {
        // bench squares range from [0,8] in x, but are -1 in y
        local dX = position.x - this.benchLowerLeft.x;
        local dY = position.y - this.benchLowerLeft.y;
        if (dX < 0 || dY < 0) { return null; }

        local x = (dX / BOARD_SQUARE_SIZE).tointeger();
        local y = (dY / BOARD_SQUARE_SIZE).tointeger();

        if (x >= 8 || y >= 1) { return null; }
        return Vector(x, y - 1, 0);
    }

    /** Returns the square that a particular position is on, if it is in the shop */
    function GetShopSquareOfPosition(position) {
        // shop squares range from [0,5] in x, but are -2 in y
        local dX = position.x - this.shopLowerLeft.x;
        local dY = position.y - this.shopLowerLeft.y;
        if (dX < 0 || dY < 0) { return null; }

        local x = (dX / BOARD_SQUARE_SIZE).tointeger();
        local y = (dY / BOARD_SQUARE_SIZE).tointeger();

        if (x >= 5 || y >= 1) { return null; }
        return Vector(x, y - 2, 0);
    }

    /**
     * Returns the square that a particular position resides in
     * Returned square is a vector, or null if outside of board
     */
    function GetSquareOfPosition(position) {
        local square = this.GetBoardSquareOfPosition(position);
        if (square != null) { return square; }
        square = this.GetBenchSquareOfPosition(position);
        if (square != null) { return square; }
        square = this.GetShopSquareOfPosition(position);
        return square;
    }

    /**
     * Returns the center of a square. Square is a vector
     */
    function GetPositionOfSquare(square) {
        local offset = Vector((square.x + 0.5) * BOARD_SQUARE_SIZE, (square.y + 0.5) * BOARD_SQUARE_SIZE, 0);
        // handle board squares
        if (square.y >= 0) { return this.lowerLeft + offset; }
        // handle bench squares
        if (square.y == -1) { return this.benchLowerLeft + Vector(0, BOARD_SQUARE_SIZE, 0) + offset; }
        // handle shop squares
        if (square.y == -2) { return this.shopLowerLeft + Vector(0, BOARD_SQUARE_SIZE * 2, 0) + offset; }

        Log("[Board] Attempted to get position of invalid square "+square);
        return null;
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