/**
 * https://github.com/birjolaxew/csgo-vscripts
 * Lets you spawn stuff from a template and get the spawned entities.
 * Exposes:
 *   - SpawnTemplate(eTemplate, cb)
 */

::_template_awaiting <- {};

/** Spawns a specific template, and calls cb with a table of name=>ent (or null if spawning fails) */
::SpawnTemplate <- function(eTemplate, cb) {
    if (!eTemplate.ValidateScriptScope()) { cb(null); return; }
    local scope = eTemplate.GetScriptScope();
    // bind PostSpawn so we can get the entities after they're spawned
    if (!("_template_bound" in scope)) {
        scope._template_bound <- "template_id_"+UniqueString();
        ::_template_awaiting[scope._template_bound] <- [];

        // PreSpawnInstance must be called for PostSpawn to be called too
        if (!("PreSpawnInstance" in scope)) {
            scope.PreSpawnInstance <- function(entClass, entName) {};
        }

        // bind PostSpawn
        if ("PostSpawn" in scope) {
            scope._template_postspawn <- scope.PostSpawn;
        }
        scope.PostSpawn <- (function(ents) {
            PrintTable(ents);
            ::_template_postspawn(this._template_bound, ents);
        }).bindenv(scope);
    }

    ::_template_awaiting[scope._template_bound].push(cb);
    EntFireByHandle(eTemplate, "ForceSpawn", "", 0.0, null, null);
}

/** Called by PostSpawn of each individual template */
::_template_postspawn <- function(id, ents) {
    if (!(id in ::_template_awaiting)) {
        Warn("PostSpawn of unknown template "+id+" called; ignoring");
        return;
    }
    if (::_template_awaiting[id].len() > 0) {
        local target = _template_awaiting[id][0];
        ::remove_elm_from_array(_template_awaiting[id], target);
        target(ents);
    } else {
        Warn("PostSpawn of template "+id+" called without");
    }
    Log("Spawned entities for id "+id);

}