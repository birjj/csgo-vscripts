/**
 * Implements the A* search algorithm for finding paths on the board
 */

::GeneratePath <- function(board, start, end) {
    // during execution each node is identified by the string "x-y", e.g. "2-5"
    // we maintain a map of those strings to _astar_node's
    local startNode = _astar_node(start, 0, _astar_estimator(start, end));
    startNode.open = true;
    local open = [startNode];
    local closed = [];
    local nodeMap = {};
    nodeMap[_astar_identifier(start)] <- startNode;

    while (open.len() > 0) {
        // find the node with the lowest forwards cost
        local current = { node=null, fcost=999, idx=-1 };
        foreach (idx,node in open) {
            if (node.forwardsCost < current.fcost) {
                current.node = node;
                current.fcost = node.forwardsCost;
                current.idx = idx;
            }
        }
        local curVec = current.node.vec;
        if (curVec.x == end.x && curVec.y == end.y) {
            // Log("[A*] Found path from "+_astar_identifier(start)+" to "+_astar_identifier(current.node.vec));
            return _astar_reconstructor(current.node);
        }

        open.remove(current.idx);
        current.node.closed = true;
        local neighbors = current.node.FindNeighbors(board, nodeMap, start, end);
        foreach (neighbor in neighbors) {
            if (neighbor.closed) { continue; }
            
            local neighborBackCost = current.node.backwardsCost + 1;
            if (!neighbor.open) {
                neighbor.open = true;
                open.push(neighbor);
            } else if (neighborBackCost >= neighbor.backwardsCost) {
                continue;
            }

            neighbor.previous = current.node;
            neighbor.backwardsCost = neighborBackCost;
            neighbor.forwardsCost = _astar_estimator(neighbor.vec, end);
        }
    }
    // Log("[A*] Couldn't find path from "+_astar_identifier(start)+" to "+_astar_identifier(end));
    return [];
};

::_astar_reconstructor <- function(node) {
    local path = [];
    while (node != null) {
        path.push(node.vec);
        node = node.previous;
    }
    return path;
}

::_astar_identifier <- function(vec) {
    return vec.x + "-" + vec.y;
};

::_astar_estimator <- function(start, end) {
    local dX = start.x - end.x;
    local dY = start.y - end.y;
    return abs(dX) + abs(dY);
};

class _astar_node {
    backwardsCost = 999; // cost from start to here
    forwardsCost = 999; // cost of getting from here to end
    previous = null;
    open = false;
    closed = false;

    vec = null;

    constructor(vect, backCost=999, forwCost=999) {
        this.vec = vect;
        this.backwardsCost = backCost;
        this.forwardsCost = forwCost;
    }

    /** Returns an array of neighbors */
    function FindNeighbors(board, nodeMap, start, end) {
        local outp = [];
        for (local x = -1; x < 2; x++) {
            for (local y = -1; y < 2; y++) {
                if (x == 0 && y == 0) { continue; }
                local targetVec = this.vec + Vector(x, y, 0);
                if (targetVec.x < 0 || targetVec.x >= 8 || targetVec.y < 0 || targetVec.y >= 8) { continue; }
                if (board[targetVec.x][targetVec.y] != null
                    && !(targetVec.x == start.x && targetVec.y == start.y)
                    && !(targetVec.x == end.x && targetVec.y == end.y)) {
                    Log("[A*] Found non-empty on-board square "+_astar_identifier(targetVec));
                    continue;
                }
                local identifier = _astar_identifier(targetVec);
                local node = null;
                if (identifier in nodeMap) {
                    node = nodeMap[identifier];
                } else {
                    node = _astar_node(targetVec);
                    nodeMap[identifier] <- node;
                }
                outp.push(node);
            }
        }
        return outp;
    }
}