// Handles displaying stuff to players
// Exposes:
//   ::COLORS{}
//   ::ChatMessageAll(msg)
//   ::ChatMessageCT(msg)
//   ::ChatMessageT(msg)

DoIncludeScript("vip/players.nut", null);

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

::ChatMessageAll <- function(msg) {
    ScriptPrintMessageChatAll(msg);
}
::ChatMessageCT <- function(msg) {
    ScriptPrintMessageChatTeam(TEAM_CT, msg);
}
::ChatMessageT <- function(msg) {
    ScriptPrintMessageChatTeam(TEAM_T, msg);
}