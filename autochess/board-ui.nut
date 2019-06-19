/**
 * Handles the UI and binding user actions to changes on the underlying board structure
 * Exposes:
 *   - FindBoardOfPlayer(player)
 *   - AssignBoardToPlayer(player)
 *   - RemoveBoardFromPlayer(player)
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/polyfills.nut", null);
DoIncludeScript("autochess/cursors.nut", null);
DoIncludeScript("autochess/board.nut", null);

::BOARD_SQUARE_SIZE <- 64;
::BOARD_BENCH_OFFSET <- Vector(0, -128, -12);
::BOARD_SHOP_OFFSET <- Vector(0, -256, 0);
::BOARD_PLAYER_OFFSET <- Vector(0, -448, 368);

class BoardUI {
    board = null;
    userid = null;
    ePlayer = null;
    cursor = null;

    origin = Vector(0, 0, 0);
    lowerLeft = Vector(0, 0, 0);
    benchLowerLeft = Vector(0, 0, 0);
    shopLowerLeft = Vector(0, 0, 0);

    highlightedSquare = null;
    selectedSquare = null;

    constructor(usrid, orig) {
        Log("[BoardUI] My origin is "+orig);
        this.board = Board(this);
        this.userid = usrid;
        this.origin = orig;
        this.lowerLeft = this.origin - Vector(4 * BOARD_SQUARE_SIZE, 4 * BOARD_SQUARE_SIZE, 0);
        this.benchLowerLeft = this.lowerLeft + BOARD_BENCH_OFFSET;
        this.shopLowerLeft = this.lowerLeft + BOARD_SHOP_OFFSET;

        this.OnRoundStart();
    }

    /** Called when the round starts, and we need to do stuff again (e.g. place the user) */
    function OnRoundStart() {
        this.ePlayer = ::Players.FindByUserid(this.userid);
        Log("[BoardUI] Finding player for our userid "+this.userid+", got "+this.ePlayer);
        if (this.ePlayer == null) { return; } // we'll be called again in a bit by our Think
        this.board.OnRoundStart();
        this.cursor = ::FindCursorOfPlayer(this.ePlayer);
        this.PlacePlayer();
    }

    function Think() {
        // after a round restart, we might need to wait a bit before we can grab our user
        if (this.ePlayer == null) {
            this.OnRoundStart();
            return;
        }

        this.board.Think();
        if (this.board.isLive) { return; } // user shouldn't be able to interact while we're fighting

        // update our reading of what the player is aiming at
        if (this.cursor == null) { this.cursor = ::FindCursorOfPlayer(this.ePlayer); }
        if (this.cursor != null) {
            local lookingAt = this.cursor.GetLookingAt();
            local lookingAtSquare = this.GetSquareOfPosition(lookingAt);
            if (lookingAtSquare != null && lookingAtSquare.y < 4) {
                this.HighlightSquare(lookingAtSquare);
            } else {
                this.HighlightSquare(null);
            }
        } else {
            Log("[BoardUI] Couldn't find cursor of player "+player);
        }

        // higlight the square the user is aiming at, or has selected
        // TODO: replace with model-based highlighting
        if (this.selectedSquare != null) {
            local position = this.GetPositionOfSquare(this.selectedSquare);
            local size = Vector(BOARD_SQUARE_SIZE, BOARD_SQUARE_SIZE, 16);
            DebugDrawBox(
                position + Vector(0, 0, 9),
                size * -0.5,
                size * 0.5,
                0,
                0,
                255,
                0,
                0.15
            );
        }
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
                0,
                0.15
            );
        }
    }

    /** Sets the square that we are highlighting */
    function HighlightSquare(square) {
        this.highlightedSquare = square;
    }

    /** Sets the square that we have selected */
    function SelectSquare(square) {
        Log("[BoardUI] "+this.ePlayer+" selected "+square);
        this.selectedSquare = square;
    }

    /** Deselects the currently active square */
    function DeselectSquare() {
        this.selectedSquare = null;
    }

    /** Handles the player clicking. Decides if we should select a square, move a unit, etc. */
    function OnClicked(position) {
        if (this.board.isLive) { return; }
        local clickedSquare = GetSquareOfPosition(position);
        // if we clicked outside of the board, deselect the current selection
        if (clickedSquare == null) {
            if (this.selectedSquare != null) {
                Log("[BoardUI] " + this.ePlayer + " deselected by clicking outside of board");
                this.DeselectSquare();
            }
            return;
        }

        // == if we clicked on a square, we have to make a decision

        // if we don't have a selected square, we make the clicked square the selected on
        if (this.selectedSquare == null) {
            // we don't want to select empty squares (because they don't do anything)
            if (this.board.GetUnitAtSquare(clickedSquare) != null) {
                this.SelectSquare(clickedSquare);
            }
            return;
        }

        // if we clicked the selected square, we want to deselect it
        if (clickedSquare.x == this.selectedSquare.x && clickedSquare.y == this.selectedSquare.y) {
            Log("[BoardUI] "+this.ePlayer+" deselected by clicking same square ("+clickedSquare+","+this.selectedSquare+")");
            this.DeselectSquare();
            return;
        }

        // otherwise we clicked a square while having a square selected - do something
        // we can't move to top half of board, or to shop
        if (clickedSquare.y >= 4 || clickedSquare.y == -2) { return; }
        local unit = this.board.GetUnitAtSquare(this.selectedSquare);
        this.board.MoveUnitToSquare(unit, clickedSquare, true);
        this.DeselectSquare();
    }

    /** Sets our player to the position we want him to start in */
    function PlacePlayer() {
        Log("[BoardUI] Moving "+this.ePlayer+" to board");
        this.ePlayer.SetOrigin(this.origin + BOARD_PLAYER_OFFSET);
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

        Log("[BoardUI] Attempted to get position of invalid square "+square);
        return null;
    }
}