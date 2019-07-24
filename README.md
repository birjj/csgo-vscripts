A collection of VScripts for CS:GO.

You're probably going to be most interested in the `lib/` folder - this is where I keep track of all the utility stuff I've extracted into library scripts, which you can use as you see fit.

If you want to use this code for learning VScript, then you should know that all the code here is a mixture of *terrible* and fairly decent code. I've learned a decent bit as I've gotten more comfortable with Squirrel, but I wouldn't recommend attempting to duplicate my code style.

If you need help with VScripts, I can suggest joining [the Source Engine Discord](https://discordapp.com/invite/sourceengine). People there do tons of stuff I wouldn't even dream of being able to.

## Installation

Download this repo, extract it to `steamapps\common\Counter-Strike Global Offensive\csgo\scripts\vscripts`.

Further installation may be necessary depending on the mod. Make sure you check each folder's README.

## Notes on Squirrel

Developing VScripts is cumbersome, mostly due to the poor documentation. Here are a few tips and tricks I've ran into:

<dl>
<dt>CS:GO's Squirrel is old</dt>
<dd>The version of Squirrel that is embedded in CS:GO is <a href="http://www.squirrel-lang.org/doc/squirrel2.html" target="_blank">Squirrel 2.2</a>. This means that some of the newer features (e.g. <code>.find()</code> or <code>in</code> on arrays) aren't available.</dd>
<dt>Script files are executed every round, but root table remains unchanged</dt>
<dd>At the start of every round, every entity's script is executed. However, the root table still contains any data set from previous runs. Any code you want to run every round (e.g. creating entities, which are invalidated at the end of every round) is fine with this, but any code you want to keep across rounds (e.g. keeping track of state) should be placed behind a guard and store its state in the root table.</dd>
<dt>VScripts are fucked</dt>
<dd><p>Valve's code tends to be... <i>interesting</i>. The VScript implementation is no exception. Whenever you rely on some Valve-implemented API, make sure you test that it returns what you expect.</p>
<p>An example of this: if you loop through entities using <code>Entities.First()/Entities.Next(ent)</code> and check <code>ent.GetClassname() == "player"</code> on each entity, you'll get all bots and players. If you instead loop through entities using <code>Entities.FindByClassname(ent, "player")</code>, then you'll only get players and not bots. Why? Because that's just the way it is. Welcome to the Source engine.</dd>
<dt>Outputs are asynchronous</dt>
<dd>Be careful when triggering outputs on entities (e.g. showing messages using an <code>env_hudhint</code>) - they will not execute until your Squirrel code is finished. You can wait until the next think cycle to work around this.</dd>
<dt>Entities will not react to script-created keyvalues by themselves</dt>
<dd>If you have an entity that is supposed to do something without being triggered by an input (e.g. a <code>logic_eventlistener</code>) then you cannot set it up in your VScript, as the <code>__KeyValueFrom*</code> functions do not execute any related logic. You must instead set it up in Hammer.<br>
If you have an entity that reads its keyvalues on input (e.g. a <code>env_hudhint</code>) then it's fine to set it up in your VScript, as it will read the keyvalue directly when you trigger it. Experiment a bit, as it's sometimes difficult to know which is which.</dd>
</dl>
