// Handles giving money to players
// Exposes:
//   ::GiveMoney(amount, player, delay=0.0)
//   ::GiveMoneySome(amount, filter, delay=0.0)
//   ::GiveMoneyCT(amount, msg, delay=0.0)
//   ::GiveMoneyT(amount, msg, delay=0.0)

DoIncludeScript("vip/lib/chat.nut", null);
DoIncludeScript("vip/lib/players.nut", null);

if (!("_LOADED_MODULE_MONEY" in getroottable())) {
    ::_LOADED_MODULE_MONEY <- true;
    ::GiveMoney <- function(amount, player, delay=0.0) {
        printl("[Money] Giving "+amount+" to "+player);

        local eMoney = Entities.CreateByClassname("game_money");
        eMoney.__KeyValueFromString("AwardText", "" /* msg does not work currently :( */);
        eMoney.__KeyValueFromInt("Money", amount);
        EntFireByHandle(eMoney, "AddMoneyPlayer", "", delay, player, player);
    }

    ::GiveMoneySome <- function(msg, filter, delay=0.0) {
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
        printl("[Money] Giving "+amount+" to CTs");
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player") {
                if (ent.GetTeam() == TEAM_CT) {
                    ::GiveMoney(amount, ent);
                }
            }
            ent = Entities.Next(ent);
        }

        local dollarAmount = ::COLORS.lime_green + "+$" + amount;
        ::ChatMessageCT(" "+dollarAmount + ::COLORS.white + ": "+msg);
    }
    ::GiveMoneyT <- function(amount, msg, delay=0.0) {
        printl("[Money] Giving "+amount+" to Ts");
        local ent = Entities.First();
        while (ent != null) {
            if (ent.GetClassname() == "player") {
                if (ent.GetTeam() == TEAM_T) {
                    ::GiveMoney(amount, ent);
                }
            }
            ent = Entities.Next(ent);
        }
        
        local dollarAmount = ::COLORS.lime_green + "+$" + amount;
        ::ChatMessageT(" "+dollarAmount + ::COLORS.white + ": "+msg);
    }
}