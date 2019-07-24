DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/polyfills.nut", null);
DoIncludeScript("lib/cursors.nut", null);
DoIncludeScript("lib/weapons.nut", null);
DoIncludeScript("lib/math.nut", null);

enum WidowmakerState {
    IDLE,
    HOOKING,
    DESTROYED
}

class HeroWidowmaker {
    ePlayer = null;
    playerScope = null;
    cursor = null;

    cbAttack1 = null;
    cbAttack2 = null;

    state = WidowmakerState.IDLE;

    hookTarget = null;
    hookStartTime = null;
    hookIsLedge = false;

    constructor(player) {
        Log("Created new Widowmaker for "+player);
        this.ePlayer = player;
        this.playerScope = player.GetScriptScope();

        this.Bind();

        this.cbAttack1 = this.OnAttack1.bindenv(this);
        this.cbAttack2 = this.OnAttack2.bindenv(this);
        this.cursor.AddAttack1Listener(this.cbAttack1);
        this.cursor.AddAttack2Listener(this.cbAttack2);
    }

    function Bind() {
        this.cursor = ::FindCursorOfPlayer(this.ePlayer);

        ::StripWeapons(this.ePlayer);
        ::GiveWeapons(this.ePlayer, ["weapon_knife", "weapon_taser"]);
    }

    function Think() {
        // make us move towards the hook if we are currently hooking
        if (this.state == WidowmakerState.HOOKING) {
            // we stop hooking once we're pretty close to hook target
            // we also stop hooking if we've been hooking for 3 seconds
            local direction = this.hookTarget - this.ePlayer.GetOrigin();
            local distance = direction.Norm();
            if (distance < 32 || Time() - this.hookStartTime > 3) {
                this.state = WidowmakerState.IDLE;
            } else {
                this.ePlayer.SetVelocity(direction * 512);
            }
        }

        // make sure we always have a taser
        if (::find_in_array(::GetWeapons(this.ePlayer), "weapon_taser") == null) {
            ::GiveWeapons(this.ePlayer, ["weapon_taser"]);
        }
    }

    function Destroy() {
        this.state = WidowmakerState.DESTROYED;

        this.cursor.RemoveAttack1Listener(this.cbAttack1);
        this.cursor.RemoveAttack2Listener(this.cbAttack2);
    }

    function OnAttack1() {
        Log("[Widowmaker] Attack 1");
        Log(::GetActiveWeapon(this.ePlayer));
    }

    function OnAttack2() {
        if (::GetActiveWeapon(this.ePlayer) == "weapon_taser" && this.state == WidowmakerState.IDLE) {
            this.FireHook();
        }
    }

    function FireHook() {
        if (!this.cursor) {
            Warn("[Widowmaker] Fired hook without cursor; something went wrong");
            return;
        }

        local targetPos = this.cursor.GetLookingAt();
        local finalPos = targetPos;

        local direction = targetPos - this.ePlayer.EyePosition();
        direction.z = 0;
        local length = direction.Norm();
        if (length < 64 || length > 512) {
            // TODO: add fail response
            Log("[Widowmaker] Hook had length "+length+", ignoring");
            return;
        }

        // check if we are hooking just below an edge
        this.hookIsLedge = false;
        local ledgeTestPos = targetPos + (direction * 8) + Vector(0, 0, 32);
        local ledgePos = ::TraceInDirection(ledgeTestPos, Vector(0, 0, -1));
        local ledgeDist = abs(ledgeTestPos.z - ledgePos.z);
        if (ledgeDist > 2 && ledgeDist < 32) { // 2 unit buffer for the hell of it
            this.hookIsLedge = true;
            finalPos = targetPos + Vector(0, 0, ledgeDist);
        }

        this.state = WidowmakerState.HOOKING;
        this.hookTarget = finalPos;
        this.hookStartTime = Time();

        // player has to be free of ground for him to move close to horizontal - move him just off the ground if we can
        local spaceAboveHead = abs(
            this.ePlayer.EyePosition().z
            - (::TraceInDirection(this.ePlayer.EyePosition(), Vector(0, 0, 1), this.ePlayer)).z
        );
        if (spaceAboveHead > 24) {
            this.ePlayer.SetOrigin(this.ePlayer.GetOrigin() + Vector(0, 0, 24));
        }

        // draw debugging stuff if we are debugging
        if (::IsDebug() && false) {
            DrawBox(targetPos, Vector(4,4,4), Vector(0,0,255), 5);
            DrawBox(ledgeTestPos, Vector(4,4,4), Vector(0,0,255), 5);
            DrawBox(ledgePos, Vector(4,4,4), Vector(0,255,0), 5);
            DrawLine(ledgeTestPos, ledgePos, Vector(0,255,0), 5);
            DrawBox(finalPos, Vector(6,6,6), Vector(255,0,0), 5);
        }
    }
}