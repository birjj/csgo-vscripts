// https://github.com/birjolaxew/csgo-vscripts
// Stuff that should've been in the language
// Keep in mind that the version of Squirrel that comes with CS:GO is 2.2, so it's a bit old

/**
 * Returns the index of an element in an array
 * Returns null if not found
 */
::find_in_array <- function(arr, elm) {
    for (local i = 0; i < arr.len(); i++) {
        if (arr[i] == elm) { return i; }
    }
    return null;
};

/**
 * Removes an element from an array. Only returns one instance
 * Returns null if not found, returns the element if is found
 */
::remove_elm_from_array <- function(arr, elm) {
    local idx = find_in_array(arr, elm);
    if (idx == null) { return null; }
    arr.remove(idx);
    return elm;
};

/**
 * Returns a copy of an array with only the elements that match a specific filter
 */
::filter_array <- function(arr, filter) {
    local outp = [];
    foreach (elm in arr) {
        if (filter(elm)) { outp.push(elm); }
    }
    return outp;
}