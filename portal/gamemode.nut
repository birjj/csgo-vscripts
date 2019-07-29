/**
 * https://github.com/birjolaxew/csgo-vscripts
 * The actual state holder and delegator for the Portal gamemode
 */

DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("portal/player.nut", null);

class GamemodePortal {
    constructor() {
    }

    function Think() {
        // bind each player that we don't know of yet
        foreach (player in ::Players.GetPlayers()) {
            if (!player.ValidateScriptScope()) { continue; }
            local scope = player.GetScriptScope();
            if ("_portal_bound" in scope) { continue; }
            scope._portal_bound <- PortalPlayer(player);
        }
    }

    function OnRoundStart() {
        foreach (player in ::Players.GetPlayers()) {
            if (!player.ValidateScriptScope()) { continue; }
            local scope = player.GetScriptScope();
            if (!("_portal_bound" in scope)) { continue; }
            scope._portal_bound.Bind();
        }
    }
}