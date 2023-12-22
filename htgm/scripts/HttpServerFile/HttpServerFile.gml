/** Serve a single file
 * @param {String} _file The file path that will be served
 */
function HttpServerFile(_file) constructor {
	/* @ignore */ self.__file = _file;
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.method != "GET") {
			throw new ExceptionHttpMethodNotAllowed()
			return;
		}

		if (file_exists(self.__file)) {
			_context.response.send_file(self.__file);
			return
		}
		
		// if that didn't work, it's not found
		_context.logger.warning("HttpServerFile file not found", {file: self.__file});
		throw new ExceptionHttpNotFound($"{_context.request.path} not found");
	};
}
