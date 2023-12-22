/** Base exception for all returnable HTTP Server exceptions
 * @param {String} _long_message A longer message
 * @param {Real} _http_code the HTTP server code
 */
function ExceptionHttpBase(_long_message=undefined, _http_code=500): Exception("", _long_message) constructor {
	self.http_code = _http_code;
	self.message = HttpServer.status_code_to_string(_http_code);
}

/** A server error that returns a 500 status code
 * @param {String} _long_message The error message
 */
function ExceptionHttpInternal(_long_message=undefined): ExceptionHttpBase(_long_message, 500) constructor {};

/** A server error that returns a 405 status code
 * @param {String} _long_message The error message
 */
function ExceptionHttpMethodNotAllowed(_long_message=undefined): ExceptionHttpBase(_long_message, 405) constructor {};

/** A server error that returns a 404 status code
 * @param {String} _long_message The error message
 */
function ExceptionHttpNotFound(_long_message=undefined): ExceptionHttpBase(_long_message, 404) constructor {};

/** A server error that returns a 403 status code
 * @param {String} _long_message The error message
 */
function ExceptionHttpForbidden(_long_message=undefined): ExceptionHttpBase(_long_message, 403) constructor {};

/** A server error that returns a 401 status code
 * @param {String} _long_message The error message
 */
function ExceptionHttpUnauthorized(_long_message=undefined): ExceptionHttpBase(_long_message, 401) constructor {};

/** A server error that returns a 400 status code
 * @param {String} _long_message The error message
 */
function ExceptionHttpBadRequest(_long_message=undefined): ExceptionHttpBase(_long_message, 400) constructor {};

