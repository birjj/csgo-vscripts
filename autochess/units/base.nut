class BaseUnit {
    position = Vector(0, 0, 0);
    board = null;

    eModel = null;
    MODEL_NAME = "models/player/ctm_fbi.mdl";

    constructor(brd) {
        this.board = brd;

        this.eModel = CreateProp("prop_dynamic", Vector(0, 0, 0), this.MODEL_NAME, 0);
    }

    function MoveToSquare(square) {
        this.position = square;
        this.eModel.SetOrigin(this.board.GetPositionOfSquare(square) + Vector(0, 0, 32));
    }
}