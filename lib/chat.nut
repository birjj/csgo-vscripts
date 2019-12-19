// https://github.com/birjolaxew/csgo-vscripts
// == Chat messages
// Handles displaying stuff to players
// You can colorize your messages using " {green}test{yellow}ing{blue} this{red} thing"
// (remember an empty space at the start or colors won't work - thanks Valve!)
// Exposes:
//   ::COLORS{}
//   ::ChatMessageAll(msg)
//   ::ChatMessageCT(msg)
//   ::ChatMessageT(msg)

DoIncludeScript("lib/players.nut", null);
DoIncludeScript("lib/polyfills.nut", null);

::COLORS <- {
    invisible = "\x00"
    white = "\x01"
    dark_red = "\x02"
    purple = "\x03"
    green = "\x04"
    light_green = "\x05"
    lime_green = "\x06"
    red = "\x07"
    grey = "\x08"
    yellow = "\x09"
    light_blue = "\x0a"
    blue = "\x0b"
    dark_blue = "\x0c"
    light_blue2 = "\x0d"
    pink = "\x0e"
    light_red = "\x0f"
    orange = "\x10"
};

::_chat_colorRegexp <- regexp("{([^}]+)}");
::_chat_format <- function(msg) {
    local i = 0;
    local result = null;
    local start = 0;
    while ((result = ::_chat_colorRegexp.capture(msg, start)) != null && i < 100) {
        local color = msg.slice(result[1].begin, result[1].end);
        if (color in ::COLORS) {
            msg = msg.slice(0,result[0].begin) + ::COLORS[color] + msg.slice(result[0].end);
            start = result[0].begin + ::COLORS[color].len();
        } else {
            start = result[0].end;
        }
        ++i;
    }
    return msg;
}
::ChatMessageAll <- function(msg) {
    local msgs = split(msg, "\n");
    foreach(msg in msgs) {
        ScriptPrintMessageChatAll(::_chat_format(msg));
    }
}
::ChatMessageCT <- function(msg) {
    ScriptPrintMessageChatTeam(TEAM_CT, ::_chat_format(msg));
}
::ChatMessageT <- function(msg) {
    ScriptPrintMessageChatTeam(TEAM_T, ::_chat_format(msg));
}