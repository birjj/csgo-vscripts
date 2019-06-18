/**
 * The actually underlying board representation
 * Deals with keeping track of units and delegating thinks to them
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("autochess/units/base.nut", null);

class Board {
    parentUI = null;
    isLive = false;

    startTime = null;

    board = null;
    bench = null;
    shop = null;

    constructor(ui) {
        this.parentUI = ui;
    }

    function Think() {
        if (this.startTime != null && Time() > this.startTime) {
            this.isLive = true;
            this.startTime = null;
        }

        // don't do any other logic if we aren't live
        if (!this.isLive) { return; }

        foreach (col in this.board) {
            foreach (unit in col) {
                if (unit != null) {
                    unit.Think();
                }
            }
        }
    }

    function OnRoundStart() {
        this.board = [ // x,y
            array(8, null),
            array(8, null),
            array(8, null),
            array(8, null),
            array(8, null),
            array(8, null),
            array(8, null),
            array(8, null)
        ];
        this.bench = array(8, null);
        this.shop = array(5, null);

        // TODO: don't generate fake units
        this.bench[0] = BaseUnit(this, true);
        this.bench[0].MoveToSquare(Vector(0, -1, 0));

        this.startTime = Time() + 10;
    }

    /** Get the unit that occupies a square, or null if none */
    function GetUnitAtSquare(square) {
        if (square.y == -2) { return this.shop[square.x]; }
        if (square.y == -1) { return this.bench[square.x]; }
        return this.board[square.x][square.y];
    }

    /** Sets the unit that is at a square - be careful, overwrites whatever is there already */
    function SetUnitAtSquare(square, unit) {
        Log("[Board] Setting unit at "+square+" to "+unit);
        if (square.y == -2) {
            this.shop[square.x] = unit;
            return;
        }
        if (square.y == -1) {
            this.bench[square.x] = unit;
            return;
        }
        this.board[square.x][square.y] = unit;
    }

    /** Moves a unit to a square, swapping with whatever is on there */
    function MoveUnitToSquare(unit, square) {
        if (unit == null) {
            Log("[BoardUI] -- Attempted to move null piece!");
            return;
        }
        local fromSquare = unit.position;
        local unitAtTarget = this.GetUnitAtSquare(square);
        this.SetUnitAtSquare(fromSquare, unitAtTarget);
        this.SetUnitAtSquare(square, unit);
        unit.MoveToSquare(square);
        if (unitAtTarget != null) {
            unitAtTarget.MoveToSquare(fromSquare);
        }
    }
}