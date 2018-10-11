A collection of VScripts for CS:GO.

## Notes on Squirrel

Developing VScripts is cumbersome, mostly due to the poor documentation. Here are a few notes on things I've learned as I've worked on this collection:

<dl>
<dt>Understand how Squirrel is embedded in CS:GO</dt>
<dd>Every entity in CS:GO has a "script scope" - this is simply a table which the entity executes code in the context of. When you specify a "Script think function" on an entity, said function is searched for in the script scope. This script scope will not be killed until the entity is, and can therefore be used to hold entity-specific state.<br>
You can access the script scope by using <code>.GetScriptScope()</code> (remember to <code>.ValidateScriptScope()</code> first), where you can then define properties like on any other table.<br><br>
In addition to this you have a root table, which every script in any context has access to. This is accessed by <code>getroottable()</code> or by prefixing variables with <code>::</code>. Use this for any code that should be accessibly globally.</dd>
<dt>CS:GO's Squirrel is old</dt>
<dd>The version of Squirrel that is embedded in CS:GO is <a href="http://www.squirrel-lang.org/doc/squirrel2.html" target="_blank">Squirrel 2.2</a>. This means that some of the newer features (e.g. <code>.find()</code> or <code>in</code> on arrays) aren't available.</dd>
<dt>Outputs are asynchronous</dt>
<dd>Be careful when triggering outputs on entities (e.g. showing messages using an <code>env_hudhint</code>) - they will not execute until your Squirrel code is finished. You can wait until the next think cycle to work around this.</dd>
<dt>Entities will not react to script-created keyvalues by themselves</dt>
<dd>If you have an entity that is supposed to do something without being triggered by an input (e.g. a <code>logic_eventlistener</code>) then you cannot set it up in your VScript, as the <code>__KeyValueFrom*</code> functions do not execute any related logic. You must instead set it up in Hammer.<br>
If you have an entity that reads its keyvalues on input (e.g. a <code>env_hudhint</code>) then it's fine to set it up in your VScript, as it will read the keyvalue directly when you trigger it.</dd>
<dt>Callbacks cannot access their containing closure</dt>
<dd>Even though functions are first-order citizens in Squirrel, they do not have access to the closure in which they were defined. You have to work around this by using <code>.bindenv()</code>, or by using a class method (in which case <code>this</code> refers to the class instance).
<code><pre>function CallCallback(cb) { cb(); }
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
}</pre></code></dd>
<dt>Script files are executed every round, but root table remains unchanged</dt>
<dd>At the start of every round, every entity's script is executed. However, the root table still contains any data set from previous runs. Any code you want to run every round (e.g. creating entities, which are invalidated at the end of every round) is fine with this, but any code you want to keep across rounds (e.g. keeping track of state) should be placed behind a guard and store its state in the root table.</dd>
</dl>