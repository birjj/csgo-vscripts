/**
 * https://github.com/birjolaxew/csgo-vscripts
 * Dynamically adds logic_measure_movements to map to track what each player is looking at
 * You must call _cursors_Think() in your Think
 * If you want to listen to Attack1/Attack2, you need to add a point_template that spawns game_ui's
 *   This point_template should have the name "_cursors_gameui_template"
 *   It should spawn a game_ui with the flags you want (usually none)
 * Exposes:
 *   - FindCursorOfPlayer(player)
 * Each cursor instance exposes:
 *   - GetAngles()
 *   - GetLookingAt()
 *   - AddAttack1Listener(cb)
 *   - RemoveAttack1Listener(cb)
 *   - AddAttack2Listener(cb)
 *   - RemoveAttack2Listener(cb)
 */

DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/events.nut", null);
DoIncludeScript("lib/math.nut", null);
DoIncludeScript("lib/players.nut", null);
DoIncludeScript("lib/timer.nut", null);
DoIncludeScript("lib/polyfills.nut", null);

/**
 * Gets the cursor that is bound to a particular player entity
 * If no cursor is bound, returns null
 */
::FindCursorOfPlayer <- function(player) {
    if (player == null) { return null; }
    if (!player.ValidateScriptScope()) { return null; }
    local scope = player.GetScriptScope();
    if ("cursor" in scope && scope.cursor.IsValid()) {
        return scope.cursor;
    }
    return ::AssignCursorToPlayer(player);
};

/**
 * Assigns a cursor to a player - automatically done when it's spawned or when a cursor is requested for a player
 */
::AssignCursorToPlayer <- function(ply) {
    if (ply == null) { return; }
    if (!ply.ValidateScriptScope()) { return; }
    local scope = ply.GetScriptScope();
    if ("cursor" in scope) {
        scope.cursor.Regenerate();
        return;
    }

    scope.cursor <- PlayerCursor(ply);
};

class PlayerCursor {
    eMeasureMovement = null;
    eRef = null;
    refName = null;
    eTarget = null;
    targetName = null;

    eGameUI = null;
    attack1CbName = null;
    attack2CbName = null;
    attack1Listeners = [];
    attack2Listeners = [];

    ePlayer = null;
    tmpPlayerName = null;
    oldPlayerName = null;

    isAwaitingBind = false;

    constructor(player) {
        Log("[Cursor] Generating cursor for "+player);
        this.ePlayer = player;

        this.attack1CbName = "cursor_ui_cb_"+UniqueString();
        this.attack2CbName = "cursor_ui_cb_"+UniqueString();
        getroottable()[this.attack1CbName] <- this.OnAttack1.bindenv(this);
        getroottable()[this.attack2CbName] <- this.OnAttack2.bindenv(this);

        this.Regenerate();
    }

    function IsValid() {
        return (this.eMeasureMovement && this.eRef && this.eTarget)
            && (this.eMeasureMovement.IsValid() && this.eRef.IsValid() && this.eTarget.IsValid());
    }

    function Regenerate() {
        this.Destroy();

        this.eMeasureMovement = Entities.CreateByClassname("logic_measure_movement");
        EntFireByHandle(this.eMeasureMovement, "AddOutput", "MeasureType 1", 0.0, null, null);
        this.eRef = Entities.CreateByClassname("info_target");
        this.eTarget = Entities.CreateByClassname("info_target");
        local origin = this.ePlayer.GetOrigin();
        this.eRef.SetOrigin(origin);
        this.eTarget.SetOrigin(origin);

        // create a game_ui for ourself, if a point_template exists
        local uiTemplate = Entities.FindByName(null, "_cursors_gameui_template");
        if (uiTemplate) {
            this.BindUiTemplate(uiTemplate);
            ::_cursors_awaitingUi.push(this);
            EntFireByHandle(uiTemplate, "ForceSpawn", "", 0.0, null, null);
        }

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

    function BindUiTemplate(eTemplate) {
        if (!eTemplate.ValidateScriptScope()) { return; }
        local scope = eTemplate.GetScriptScope();
        if (!("PreSpawnInstance" in scope)) {
            // PreSpawnInstance must be called for PostSpawn to be called too
            scope.PreSpawnInstance <- function(entClass, entName) {};
        }
        scope.PostSpawn <- function(ents) {
            foreach (handle in ents) {
                if (handle.GetClassname() == "game_ui") {
                    ::_cursors_OnGameUI(handle);
                }
            }
        }
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

    function OnGameUI(ui) {
        Log("[Cursors] Received game_ui");
        this.eGameUI = ui;

        EntFireByHandle(this.eGameUI, "Activate", "", 0.0, this.ePlayer, this.ePlayer);
        EntFireByHandle(this.eGameUI, "AddOutput", "PressedAttack !self:RunScriptCode:"+this.attack1CbName+"():0:-1", 0.0, this.ePlayer, this.ePlayer);
        EntFireByHandle(this.eGameUI, "AddOutput", "PressedAttack2 !self:RunScriptCode:"+this.attack2CbName+"():0:-1", 0.0, this.ePlayer, this.ePlayer);
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
        if (this.eGameUI != null && this.eGameUI.IsValid()) {
            this.eGameUI.Destroy();
            this.eGameUI = null;
        }
    }

    function GetAngles() {
        return this.eTarget.GetForwardVector();
    }

    function GetLookingAt() {
        return ::TraceInDirection(this.ePlayer.EyePosition(), this.GetAngles(), this.ePlayer);
    }

    function AddAttack1Listener(cb) {
        this.attack1Listeners.push(cb);
    }
    function RemoveAttack1Listener(cb) {
        ::remove_elm_from_array(this.attack1Listeners, cb);
    }
    function OnAttack1() {
        foreach(cb in this.attack1Listeners) {
            cb();
        }
    }

    function AddAttack2Listener(cb) {
        this.attack2Listeners.push(cb);
    }
    function RemoveAttack2Listener(cb) {
        ::remove_elm_from_array(this.attack2Listeners, cb);
    }
    function OnAttack2() {
        foreach(cb in this.attack2Listeners) {
            cb();
        }
    }
}

::_cursors_awaitingUi <- [];
::_cursors_OnGameUI <- function(ui) {
    if (::_cursors_awaitingUi.len() > 0) {
        local target = _cursors_awaitingUi[0];
        ::remove_elm_from_array(_cursors_awaitingUi, target);
        target.OnGameUI(ui);
    } else {
        Warn("Got game_ui but has no cursor ready to accept it; something went wrong here");
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
        ::AssignCursorToPlayer(ply);
    });
}