A collection of VScripts for CS:GO.

## Installation

Download this repo, extract it to `steamapps\common\Counter-Strike Global Offensive\csgo\scripts\vscripts`. It should then be useable in your maps.

## Notes on Squirrel

Developing VScripts is cumbersome, mostly due to the poor documentation. Here are a few notes on things I've learned as I've worked on this collection:

<dl>
<dt>Understand how Squirrel is embedded in CS:GO</dt>
<dd>Every entity in CS:GO has a "script scope" - this is simply a table which the entity executes code in the context of. When you specify a "Script think function" on an entity, said function is searched for in the script scope. This script scope will not be killed until the entity is, and can therefore be used to hold entity-specific state.<br>
You can access the script scope by using <code>.GetScriptScope()</code> (remember to <code>.ValidateScriptScope()</code> first), where you can then define properties like on any other table.<br><br>
In addition to this you have a root table, which every script in any context has access to. This is accessed by <code>getroottable()</code> or by prefixing variables with <code>::</code>. Use this for any code that should be accessibly globally.</dd>
<dt>CS:GO's Squirrel is old</dt>
<dd>The version of Squirrel that is embedded in CS:GO is <a href="http://www.squirrel-lang.org/doc/squirrel2.html" target="_blank">Squirrel 2.2</a>. This means that some of the newer features (e.g. <code>.find()</code> or <code>in</code> on arrays) aren't available.</dd>
<dt>Script files are executed every round, but root table remains unchanged</dt>
<dd>At the start of every round, every entity's script is executed. However, the root table still contains any data set from previous runs. Any code you want to run every round (e.g. creating entities, which are invalidated at the end of every round) is fine with this, but any code you want to keep across rounds (e.g. keeping track of state) should be placed behind a guard and store its state in the root table.</dd>
<dt>Callbacks cannot access their containing closure</dt>
<dd><p>Even though functions are first-order citizens in Squirrel, they do not have access to the closure in which they were defined. You have to work around this by using <code>.bindenv()</code>, or by using a class method (in which case <code>this</code> refers to the class instance).</p>
<pre>function CallCallback(cb) { cb(); }
class Test {
    test = null;
    constructor() {
        test = "a";
        PrintTest();
        CallCallback(PrintTest);
    }
    function PrintTest() {
        printl("this.test: "+this.test); // will succeed
        printl("test: "+test); // will error if called as callback
    }
}</pre></dd>
<dt>Outputs are asynchronous</dt>
<dd>Be careful when triggering outputs on entities (e.g. showing messages using an <code>env_hudhint</code>) - they will not execute until your Squirrel code is finished. You can wait until the next think cycle to work around this.</dd>
<dt>Entities will not react to script-created keyvalues by themselves</dt>
<dd>If you have an entity that is supposed to do something without being triggered by an input (e.g. a <code>logic_eventlistener</code>) then you cannot set it up in your VScript, as the <code>__KeyValueFrom*</code> functions do not execute any related logic. You must instead set it up in Hammer.<br>
If you have an entity that reads its keyvalues on input (e.g. a <code>env_hudhint</code>) then it's fine to set it up in your VScript, as it will read the keyvalue directly when you trigger it.</dd>
</dl>

## Known bugs
- Cannot differentiate AI from human players;<br>
_Hard to fix in a way that's reliable._

- When taking over a VIP Bot, VIP vanishes but round doesn't end;<br>
_Potential fix: Save last known VIP position, and when there's no VIP and VIP didn't die, set closest CT to last known position as VIP._

- When VIP disconnects from the server, VIP vanishes but round doesn't end;<br>
_Potential fix: Have a grace time within which a VIP can be replaced by another under certain conditions (has VIP taken damage, etc, so it can't be abused easily). If VIP disconnects way into the round, CT's should just lose the round._

- Bots don't know where to go;<br>
_Not a whole lot can be done about teaching bots the gamemode, but could try spawning an Hostage entity inside Helicopter to "bait" CTs into the Helicopter, and making the hostage invisible/untargatable. This would of course cause some other weird problems such as Terrorist bots saying things like "Gonna camp the hostage" and such. No elegant solution._

- Helicopter and smokes don't go well together;<br>
_If a smoke lands close to the helicopter, depending on their perspective certain players might be able to see players through the smoke. Possible solution: have a dynamic model draw on top on the animated helicopter and disable that one on lift off(???) (hopefully works)_

- Quickswitch may drop pistol on certain ocasions;

- 200HP on VIP seems a bit too imbalanced, needs to be lowered to about 150HP;

- Triggers need to be disabled after VIP escapes.

- VIP sound sometimes plays in a position that it shouldn't.

- Add Rescue Area on the map, to get that sweeeet [H] marker on the radar.
