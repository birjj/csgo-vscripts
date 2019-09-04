/**
 * https://github.com/birjolaxew/csgo-vscripts
 * A representation of a portal in the Portal gamemode
 * Also includes some global stuff for interacting with it
 */
DoIncludeScript("lib/math.nut", null);

::_portal_map <- {};

::OnEnteredTeleport <- function(teleScope) {
    if (!("_portal_uid" in teleScope)) {
        Warn("Entered portal that wasn't bound to portal instance");
        return;
    }
    local uid = teleScope._portal_uid;
    if (!(uid in ::_portal_map)) {
        Warn("Entered portal, but cannot find its portal instance");
        return;
    }
    ::_portal_map[uid].OnEnter(activator);
};

class Portal {
    player = null; // the Player instance
    ents = null;
    normal = null;
    origin = null;
    partner = null; // the Portal instance we connect to
    uid = "";

    constructor(ents, player, normal, origin) {
        this.ents = ents;
        this.normal = normal;
        this.origin = origin;
        this.uid = "portal_trigger_"+UniqueString();
        ::_portal_map[this.uid] <- this;

        foreach(ent in ents) {
            ent.SetOrigin(origin);
            ent.SetForwardVector(normal);
        }
        
        // bind to the teleport trigger
        if (!("portal_portaltele" in ents) || !ents["portal_portaltele"].ValidateScriptScope()) {
            Warn("Couldn't find tele for portal instance");
        } else {
            local teleScope = ents["portal_portaltele"].GetScriptScope();
            teleScope._portal_uid <- this.uid;
        }
    }

    function RegisterPartner(partner) {
        this.partner = partner;
    }
    
    function OnEnter(player) {
        // we use a 0.5 cooldown per player to make sure we don't teleport them right after they've gotten emitted from us
        if (!player.ValidateScriptScope()) { return; }
        local scope = player.GetScriptScope();
        if ((this.uid in scope) && Time() - scope[this.uid] < 0.5) { return; }

        local vel = player.GetVelocity();
        local relativeVel = ::GetRelativeVector(this.normal, vel, this.origin);
        if (this.partner && this.partner.IsValid()) {
            this.partner.Emit(player, relativeVel);
        }
    }

    function Emit(player, relativeVel) {
        // we use a 0.5 cooldown per player to make sure we don't teleport them right after they've gotten emitted from us
        if (!player.ValidateScriptScope()) { return; }
        local scope = player.GetScriptScope();
        scope[this.uid] <- Time();

        Log("Emitting "+player+" from "+this.uid);
        local vel = ::ApplyRelativeVector(this.normal, relativeVel, this.origin);
        player.SetOrigin(this.origin + this.normal * 64);
        player.SetVelocity(vel * -1);
    }

    function IsValid() {
        foreach(ent in this.ents) {
            if (ent && !ent.IsValid()) {
                return false;
            }
        }
        return true;
    }

    function Destroy() {
        foreach(ent in this.ents) {
            if (ent && ent.IsValid()) {
                ent.Destroy();
            }
        }
    }
}