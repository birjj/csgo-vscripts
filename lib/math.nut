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

/** Returns the normal vector of a point that is on a surface. Note that this is pretty expensive.
 * The point *must* be 1 unit offset away from the wall - otherwise you might get the inverse normal.
 * Precision indicates how precise we should be. 0 means round to 90 degrees, 1 to 45 degrees, 2 to 22.5 degrees, etc. */
const NORMAL_CHECK_LEN = 4;
const NORMAL_OFFSET_DIST = 0.5; // prolly should be <= 0.5, but higher = better precision
::NormalOfSurface <- function(point, precision=0) {
    local min = { dir = null, len = 999 };
    // check the 6 base directions first
    local count = 0;
    foreach (dir in [Vector(0, 0, 1), Vector(0, 0, -1), Vector(0, 1, 0), Vector(0, -1, 0), Vector(1, 0, 0), Vector(-1, 0, 0)]) {
        local start = point;
        local end = point + (dir * NORMAL_CHECK_LEN);
        local len = TraceLine(start, end, null);
        if (len < min.len) {
            min.dir = dir;
            min.len = len;
        }
    }

    // we want to find 3 points on the surface so we can generate a formula for the plane
    // we just move our direction vector a bit and hope that works ¯\_(ツ)_/¯
    // better solution would be to implement vector rotation or spherical coordinates, but I'm lazy
    local dir1 = null;
    local dir2 = null;
    if (min.dir.y == 0 && min.dir.z == 0) {
        dir1 = min.dir + Vector(-min.dir.x * NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST);
        dir2 = min.dir + Vector(-min.dir.x * NORMAL_OFFSET_DIST, -NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST);
    } else if (min.dir.x == 0 && min.dir.z == 0) {
        dir1 = min.dir + Vector(NORMAL_OFFSET_DIST, -min.dir.y * NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST);
        dir2 = min.dir + Vector(-NORMAL_OFFSET_DIST, -min.dir.y * NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST);
    } else {
        dir1 = min.dir + Vector(NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST, -min.dir.z * NORMAL_OFFSET_DIST);
        dir2 = min.dir + Vector(-NORMAL_OFFSET_DIST, NORMAL_OFFSET_DIST, -min.dir.z * NORMAL_OFFSET_DIST);
    }
    local dir3 = min.dir;
    dir1.Norm(); dir2.Norm(); dir3.Norm();
    local point1 = point + dir1 * TraceLine(point, point + dir1 * NORMAL_CHECK_LEN, null);
    local point2 = point + dir2 * TraceLine(point, point + dir2 * NORMAL_CHECK_LEN, null);
    local point3 = point + dir3 * TraceLine(point, point + dir3 * NORMAL_CHECK_LEN, null);

    local vec1 = point3 - point1;
    local vec2 = point3 - point2;
    local normal = vec1.Cross(vec2);
    normal.Norm();

    // we might've gotten the normal that points into the surface - inverse it if so
    if ((min.dir - normal).LengthSqr() < (min.dir + normal).LengthSqr()) {
        normal *= -1;
    }

    return normal;
}

/** Gets the reflection of a (normalized) vector, given the normal of the surface */
::GetReflection <- function(vec, normal) {
    return (
        (normal * (2 * normal.Dot(vec))) - vec
    ) * -1; // TODO: figure out why we gotta * -1. I do not have the smahts :(
};

/** Turns direction vectors into a relative vector that can then be applied to another vector later */
::GetRelativeVector <- function(baseVec, otherVec, debugPos=null) {
    // first we generate the two axis' needed to define the other vec in relative spherical coordinates
    local tmpVec = Vector(0, 0, 1);
    if (baseVec.x == 0 && baseVec.y == 0) {
        tmpVec = Vector(1, 0, 0);
    }
    local xVec = baseVec.Cross(tmpVec);
    local yVec = baseVec.Cross(xVec);
    local zVec = Vector(baseVec.x, baseVec.y, baseVec.z);
    xVec.Norm();
    yVec.Norm();
    zVec.Norm();

    if (debugPos) {
        DrawLine(debugPos, debugPos + xVec * 16, Vector(255, 0, 0), 5.0);
        DrawLine(debugPos, debugPos + yVec * 16, Vector(0, 255, 0), 5.0);
        DrawLine(debugPos, debugPos + zVec * 16, Vector(0, 0, 255), 5.0);
    }

    // then calculate the x/y/height components
    local x = otherVec.Dot(xVec);
    local y = otherVec.Dot(yVec);
    local z = otherVec.Dot(zVec);

    if (debugPos) {
        DrawLine(debugPos, debugPos + otherVec * 16, Vector(255, 0, 255), 5.0);
        DrawLine(debugPos, debugPos + Vector(x, y, z) * 16, Vector(255, 255, 0), 5.0);
    }

    return Vector(x, y, z);
};

/** Applies a relative vector (from ::CreateRelativeVector) to another vector */
::ApplyRelativeVector <- function(baseVec, relativeVec, debugPos=null) {
    // first we generate the two axis' needed to define the other vec in relative cylindrical coordinates
    local tmpVec = Vector(0, 0, 1);
    if (baseVec.x == 0 && baseVec.y == 0) {
        tmpVec = Vector(1, 0, 0);
    }
    local xVec = baseVec.Cross(tmpVec);
    local yVec = baseVec.Cross(xVec);
    local zVec = Vector(baseVec.x, baseVec.y, baseVec.z);
    xVec.Norm();
    yVec.Norm();
    zVec.Norm();

    if (debugPos) {
        DrawLine(debugPos, debugPos + xVec * 16, Vector(255, 0, 0), 5.0);
        DrawLine(debugPos, debugPos + yVec * 16, Vector(0, 255, 0), 5.0);
        DrawLine(debugPos, debugPos + zVec * 16, Vector(0, 0, 255), 5.0);
    }

    // then apply the x/y/height components
    local outp = Vector(0,0,0) + (xVec * relativeVec.x) + (yVec * relativeVec.y) + (zVec * relativeVec.z);

    if (debugPos) {
        DrawLine(debugPos, debugPos + outp * 16, Vector(255, 255, 0), 5.0);
    }

    return outp;
}