DoIncludeScript("lib/debug.nut", null);
DoIncludeScript("lib/events.nut", null);
DoIncludeScript("lib/polyfills.nut", null);

::_command_prefixes <- ["!", "/", "."];
::_command_HandleChat <- function(msg, userid) {
    local prefix = msg.slice(0,1);
    if (::find_in_array(::_command_prefixes, prefix) == null) {
        return;
    }

    local cmds = split(strip(msg.slice(1)), " ");
    if (cmds.len() == 0) { return; }
    local cmd = cmds[0].tolower();
    if (cmd in ::_command_registered) {
        if (cmds.len() > 1) {
            ::_command_registered[cmd](userid, cmds.slice(1));
        } else {
            ::_command_registered[cmd](userid);
        }
    }
};

::RegisterCommand <- function(name, callback) {
    if (typeof name == "array") {
        foreach(n in name) {
            ::RegisterCommand(n, callback);
        }
        return;
    }

    if (name in ::_command_registered) {
        Warn("[commands] Attempting to register command '"+name+"', but is already registered");
        return;
    }
    ::_command_registered[name] <- callback;
}

if (!("_LOADED_MODULE_COMMANDS" in getroottable())) {
    ::_LOADED_MODULE_COMMANDS <- true;
    ::_command_registered <- {};
    ::AddEventListener("player_say", function(data){
        ::_command_HandleChat(data.text, data.userid);
    });
}