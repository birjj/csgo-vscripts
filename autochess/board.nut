/**
 * The actually underlying board representation
 * Deals with keeping track of units and delegating thinks to them
 */
DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/polyfills.nut", null);
DoIncludeScript("autochess/units/base.nut", null);

class Board {
    parentUI = null;

    isLive = false;
    startTime = null;
    clockTime = null;

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
            this.clockTime = null;
        }
        if (this.clockTime != null && Time() > this.clockTime) {
            // this.parentUI.ePlayer.EmitSound("AutoChess.Clock");
            this.clockTime = this.clockTime + 1;
        }

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
        this.bench[0].MoveToSquare(Vector(0, -1, 0), true);

        this.board[7][7] = BaseUnit(this, false);
        this.board[7][7].MoveToSquare(Vector(7, 7, 0), true);

        this.isLive = false;
        this.startTime = Time() + 10;
        this.clockTime = this.startTime - 5;
    }

    /** Finds the closest unit of the opposite alliance to a square */
    function FindEnemyClosestTo(square, friendly) {
        local lookingFor = !friendly;
        for (local dist = 1; dist <= 8; dist++) {
            local seenUnits = this.FindUnitsAtDistance(square, dist);
            local enemies = [];
            foreach (unit in seenUnits) {
                if (unit.friendly == lookingFor) { enemies.push(unit); }
            }
            if (enemies.len() > 0) {
                return enemies[RandomInt(0, enemies.len() - 1)];
            }
        }
    }

    /** Returns an array of all units that are a specific distance from a square */
    function FindUnitsAtDistance(startSquare, distance) {
        local output = [];
        local lowerLeft = startSquare - Vector(distance, distance, 0);
        local upperRight = startSquare + Vector(distance, distance, 0);
        // check horizontally
        for (local x = lowerLeft.x; x < upperRight.x; x++) {
            if (x < 0 || x >= 8) { continue; }
            local square = null;
            local unit = null;
            if (lowerLeft.y >= 0) {
                local square = Vector(x, lowerLeft.y, 0);
                local unit = this.GetUnitAtSquare(square);
                if (unit != null) { output.push(unit); }
            }
            if (upperRight.y < 8) {
                local square = Vector(x, upperRight.y, 0);
                local unit = this.GetUnitAtSquare(square);
                if (unit != null) { output.push(unit); }
            }
        }
        // check vertically
        for (local y = lowerLeft.y + 1; y < upperRight.y - 1; y++) {
            if (y < 0 || y >= 8) { continue; }
            local square = null;
            local unit = null;
            if (lowerLeft.x >= 0) {
                local square = Vector(lowerLeft.x, y, 0);
                local unit = this.GetUnitAtSquare(square);
                if (unit != null) { output.push(unit); }
            }
            if (upperRight.x < 8) {
                local square = Vector(upperRight.x, y, 0);
                local unit = this.GetUnitAtSquare(square);
                if (unit != null) { output.push(unit); }
            }
        }
        return output;
    }

    /** Gets the distance between two squares */
    function GetDistance(from, to) {
        local dX = abs(to.x - from.x);
        local dY = abs(to.y - from.y);
        if (dX < dY) { return dY; }
        return dX;
    }

    /** Get the unit that occupies a square, or null if none */
    function GetUnitAtSquare(square) {
        if (square.y == -2) { return this.shop[square.x]; }
        if (square.y == -1) { return this.bench[square.x]; }
        return this.board[square.x][square.y];
    }

    /** Sets the unit that is at a square - be careful, overwrites whatever is there already */
    function SetUnitAtSquare(square, unit) {
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
    function MoveUnitToSquare(unit, square, noAnim=false) {
        if (unit == null) {
            Log("[BoardUI] -- Attempted to move null piece!");
            return;
        }
        local fromSquare = unit.position;
        local unitAtTarget = this.GetUnitAtSquare(square);
        this.SetUnitAtSquare(fromSquare, unitAtTarget);
        this.SetUnitAtSquare(square, unit);
        unit.MoveToSquare(square, noAnim);
        if (unitAtTarget != null) {
            unitAtTarget.MoveToSquare(fromSquare, noAnim);
        }
    }
}