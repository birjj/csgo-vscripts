// https://github.com/birjolaxew/csgo-vscripts
// Handles gathering all the stuff that should be precached
// Note that you *must* call PerformPrecache(self) in your main script's Precache()
// Exposes:
// - RegisterPrecacheModel(str)
// - RegisterPrecacheSound(str)
// - PerformPrecache()

DoIncludeScript("lib/debug.nut", null);

if (!("_LOADED_MODULE_CURSORS" in getroottable())) {
    ::_precache_models <- [];
    ::_precache_sounds <- [];
}

::RegisterPrecacheModel <- function(model) {
    ::_precache_models.push(model);
}

::RegisterPrecacheSound <- function(sound) {
    ::_precache_sounds.push(sound);
}

function PerformPrecache(target) {
    foreach (model in ::_precache_models) {
        target.PrecacheModel(model);
    }
    foreach (sound in ::_precache_sounds) {
        target.PrecacheSoundScript(sound);
    }
}