// https://github.com/birjolaxew/csgo-vscripts
// == UI messages
// Handles displaying stuff to players
// Exposes:
//   ::ShowMessage(msg, player, style="", delay=0.0)
//   ::ShowMessageSome(msg, filter, style="", delay=0.0)

DoIncludeScript("vip/lib/players.nut", null);

if (!("_LOADED_MODULE_UI" in getroottable())) {
    ::_LOADED_MODULE_UI <- true;
    ::ShowMessage <- function(msg, player, style="", delay=0.0) {
        local hudhint = Entities.CreateByClassname("env_hudhint");
        hudhint.__KeyValueFromString("message", "<font "+style+">"+msg+"</font>");
        EntFireByHandle(hudhint, "ShowHudHint", "", delay, player, null);
        EntFireByHandle(hudhint, "Kill", "", 0.5, null, null);
    }

    ::ShowMessageSome <- function(msg, filter, style="") {
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player") {
                if (filter == null || filter(ent)) {
                    ::ShowMessage(msg, ent, style);
                }
            }
            ent = Entities.Next(ent);
        }
    }
}