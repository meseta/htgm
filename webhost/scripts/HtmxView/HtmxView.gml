/** Base constructor for a View, which includes a redirect if the request isn't an htmx request
 * @param {String} _redirect_path The path to redirect to if the request isn't an Htmx request
 */
function HtmxView(_redirect_path=""): HttpServerRenderBase() constructor {
	/* @ignore */ self.__redirect_path = _redirect_path;
	
	/** Generate a path based on the struct instance automatically
	 * @param {String} _path_prefix Custom path prefix
	 */
	static auto_path = function(_path_prefix="render") {
		return $"{_path_prefix}/{instanceof(self)}";
	}
	
	/** Generate an ID based on the struct instance automatically
	 * @param {String} _id_prefix Custom ID prefix
	 */
	static auto_id = function(_id_prefix) {
		return $"{_id_prefix}-{instanceof(self)}";
	}
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.method != "GET") {
			throw new ExceptionHttpMethodNotAllowed();
		}
		if (_context.request.get_header("hx-request") != "true" && _context.request.path != self.__redirect_path) {
			_context.logger.debug("Htmx Fetching without view, internal redirect", {request_path: _context.request.path, redirect_path: self.__redirect_path}, LOG_TYPE_HTTP);
			throw new ExceptionHttpServerInternalRedirect(self.__redirect_path);
		}
		
		var _rendered = is_method(self.render) ? self.render(_context) : self.render;
		_context.response.send_html(_rendered);
	};
}