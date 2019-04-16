::printtable <- function(tbl, indent="", printfunc=::log) {
    if (tbl == null) {
        printfunc("null");
        return;
    }
    printfunc(indent + "table {");
    foreach (key,val in tbl) {
        local v = val;
        if (val == null) {
            v = "null";
        } else {
            v = val.tostring();
        }
        printfunc(indent + "  "+key+": "+v);
    }
    printfunc(indent + "}");
}

::log <- function(msg) {
    if (GetDeveloperLevel() > 0) {
        printl(msg);
    }
}