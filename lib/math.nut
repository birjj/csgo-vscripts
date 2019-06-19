// Trace in a direction, returning the point where the line hits terrain
::TraceInDirection <- function(start, direction, ignore = null) {
    direction.Norm();
    local end = start + (direction * 10000);
    local progress = TraceLine(start, end, ignore);
    return start + (end - start) * progress;
}

/** Returns the angle an entity should have when at "from" to point towards "to" */
::AngleBetweenPoints <- function(from, to) {
    // TODO: extend to support Z axis
    local dX = to.x - from.x;
    local dY = to.y - from.y;
    local rads = atan2(dY, dX);
    local degrees = (rads * 180) / PI;
    return Vector(0, degrees, 0);
}