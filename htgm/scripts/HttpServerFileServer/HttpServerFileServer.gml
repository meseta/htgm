/** A file server for loading files from gamemaker
 * @param {String} _web_root The file path that is the server root
 * @param {String} _index_file The name of the index file in the root
 */
function HttpServerFileServer(_web_root, _index_file="index.html") constructor {
	static max_age = 3600; // max age of cache
	
	/* @ignore */ self.__web_root = _web_root;
	/* @ignore */ self.__index_file = _index_file;
	
	// add trailing slash
	if (string_char_at(self.__web_root, string_length(self.__web_root)) != "/") {
		self.__web_root += "/";
	};
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.method != "GET") {
			throw new ExceptionHttpMethodNotAllowed()
			return;
		}
					
		var _file = self.__web_root + _context.request.get_parameter("*");
		if (file_exists(_file)) {
			_context.response.send_file(_file);
			return
		}
		
		// try to access folder with index
		if (string_char_at(_file, string_length(_file)) != "/") {
			_file += "/";
		}
		_file += self.__index_file;

		if (file_exists(_file)) {
			_context.set_should_cache(true);
			_context.response.send_file(_file);
			return
		}
		
		// if that didn't work, it's not found
		throw new ExceptionHttpNotFound($"{_context.request.path} not found");
	};
}
