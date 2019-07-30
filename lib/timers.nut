DoIncludeScript("lib/debug.nut",null);

::CallNextFrame <- function(cb) {
    TimerHandler(0, cb, true);
}

class TimerHandler {
    uid = null;
    cb = null;
    eTimer = null;
    once = false;

    constructor(frequency, callback, once=false) {
        this.uid = UniqueString("-timer");
        this.cb = callback;
        this.once = once;
        ::_timer_handler_map[this.uid] <- this;

        this.eTimer = Entities.CreateByClassname("logic_timer");
        EntFireByHandle(this.eTimer, "RefireTime", frequency.tostring(), 0.0, null, null);
        EntFireByHandle(this.eTimer, "AddOutput", "OnTimer !self:RunScriptCode:_timer_callback(\""+this.uid+"\"):0:-1", 0.0, null, null);
        EntFireByHandle(this.eTimer, "Enable", "", 0.0, null, null);
    }

    function Trigger() {
        this.cb();
        if (this.once) {
            this.Destroy();
        }
    }

    function Destroy() {
        if (this.eTimer != null && this.eTimer.IsValid()) {
            this.eTimer.Destroy();
        }
        this.cb = null;
        delete ::_timer_handler_map[this.uid];
    }
}

::_timer_handler_map <- {};

::_timer_callback <- function(uid) {
    if (uid in _timer_handler_map) {
        _timer_handler_map[uid].Trigger();
    } else {
        Log("[Animation] Timer fired for unknown timer "+uid);
    }
}