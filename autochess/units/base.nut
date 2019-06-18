DoIncludeScript("lib/debug.nut", null);

class BaseUnit {
    position = Vector(0, 0, 0);
    board = null;
    friendly = false;

    eModel = null;
    MODEL_NAME = "models/player/ctm_fbi.mdl";

    constructor(brd, isFriend) {
        this.board = brd;
        this.friendly = isFriend;

        this.eModel = CreateProp("prop_dynamic", Vector(0, 0, 0), this.MODEL_NAME, 0);
        this.eModel.SetAngles(0, 90, 0);
    }

    function Think() {
        Log("[BaseUnit] Am thinking");
    }

    function MoveToSquare(square) {
        this.position = square;
        this.eModel.SetOrigin(this.board.parentUI.GetPositionOfSquare(square) + Vector(0, 0, 32));
    }

    function Destroy() {
        if (this.eModel != null && this.eModel.IsValid()) {
            this.eModel.Destroy();
        }
    }
}