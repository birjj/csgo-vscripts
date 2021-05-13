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
    
- **When a player swaps from T to CT, and happens to replace the bot that was suposedly VIP some shit happens.**

    _The replaced bot still spawns for the first frame aparently, and if he happens to have been select to be VIP, the player spawns, the VIP is dead in that same position inside the hostage entity._
    
- **[NOT A BUG] Could probably make mode more friendly towards spectator.**

    _Small things like printing messages from Ts and CTs to spectator as well, ex.: When VIP countdown is happening. To make the spectator experience atleast decent._
