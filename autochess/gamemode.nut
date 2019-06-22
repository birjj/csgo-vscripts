/**
 * Entrypoint for the Auto Chess gamemode
 * Handles assigning boards to users, handling inputs and precaching/delegating think functions
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("autochess/cursors.nut", null);
DoIncludeScript("autochess/board-ui.nut", null);

::BOARD_POSITIONS <- [ // update this to match the position of the boards in your map
    Vector(0, 0, 16)
];

function Precache() {
    self.PrecacheModel("models/player/ctm_fbi.mdl");
    self.PrecacheModel("models/weapons/w_knife.mdl");
    self.PrecacheModel("models/weapons/w_snip_awp.mdl");
    self.PrecacheSoundScript("weapons/awp/awp_01.wav");
    self.PrecacheSoundScript("AutoChess.Clock");
    self.PrecacheSoundScript("AutoChess.SelectUnit");
    self.PrecacheSoundScript("AutoChess.SwapUnits");
    self.PrecacheSoundScript("AutoChess.Knife");
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
    if ("gamemode_autochess" in root) {
        ::gamemode_autochess.Think();
    }
}

function OnAttack1() {
    local cursor = ::FindCursorOfPlayer(activator);
    if (cursor == null) { return; }
    local board = ::gamemode_autochess.FindBoardOfPlayer(activator);
    if (board == null) { return; }

    board.OnClicked(cursor.GetLookingAt());
}

class GamemodeAutoChess {
    assigned_boards = null;
    free_board_positions = null;

    startTime = null;
    roundTime = null;
    isLive = false;

    constructor() {
        this.assigned_boards = {};
        this.free_board_positions = [];
        foreach (position in ::BOARD_POSITIONS) {
            this.free_board_positions.push(position);
        }

        this.OnRoundStart();
    }

    /** Get the time of the current round, negative if in preparation and positive if is live */
    function GetRoundTime() {
        return Time() - this.roundTime;
    }

    function OnRoundStart() {
        this.startTime = Time();
        this.roundTime = this.startTime + 10;
        this.isLive = false;

        foreach (board in this.assigned_boards) {
            board.OnRoundStart();
        }
    }

    function Think() {
        if (!this.isLive && this.GetRoundTime() >= 0) {
            this.isLive = true;
        }

        foreach (board in this.assigned_boards) {
            board.Think();
        }
    }

    /**
     * Gets the board that is bound to a particular player entity
     * If no board is bound, returns null
     */
    function FindBoardOfPlayer(player) {
        if (player == null) { return null; }
        if (!player.ValidateScriptScope()) { return null; }
        local scope = player.GetScriptScope();
        if (!("userid" in scope)) {
            Log("[AutoChess] Tried to find board of player "+player+" that has no userid");
            return null;
        }
        local userid = scope.userid;
        if (!(userid in this.assigned_boards)) {
            Log("[AutoChess] Tried to find board of player "+player+" that has no board");
            return null;
        }
        return this.assigned_boards[userid];
    };

    /**
     * Assigns a free board to a player and returns it
     * If no free board is available, returns null
     * If player already has a board, it is returned without assigning a new one
     */
    function AssignBoardToUserid(userid) {
        if (this.free_board_positions.len() == 0) { return null; }
        Log("[AutoChess] Assigning board to "+userid);
        if (userid in this.assigned_boards) {
            Log("[AutoChess] Player already has a board");
            return this.assigned_boards[userid];
        }

        local boardPosition = this.free_board_positions.pop();
        this.assigned_boards[userid] <- BoardUI(userid, boardPosition);
        return this.assigned_boards[userid];
    }

    /**
     * Removes a board from a player, returning it to the pool of free boards
     * If player doesn't have a board, nothing is done
     */
    function RemoveBoardFromUserid(userid) {
        Log("[AutoChess] Removing board from "+userid);
        if (!(userid in this.assigned_boards)) {
            Log("[AutoChess] Player "+userid+" has no board");
            return;
        }
        local board = this.assigned_boards[userid];
        this.free_board_positions.push(board.origin);
        delete this.assigned_boards[userid];
    }
}

if (!("_LOADED_GAMEMODE_AUTOCHESS" in getroottable())) {
    ::_LOADED_GAMEMODE_AUTOCHESS <- true;
    ::gamemode_autochess <- GamemodeAutoChess();

    ::AddEventListener("player_spawn", function(data) {
        local player = ::Players.FindByUserid(data.userid);
        if (player == null) { return; }
        local board = ::gamemode_autochess.AssignBoardToUserid(data.userid);
        Log("[AutoChess] Assigned board "+board+" to "+player+" ("+data.userid+")");
    });
} else {
    ::gamemode_autochess.OnRoundStart();
}