::printtable <- function(tbl, indent="") {
    if (tbl == null) {
        printl("null");
        return;
    }
    printl(indent + "table {");
    foreach (key,val in tbl) {
        local v = val;
        if (val == null) {
            v = "null";
        } else {
            v = val.tostring();
        }
        printl(indent + "  "+key+": "+v);
    }
    printl(indent + "}");
}