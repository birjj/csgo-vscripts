# VIP gamemode

CTs take the VIP to the helicopter. Ts kill him. 

The VIP has 200 HP, but can only use pistols. If he tries to buy another weapon (or has one from a previous round) he'll drop it if he switches to it twice.

## Usage

Extract `lib/` and `gamemode.nut` to `steamapps/Counter-Strike: Global Offensive/csgo/scripts/vscripts/vip` (create the last folder if it doesn't exist).  
Extract `resources/*` to `steamapps/Counter-Strike: Global Offensive/csgo` (so `models` merges with CS:GO's `models`).

**Important:** In order for the VIP to be able to see his own arms, your map needs a `.kv` file. You can copy-paste the `vmfs/test_vip.kv` file from this repo and rename it to match your map.
