DoIncludeScript("lib/debug.nut",null);

class TimerHandler {
    uid = null;
    cb = null;
    eTimer = null;

    constructor(frequency, callback) {
        this.uid = UniqueString("-timer");
        this.cb = callback;
        ::_timer_handler_map[this.uid] <- this;

        this.eTimer = Entities.CreateByClassname("logic_timer");
        EntFireByHandle(this.eTimer, "RefireTime", "0.05", 0.0, null, null);
        EntFireByHandle(this.eTimer, "AddOutput", "OnTimer !self:RunScriptCode:_timer_callback(\""+this.uid+"\"):0:-1", 0.0, null, null);
        EntFireByHandle(this.eTimer, "Enable", "", 0.0, null, null);
    }

    function Trigger() {
        this.cb();
    }

    function Destroy() {
        if (this.eTimer != null && this.eTimer.IsValid()) {
            this.eTimer.Destroy();
        }
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