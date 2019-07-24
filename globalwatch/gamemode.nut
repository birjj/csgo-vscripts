/**
 * https://github.com/birjolaxew/csgo-vscripts
 * The actual state holder and delegator for the Globalwatch gamemode
 */

DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("globalwatch/heroes/widowmaker.nut", null);

enum Heroes {
    WIDOWMAKER,
}
::HERO_CLASSES <- [
    HeroWidowmaker,
];

class GamemodeGlobalwatch {
    constructor() {
    }

    function Think() {
        foreach (player in ::Players.GetPlayers()) {
            if (!player.ValidateScriptScope) { continue; }
            local scope = player.GetScriptScope();
            if (!("gw_hero" in scope)) { continue; }
            scope.gw_hero.Think();
        }
    }

    function OnRoundStart() {
        foreach (player in ::Players.GetPlayers()) {
            if (!player.ValidateScriptScope) { continue; }
            local scope = player.GetScriptScope();
            if (!("gw_hero" in scope)) { continue; }
            scope.gw_hero.Bind();
        }
    }

    /** Assigns a hero to a player.
     * @param {Heroes} hero The hero to assign */
    function AssignHero(hero) {
        local player = activator;
        Log("Got asked to assign hero "+hero+" to "+player);
        if (!activator.ValidateScriptScope()) {
            Warn("Couldn't validate script scope of "+player+" while assigning hero");
            return;
        }
        local scope = player.GetScriptScope();
        if ("gw_hero" in scope) {
            Warn("Was asked to assign hero to player that already has one; ignoring");
            return;
        }
        scope.gw_hero <- ::HERO_CLASSES[hero](player);
    }

    /** Destroys a hero and removes references to it */
    function UnassignHero(player) {
        local scope = player.GetScriptScope();
        scope.gw_hero.Destroy();
    }
}