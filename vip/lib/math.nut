// Trace in a direction, returning the point where the line hits terrain
::TraceInDirection <- function(start, direction, ignore = null) {
    direction.Norm();
    local end = start + (direction * 5000);
    local progress = TraceLine(start, end, ignore);
    return start + (end - start) * progress;
}