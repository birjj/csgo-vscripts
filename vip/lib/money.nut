// https://github.com/birjolaxew/csgo-vscripts
// == Money
// Handles giving money to players
// Exposes:
//   ::GiveMoney(amount, player)
//   ::GiveMoneySome(amount, filter)
//   ::GiveMoneyCT(amount, msg)
//   ::GiveMoneyT(amount, msg)

DoIncludeScript("vip/lib/chat.nut", null);
DoIncludeScript("vip/lib/players.nut", null);
DoIncludeScript("vip/lib/debug.nut", null);

if (!("_LOADED_MODULE_MONEY" in getroottable())) {
    ::_LOADED_MODULE_MONEY <- true;
    ::_money_fire <- function(amount, target, msg="", output="AddMoneyPlayer") {
        local eMoney = Entities.CreateByClassname("game_money");
        eMoney.__KeyValueFromString("AwardText", msg);
        eMoney.__KeyValueFromInt("Money", amount);
        EntFireByHandle(eMoney, output, "", 0.0, target, target);
        EntFireByHandle(eMoney, "Kill", "", 0.5, null, null);
    };

    ::GiveMoney <- function(amount, player) {
        Log("[Money] Giving "+amount+" to "+player);

        ::_money_fire(amount, player);
    }

    ::GiveMoneySome <- function(msg, filter) {
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player") {
                if (filter == null || filter(ent)) {
                    ::GiveMoney(msg, ent, delay);
                }
            }
            ent = Entities.Next(ent);
        }
    }

    ::GiveMoneyCT <- function(amount, msg) {
        Log("[Money] Giving "+amount+" to CTs");
        ::_money_fire(amount, null, msg, "AddTeamMoneyCT");
    }
    ::GiveMoneyT <- function(amount, msg, delay=0.0) {
        Log("[Money] Giving "+amount+" to Ts");
        ::_money_fire(amount, null, msg, "AddTeamMoneyTerrorist");
    }
}