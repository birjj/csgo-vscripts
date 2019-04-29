::IsDebug <- function() {
    return GetDeveloperLevel() > 0;
}

::PrintTable <- function(tbl, indent="", printfunc=::log) {
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

::Log <- function(msg) {
    if (IsDebug()) {
        printl(msg);
    }
}