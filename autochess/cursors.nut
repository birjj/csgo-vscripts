/**
 * Dynamically adds logic_measure_movements to map to track what each player is looking at
 * Exposes:
 *   - FindCursorOfPlayer(player)
 * Each cursor instance exposes:
 *   - GetAngles()
 *   - GetLookingAt()
 */

DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/events.nut", null);
DoIncludeScript("lib/math.nut", null);
DoIncludeScript("lib/players.nut", null);
DoIncludeScript("lib/timer.nut", null);

/**
 * Gets the cursor that is bound to a particular player entity
 * If no cursor is bound, returns null
 */
::FindCursorOfPlayer <- function(player) {
    if (player == null) { return null; }
    if (!player.ValidateScriptScope()) { return null; }
    local scope = player.GetScriptScope();
    if ("cursor" in scope) {
        return scope.cursor;
    }
    return null;
};

class PlayerCursor {
    eMeasureMovement = null;
    eRef = null;
    refName = null;
    eTarget = null;
    targetName = null;

    ePlayer = null;
    tmpPlayerName = null;
    oldPlayerName = null;

    isAwaitingBind = false;

    constructor(player) {
        printl("[Cursor] Generating cursor for "+player);
        this.ePlayer = player;
        this.Regenerate();
    }

    function Regenerate() {
        this.Destroy();

        this.eMeasureMovement = Entities.CreateByClassname("logic_measure_movement");
        EntFireByHandle(this.eMeasureMovement, "AddOutput", "MeasureType 1", 0.0, null, null);
        this.eRef = Entities.CreateByClassname("info_target");
        this.eTarget = Entities.CreateByClassname("info_target");
        local origin = Vector(0, 0, 0);
        this.eRef.SetOrigin(origin);
        this.eTarget.SetOrigin(origin);

        // measure_movement uses targetnames - we create some here
        oldPlayerName = this.ePlayer.GetName();
        tmpPlayerName = UniqueString("cursor_player");
        refName = UniqueString("cursor_ref");
        targetName = UniqueString("cursor_target");
        EntFireByHandle(this.ePlayer, "AddOutput", "targetname "+tmpPlayerName, 0.0, null, null);
        EntFireByHandle(this.eRef, "AddOutput", "targetname "+refName, 0.0, null, null);
        EntFireByHandle(this.eTarget, "AddOutput", "targetname "+targetName, 0.0, null, null);

        // this is required for measure_movement to work - don't ask me why
        this.eMeasureMovement.__KeyValueFromString("MeasureReference", refName);
        this.eMeasureMovement.__KeyValueFromString("MeasureTarget", refName);
        this.eMeasureMovement.__KeyValueFromString("Target", targetName);
        this.eMeasureMovement.__KeyValueFromString("TargetReference", refName);

        // we actually tell the measure_movement about our entities in the next frame
        this.isAwaitingBind = true;
    }

    function BindEntities() {
        Log("[Cursor] Binding cursor { ply="+ePlayer+", ref="+eRef+", target="+eTarget+" }");

        EntFireByHandle(this.eMeasureMovement, "SetMeasureReference", refName, 0.0, null, null);
        EntFireByHandle(this.eMeasureMovement, "SetTargetReference", refName, 0.0, null, null);
        EntFireByHandle(this.eMeasureMovement, "Target", targetName, 0.0, null, null);
        EntFireByHandle(this.eMeasureMovement, "SetMeasureTarget", ePlayer.GetName(), 0.0, null, null);
        EntFireByHandle(this.eMeasureMovement, "Target", targetName, 0.0, null, null);
        EntFireByHandle(this.eMeasureMovement, "Enable", "", 0.0, null, null);

        this.isAwaitingBind = false;
    }

    function Destroy() {
        if (this.eMeasureMovement != null && this.eMeasureMovement.IsValid()) {
            this.eMeasureMovement.Destroy();
            this.eMeasureMovement = null;
        }
        if (this.eRef != null && this.eRef.IsValid()) {
            this.eRef.Destroy();
            this.eRef = null;
        }
        if (this.eTarget != null && this.eTarget.IsValid()) {
            this.eTarget.Destroy();
            this.eTarget = null;
        }
    }

    function GetAngles() {
        return this.eTarget.GetForwardVector();
    }

    function GetLookingAt() {
        return ::TraceInDirection(this.ePlayer.EyePosition(), this.GetAngles(), this.ePlayer);
    }
}

if (!("_LOADED_MODULE_CURSORS" in getroottable())) {
    ::_LOADED_MODULE_CURSORS <- true;

    ::_cursors_Think <- function() {
        local players = ::Players.GetPlayers();
        foreach (ply in players) {
            local cursor = ::FindCursorOfPlayer(ply);
            if (cursor != null && cursor.isAwaitingBind) {
                cursor.BindEntities();
            }
        }
    };
    
    ::AddEventListener("player_spawn", function(data) {
        local ply = ::Players.FindByUserid(data.userid);
        if (ply == null) { return; }
        if (!ply.ValidateScriptScope()) { return; }
        local scope = ply.GetScriptScope();
        if ("cursor" in scope) {
            scope.cursor.Regenerate();
            return;
        }

        scope.cursor <- PlayerCursor(ply);
    });
}