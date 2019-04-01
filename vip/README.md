# VIP gamemode

CTs take the VIP to the helicopter. Ts kill him. 

The VIP has 200 HP, but can only use pistols. If he tries to buy another weapon (or has one from a previous round) he'll drop it if he switches to it twice.

## Usage

Extract `lib/` and `gamemode.nut` to `steamapps/Counter-Strike: Global Offensive/csgo/scripts/vscripts/vip` (create the last folder if it doesn't exist).  
Extract `resources/*` to `steamapps/Counter-Strike: Global Offensive/csgo` (so `models` merges with CS:GO's `models`).

**Important:** In order for the VIP to be able to see his own arms, your map needs a `.kv` file. You can copy-paste the `vmfs/test_vip.kv` file from this repo and rename it to match your map.

## Known bugs
- Bots are able to use weapons while VIP  
    _This is because bots do not respond to client commands, so we cannot make them switch weapons when using illegal weapons. Any ideas for workarounds are appreciated._

- Bots don't know where to go  
    _Not a whole lot can be done about teaching bots the gamemode, but could try spawning an Hostage entity inside Helicopter to "bait" CTs into the Helicopter, and making the hostage invisible/untargatable. This would of course cause some other weird problems such as Terrorist bots saying things like "Gonna camp the hostage" and such. No elegant solution._

- Helicopter and smokes don't go well together  
    _If a smoke lands close to the helicopter, depending on their perspective certain players might be able to see players through the smoke. Possible solution: have a dynamic model draw on top on the animated helicopter and disable that one on lift off(???) (hopefully works)_

- Quickswitch may drop pistol on certain ocasions  
    _This is caused by the delay between server and client. If client switches to another weapon before it receives the `drop` command from the server, then said weapon will be dropped instead. Not much we can do;_

- Triggers need to be disabled after VIP escapes

- VIP sound sometimes plays in a position that it shouldn't

- Add support for multiple escape areas
