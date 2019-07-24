/**
 * https://github.com/birjolaxew/csgo-vscripts
 * Handles getting and settings weapons on a player
 * In order to be able to get active weapon, you must add a listener for item_equip to your map (see events.nut)
 *   You must also add the listeners required by players.nut
 * Exposes:
 *   - GetActiveWeapon(player)
 *   - GetWeapons(player)
 *   - StripWeapons(player)
 */

 DoIncludeScript("lib/players.nut", null);

/* Gets the active weapon of a player - returns class string (e.g. weapon_glock), or null if unknown */
::GetActiveWeapon <- function(player) {
    local scope = player.GetScriptScope();
    if (!("weapon_data" in scope)) { return null; }
    return "weapon_"+scope.weapon_data.item;
}

/** Gets all weapons a player is currently carrying - returns array of class strings (e.g. weapon_glock) */
::GetWeapons <- function(player) {
    // loop through move children
    local weapons = [];
    local ent = player.FirstMoveChild();
    while (ent != null) {
        if (ent.GetClassname().find("weapon_") != null) {
            weapons.push(ent.GetClassname());
        }
        ent = ent.NextMovePeer();
    }
    return weapons;
}

/** Strips all weapons from a player */
::StripWeapons <- function(player) {
    local weaponstrip = Entities.FindByClassname(null, "player_weaponstrip");
    if (weaponstrip == null) {
        weaponstrip = Entities.CreateByClassname("player_weaponstrip");
    }
    EntFireByHandle(weaponstrip, "Strip", "", 0.0, player, player);
}

/** Gives weapons to a player - expects weapons to be an array of classnames */
::GiveWeapons <- function(player, weapons) {
    local equipper = Entities.CreateByClassname("game_player_equip");
    foreach(weapon in weapons) {
        equipper.__KeyValueFromInt(weapon, 1); // couldn't get count to work - please make PR if you can
    }
    
    EntFireByHandle(equipper, "Use", "", 0.0, player, player);
    EntFireByHandle(equipper, "Kill", "", 2.0, null, null);
}

if (!("_LOADED_MODULE_WEAPONS" in getroottable())) {
    ::_LOADED_MODULE_WEAPONS <- true;

    ::AddEventListener("item_equip", function(data){
        local player = ::Players.FindByUserid(data.userid);
        if (!player) { return; }
        if (!player.ValidateScriptScope()) { return; }
        local scope = player.GetScriptScope();
        scope.weapon_data <- data;
    });
}