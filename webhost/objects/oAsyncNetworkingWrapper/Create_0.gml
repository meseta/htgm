// This object exists solely to be spawned by add_async_networking_callback
// Do not spawn this object by hand

callback = undefined;

/** Sets a callback to the handler to respond to network events
 * @param {Function} _callback A callback to add
 * @self
 */
set_callback = function(_callback) {
	callback = _callback;
}