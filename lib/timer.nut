DoIncludeScript("lib/debug.nut",null);

if (!("_LOADED_MODULE_TIMER" in getroottable())) {
    ::_LOADED_MODULE_TIMER <- true;
    ::_timer_cbs <- [];

    ::_timer_Think <- function() {
        local timers = ::_timer_cbs; // we store this here so that a failing cb won't stop us from wiping the timer array
        ::_timer_cbs = [];
        foreach(cb in timers) {
            cb();
        }
    }

    ::CallNextFrame <- function(cb) {
        ::_timer_cbs.push(cb);
    }
}