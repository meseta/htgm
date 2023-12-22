/** Exception for HttpServer during setup
 * @param {String} _message The exception message
 * @param {String} _long_message A longer message
 */
function ExceptionHttpServerSetup(_message, _long_message=undefined): Exception(_message, _long_message) constructor {}

/** An exception that can be thrown to cause an internal redirect
 * @param {String} _path The new path to redirect to
 */
function ExceptionHttpServerInternalRedirect(_path) constructor {
	self.path = _path;
}
