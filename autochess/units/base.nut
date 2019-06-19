DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/timers.nut", null);
DoIncludeScript("lib/math.nut", null);
DoIncludeScript("autochess/a-star.nut", null);

class BaseUnit {
    eModel = null;
    position = Vector(0, 0, 0);
    board = null;

    moveTime = null; // time at which we should move again
    moveFrom = null; // Vector we are moving from
    moveTo = null; // Vector we are moving to
    moveStart = null; // time at which we started moving
    moveTimer = null; // TimerHandler we use for animating the move

    attackTime = null;
    
    friendly = false;
    target = null;
    hp = 0;

    MODEL_NAME = "models/player/ctm_fbi.mdl";
    MOVE_DURATION = 1; // time it takes to move from one space to another
    MAX_HP = 100;
    ATTACK_RANGE = 1; // distance at which we can attack
    ATTACK_DELAY = 0.5; // seconds between each attack
    ATTACK_DMG = 1; // amount of damage we deal to the enemy

    constructor(brd, isFriend) {
        this.board = brd;
        this.friendly = isFriend;
        this.hp = MAX_HP;

        this.eModel = CreateProp("prop_dynamic", Vector(0, 0, 0), this.MODEL_NAME, 0);
        if (this.friendly) {
            this.eModel.SetAngles(0, 90, 0);
        } else {
            this.eModel.SetAngles(0, -90, 0);
        }
    }

    /** Called when we are live and should do something - gets targets, attacks and moves */
    function Think() {
        if (this.target == null) {
            this.AcquireTarget();
        }

        if (this.target) {
            local distance = this.board.GetDistance(this.position, this.target.position);
            if (distance <= this.ATTACK_RANGE) {
                if (this.moveStart == null) {
                    if (this.attackTime == null) { this.attackTime = Time(); }
                    if (this.attackTime < Time()) {
                        this.attackTime = Time() + this.ATTACK_DELAY;
                        this.PerformAttack();
                    }
                }
            } else {
                if (this.moveTime == null) { this.moveTime = Time(); }
                if (this.moveTime < Time()) {
                    this.moveTime = Time() + this.MOVE_DURATION;
                    this.PerformMove();
                }
            }
        }
    }

    /** Calculates which move we want to do and executes it */
    function PerformMove() {
        local targetSquare = this.GetMove();
        if (targetSquare == null) { return; }
        local ourPos = this.board.parentUI.GetPositionOfSquare(this.position);
        local theirPos = this.board.parentUI.GetPositionOfSquare(this.target.position);
        /*::DrawLine(
            ourPos + Vector(0, 0, 12),
            theirPos + Vector(0, 0, 12),
            Vector(255, 0, 0),
            1
        );*/
        local angles = AngleBetweenPoints(ourPos, theirPos);
        this.eModel.SetAngles(angles.x, angles.y + 8, angles.z);
        EntFireByHandle(this.eModel, "SetAnimation", "testWalkN", 0.0, null, null);
        this.board.MoveUnitToSquare(this, targetSquare);
    }

    /** Performs an attack towards our target */
    function PerformAttack() {
        Log("[BaseUnit] Dealing "+this.ATTACK_DMG+" to target");
        this.target.SetHealth(this.target.hp - this.ATTACK_DMG);
        local ourPos = this.board.parentUI.GetPositionOfSquare(this.position);
        local theirPos = this.board.parentUI.GetPositionOfSquare(this.target.position);
        local angles = AngleBetweenPoints(ourPos, theirPos);
        this.eModel.SetAngles(angles.x, angles.y + 90, angles.z);
        EntFireByHandle(this.eModel, "SetAnimation", "Run_Shoot_KNIFE_LIGHT_L_BS", 0.0, null, null);
    }

    /** Performs the animation and logic for dying */
    function PerformDeath() {
        Log("[BaseUnit] Died :(");
    }

    function AnimThink() {
        if (this.moveStart != null) {
            local progress = (Time() - this.moveStart) / this.MOVE_DURATION;
            local pos = null;
            if (progress >= 1) {
                this.moveStart = null;
                this.moveTimer.Destroy();
                this.moveTimer = null;
                EntFireByHandle(this.eModel, "SetAnimation", "testIdle", 0.0, null, null);
                pos = this.moveTo;
            } else {
                local delta = (this.moveFrom - this.moveTo) * (1 - progress);
                pos = this.moveTo + delta;
                pos = this.moveFrom;
            }
            this.eModel.SetOrigin(pos);
        }
    }

    /** Get the square we want to move to */
    function GetMove() {
        if (this.target == null) { return null; }

        // get path to enemy
        local path = ::GeneratePath(this.board.board, this.position, this.target.position);
        /*for (local i = 0; i < path.len() - 1; i++) {
            ::DrawLine(
                this.board.parentUI.GetPositionOfSquare(path[i]) + Vector(0, 0, 8),
                this.board.parentUI.GetPositionOfSquare(path[i+1]) + Vector(0, 0, 8),
                Vector(255,180,200),
                1
            );
        }*/

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
        /*::DrawLine(
            this.board.parentUI.GetPositionOfSquare(this.position) + Vector(0, 0, 8),
            this.board.parentUI.GetPositionOfSquare(this.target.position) + Vector(0, 0, 8),
            Vector(0,0,255),
            10
        );*/
    }

    function MoveToSquare(square, noAnim=false) {
        if (this.moveTimer != null) {
            this.moveTimer.Destroy();
            this.moveTimer = null;
        }
        if (!noAnim) {
            this.moveFrom = this.board.parentUI.GetPositionOfSquare(this.position);
            this.moveTo = this.board.parentUI.GetPositionOfSquare(square);
            this.moveStart = Time();
            this.moveTimer = TimerHandler(0.01, this.AnimThink.bindenv(this));
        } else {
            this.eModel.SetOrigin(this.board.parentUI.GetPositionOfSquare(square));
        }
        this.position = square;
    }

    function SetHealth(health) {
        local color = (health / this.MAX_HP) * 255;
        local colStr = color + " 0";
        if (this.friendly) {
            colStr = "0 "+colStr;
        } else {
            colStr = colStr+" 0";
        }
        this.hp = health;
        // EntFireByHandle(this.eModel, "Color", colStr, 0.0, null, null);

        if (this.hp <= 0) {
            this.PerformDeath();
        }
    }

    function Destroy() {
        if (this.eModel != null && this.eModel.IsValid()) {
            this.eModel.Destroy();
        }
    }
}