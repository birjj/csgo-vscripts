# VIP gamemode

CTs take the VIP to the helicopter. Ts kill him. 

The VIP has 200 HP, but can only use pistols. If he tries to buy another weapon (or has one from a previous round) he'll drop it if he switches to it twice.

## Usage

Extract `lib/` and `gamemode.nut` to `steamapps/Counter-Strike: Global Offensive/csgo/scripts/vscripts/vip` (create the last folder if it doesn't exist).  
Extract `resources/*` to `steamapps/Counter-Strike: Global Offensive/csgo` (so `models` merges with CS:GO's `models`).

When mapping, insert a `func_instance` entity into your map, pointing to `vmfs/instance_vip_entities.vmf` - make sure "Entity Name Fix Up" is set to "None". This adds all the stuff needed to make the gamemode work to your map.  
Then insert another `func_instance` pointing to `vmfs/instance_vip_rescue.vmf`. This will add a VIP rescue zone to your map. If you want multiple rescue zones, you want "Entity Name Fix Up" to be "Prefix".

**Important:** In order for the VIP to be able to see his own arms, your map needs a `.kv` file. You can copy-paste the `vmfs/test_vip.kv` file from this repo and rename it to match your map.

## Known bugs

- **Bots are able to use weapons while VIP**  

    _This is because bots do not respond to client commands, so we cannot make them switch weapons when using illegal weapons. Any ideas for workarounds are appreciated._

- **Bots don't know where to go**  

    _Not a whole lot can be done about teaching bots the gamemode, but could try spawning an Hostage entity inside Helicopter to "bait" CTs into the Helicopter, and making the hostage invisible/untargatable. This would of course cause some other weird problems such as Terrorist bots saying things like "Gonna camp the hostage" and such. No elegant solution._

- **Quickswitch may drop pistol on certain ocasions**  

    _This is caused by the delay between server and client. If client switches to another weapon before it receives the `drop` command from the server, then said weapon will be dropped instead. Fix would be to send a `slot1` (or whatever slot the illegal weapon is in) before sending the `drop`._

- **Fix economy**

    _Add propper economy balance_

- **Dead people don't get Money rewards**

    _That or only when BotTakeOver occurs, the player taking over doesn't get money, needs to be verified_

- **When VIP is Rescued, ResetVIP() resets his skin to default**

    _This is noticeable by people outside the helicopter who are looking inside_
    
- **Gamemode shouldn't work until warmup is over**

    _Can be solved with event_listener for warmup detection_

~~- **When Hostage is spawned, he may sometimes be floating**~~

    _This is due to him spawning where there is a grenade projectile or a player_
    
    _**ALSO RELATED:** z offset for spawning hostage needs to be adjusted, otherwise dieing in "underground" may spawn hostage on floor above._

~~- **When Hostage is spawned, he always spawns with the same rotation regardless of player orientation**~~
    
    _We need to take VIPs rotation and rotate entity_maker to match that._

- **When Hostage is spawned, he gets slightly offset to the side.**

    _Seems to be caused because there's still an entity in the position the VIP should take the exact moment he spawns. Could probably delay another frame? This is a bigger problem when he is enclosed in tight space (vents, where he could be pushed outside the map)_

~~- **Hostage VIP shouldn't take damage from grenades or shots**~~

    _Should be fixed by using filter_damage_type (it is, I tried)_
    
- **When Hostage HP reaches 0% he should become Ragdoll**

    _Se7en should be on it, need ragdoll animation for this to work. If it doesn't work, we could still instantiate a prop_ragdoll with VIPs model on that position. Purely cosmetic feature._
    
~~- **When VIP is downed, there should be a way to keep track on his HP on HUD.**~~
    
    _So people can see when he's about to die_
    
- **When VIP dies to World (fall damage, trigger hurt, etc...), he receives damage, but that won't kill the VIP hostage**
    
    _Undesirable scenario: VIP jumps off building, the hostage is spawned at an unreachable position._

    _**Proposed solutions:**_
    
        - Whenever VIP is touching trigger_hurt instantly kill and end the round.
    
        - Only ever spawn an hostage entity if the VIP dies to a Player (aka not World), this could prevent intentional suicide transfering of VIP status too.
    
- **When the VIP dies to a multikill (f.e. AWP shot) some issues occur.**

    _Sometimes an Hostage VIP won't spawn, or 2 might spawn depending on who the shot hits first._
    
    _Case 1: VIP is lined up with a team mate. VIP gets shot, dies and the friend behind him dies too. No hostage will spawn in this case._
    
    _Case 2: VIP is lined up with a team mate. Team mate gets shot first, dies and the VIP also dies behind him. 2 Hostages will spawn in this case._
    
    _Case 3: If in like Case 2, 2 team mates are standing in front of VIP, all 3 die and VIP is the last one to die, 3 Hostages will spawn._
    
    _In all these cases only the first VIP to spawn gets the VIP skin._
    
    _When checking if VIP died, of all units that died in the same tick, only the last one will be considered to determine whether or not the VIP died. If the VIP dies last of **X** people to the same shot, **X** hostages will spawn, if he is in the middle or is first, no hostage will be spawned because the last person to die was not VIP._
    
- **It is possible for VIP to use primary.**

    _How to replicate: Be VIP, buy m4, hold pistol. Drop pistol and m4 automaticly comes out and you can use it, as long as you don't swap back to knife or pistol._
