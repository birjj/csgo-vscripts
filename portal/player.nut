/**
 * https://github.com/birjolaxew/csgo-vscripts
 * A representation of a player in the Portal gamemode
 */

DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/cursors.nut", null);
DoIncludeScript("lib/math.nut", null);
DoIncludeScript("lib/templates.nut", null);
DoIncludeScript("lib/timers.nut", null);
DoIncludeScript("portal/portal.nut", null);

::ePortalTesterTmpl <- Entities.FindByName(null, "portal_portalcheckertemplate");
::ePortalTmpl <- Entities.FindByName(null, "portal_portaltemplate");

enum PORTAL_TYPES {
    FIRST,
    SECOND
}

const PORTAL_FIRE_DELAY = 0.3;
class PortalPlayer {
    ePlayer = null;
    cursor = null;
    colors = ["255 0 0", "0 0 255"];
    portals = [null, null];

    cbAttack1 = null;
    cbAttack2 = null;

    lastPortalTime = 0;
    portalTarget = null;
    portalSurfaceNormal = null;
    portalType = null;
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

    /** Fires a portal at where our player is looking */
    function FirePortal(type) {
        if (lastPortalTime && Time() - lastPortalTime < PORTAL_FIRE_DELAY) { return; }
        lastPortalTime = Time();
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
        this.portalType = type;
        // checking if it's possible to place a portal is... messy
        // we spawn a tester, move it to our target, wait a frame, then test if a trigger has renamed it
        ::SpawnTemplate(::ePortalTesterTmpl, (function(ents) {
            foreach(ent in ents) {
                if (ent.GetName() == "portal_portalchecker") {
                    this.ePortalTester = ent;
                    local target = this.portalTarget;
                    ent.SetOrigin(target);
                    TimerHandler(0.1, (function(){
                        if (!this.ePortalTester) {
                            Warn("Unknown portal tester!");
                            return;
                        }
                        if (this.ePortalTester.GetName() != "portal_portalchecker") {
                            this.SpawnPortal();
                        }
                        this.ePortalTester.Destroy();
                        this.ePortalTester = null;
                    }).bindenv(this), true);
                }
            }
        }).bindenv(this));
    }

    /** Spawns a portal (type previously set) at our portal location */
    function SpawnPortal() {
        ::SpawnTemplate(::ePortalTmpl, (function(ents) {
            if (this.portals[this.portalType]) {
                this.portals[this.portalType].Destroy();
            }
            EntFireByHandle(ents["portal_portal"], "Color", this.colors[this.portalType], 0.0, null, null);
            local portal = Portal(ents, this, this.portalSurfaceNormal, this.portalTarget);
            local otherPortal = this.portals[1 - this.portalType];
            if (otherPortal) {
                otherPortal.RegisterPartner(portal);
                portal.RegisterPartner(otherPortal);
            }
            this.portals[this.portalType] = portal;
        }).bindenv(this));
    }

    function OnAttack1() {
        this.FirePortal(PORTAL_TYPES.FIRST);
    }
    function OnAttack2() {
        local lookingAt = this.cursor.GetLookingAt();
        local delta = lookingAt - this.ePlayer.EyePosition();
        delta.Norm();
        local traceFrom = lookingAt - delta * 1;
        local normal = ::NormalOfSurface(traceFrom);
        local reflected = ::GetReflection(delta, normal * -1);
        local relative = ::GetRelativeVector(normal, delta);

        ::DrawLine(lookingAt, lookingAt + normal * 16, Vector(255,0,0));
        ::DrawLine(lookingAt, lookingAt + delta * 16, Vector(0,255,0));
        ::DrawLine(lookingAt, lookingAt + reflected * 16, Vector(0,0,255));
        ::DrawLine(lookingAt, lookingAt + (normal * -1) * 16, Vector(0,255,255));
        ::DrawLine(lookingAt, lookingAt + ::ApplyRelativeVector(normal, relative) * 16, Vector(255,0,255));

        this.FirePortal(PORTAL_TYPES.SECOND);
    }
}