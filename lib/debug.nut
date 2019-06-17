::IsDebug <- function() {
    return true;
    return GetDeveloperLevel() > 0;
}

::Log <- function(msg) {
    if (IsDebug()) {
        printl(msg);
    }
}

::PrintTable <- function(tbl, indent="", printfunc=::Log) {
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

::DrawBox <- function(origin, size=Vector(16,16,16), color=Vector(255,0,0), duration=5) {
    DebugDrawBox(
        origin,
        size * -0.5,
        size * 0.5,
        color.x,
        color.y,
        color.z,
        0,
        duration
    );
}

::DrawLine <- function(start, end, color=Vector(255,0,0), duration=5) {
    DebugDrawLine(
        start,
        end,
        color.x,
        color.y,
        color.z,
        true,
        duration
    );
}