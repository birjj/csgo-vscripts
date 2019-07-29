/**
 * https://github.com/birjolaxew/csgo-vscripts
 * A representation of a player in the Portal gamemode
 */

DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/cursors.nut", null);
DoIncludeScript("lib/math.nut", null);
DoIncludeScript("lib/templates.nut", null);
DoIncludeScript("lib/timers.nut", null);

::ePortalTesterTmpl <- Entities.FindByName(null, "portal_portalcheckertemplate");
Log("=== PORTAL TESTER "+::ePortalTesterTmpl);

class PortalPlayer {
    ePlayer = null;
    cursor = null;

    cbAttack1 = null;
    cbAttack2 = null;

    portalTarget = null;
    portalSurfaceNormal = null;
    ePortalTester = null;

    constructor(player) {
        this.ePlayer = player;
        this.Bind();
        this.cbAttack1 = this.OnAttack1.bindenv(this);
        this.cbAttack2 = this.OnAttack2.bindenv(this);
        this.cursor.AddAttack1Listener(this.cbAttack1);
        this.cursor.AddAttack2Listener(this.cbAttack2);
    }

    function Destroy() { this.cursor.Destroy(); }
    function Bind() { this.cursor = ::FindCursorOfPlayer(this.ePlayer); }

    function SpawnPortal(point) {
        Log("=== SPAWNING PORTAL");
    }

    function OnAttack1() {
        local lookingAt = this.cursor.GetLookingAt();
        local delta = lookingAt - this.ePlayer.EyePosition();
        delta.Norm();
        local traceFrom = lookingAt - delta * 1;
        local normal = ::NormalOfSurface(traceFrom);

        if (!::ePortalTesterTmpl || !::ePortalTesterTmpl.IsValid()) {
            Warn("Cannot find portal_portalcheckertemplate ("+::ePortalTesterTmpl+")");
        }
        this.portalTarget = lookingAt;
        this.portalSurfaceNormal = normal;
        // checking if it's within a portal is... messy
        // we spawn a tester, move it to our target, wait a frame, then test if a trigger has renamed it
        ::SpawnTemplate(::ePortalTesterTmpl, (function(ents) {
            foreach(ent in ents) {
                if (ent.GetName() == "portal_portalchecker") {
                    this.ePortalTester = ent;
                    local target = this.portalTarget;
                    ent.SetOrigin(target);
                    TimerHandler(0, (function(){
                        if (!this.ePortalTester) {
                            Warn("Unknown portal tester!");
                            return;
                        }
                        if (this.ePortalTester.GetName() != "portal_portalchecker") {
                            this.SpawnPortal(this.portalTarget);
                        }
                        this.ePortalTester.Destroy();
                        this.ePortalTester = null;
                    }).bindenv(this), true);
                }
            }
        }).bindenv(this));
    }
    function OnAttack2() {}
}