DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/timers.nut", null);
DoIncludeScript("autochess/a-star.nut", null);

class BaseUnit {
    eModel = null;
    position = Vector(0, 0, 0);
    board = null;

    moveTime = null;
    moveFrom = null;
    moveTo = null;
    moveStart = null;
    moveTimer = null;
    
    friendly = false;
    target = null;

    MODEL_NAME = "models/player/ctm_fbi.mdl";
    ATTACK_RANGE = 1;

    constructor(brd, isFriend) {
        this.board = brd;
        this.friendly = isFriend;

        this.eModel = CreateProp("prop_dynamic", Vector(0, 0, 0), this.MODEL_NAME, 0);
        if (this.friendly) {
            this.eModel.SetAngles(0, 90, 0);
        } else {
            this.eModel.SetAngles(0, -90, 0);
        }
    }

    function Think() {
        if (this.target == null) {
            this.AcquireTarget();
        }

        if (this.target) {
            if (this.moveTime == null) { this.moveTime = Time() + 1; }
            if (this.moveTime < Time()) {
                this.moveTime = Time() + 1;
                local targetSquare = this.GetMove();
                if (targetSquare == null) { return; }
                ::DrawLine(
                    this.board.parentUI.GetPositionOfSquare(this.position) + Vector(0, 0, 12),
                    this.board.parentUI.GetPositionOfSquare(this.target.position) + Vector(0, 0, 12),
                    Vector(255, 0, 0),
                    1
                );
                this.board.MoveUnitToSquare(this, targetSquare);
            }
        }
    }

    function AnimThink() {
        if (this.moveStart != null) {
            local progress = (Time() - this.moveStart) / 0.5;
            local pos = null;
            if (progress >= 1) {
                this.moveStart = null;
                this.moveTimer.Destroy();
                this.moveTimer = null;
                pos = this.moveTo;
            } else {
                local delta = (this.moveFrom - this.moveTo) * (1 - progress);
                Log("[BaseUnit] Progress "+progress+". Moving "+this.moveFrom+"->"+this.moveTo+" ("+delta+")");
                pos = this.moveTo + delta;
            }
            this.eModel.SetOrigin(pos + Vector(0, 0, 32));
        }
    }

    /** Get the square we want to move to */
    function GetMove() {
        if (this.target == null) { return null; }

        // get path to enemy
        local path = ::GeneratePath(this.board.board, this.position, this.target.position);
        for (local i = 0; i < path.len() - 1; i++) {
            ::DrawLine(
                this.board.parentUI.GetPositionOfSquare(path[i]) + Vector(0, 0, 8),
                this.board.parentUI.GetPositionOfSquare(path[i+1]) + Vector(0, 0, 8),
                Vector(255,180,200),
                1
            );
        }

        // if we have only one move, that would put us on top of the enemy - in those cases don't move
        if (path.len() < 3) {
            return null;
        }

        // return the next step
        return path[path.len() - 2];
    }

    function AcquireTarget() {
        // Log("[BaseUnit] Finding target for "+this);
        this.target = this.board.FindEnemyClosestTo(this.position, this.friendly);
        if (this.target == null) { return; }
        ::DrawLine(
            this.board.parentUI.GetPositionOfSquare(this.position) + Vector(0, 0, 8),
            this.board.parentUI.GetPositionOfSquare(this.target.position) + Vector(0, 0, 8),
            Vector(0,0,255),
            10
        );
    }

    function MoveToSquare(square, noAnim=false) {
        if (!noAnim) {
            this.moveFrom = this.board.parentUI.GetPositionOfSquare(this.position);
            this.moveTo = this.board.parentUI.GetPositionOfSquare(square);
            this.moveStart = Time();
            this.moveTimer = TimerHandler(0.01, this.AnimThink.bindenv(this));
        } else {
            this.eModel.SetOrigin(this.board.parentUI.GetPositionOfSquare(square) + Vector(0, 0, 32));
        }
        this.position = square;
    }

    function Destroy() {
        if (this.eModel != null && this.eModel.IsValid()) {
            this.eModel.Destroy();
        }
    }
}