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
	
	/** The render function for rendering this component, can be either string or Chain return
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 * @return {String|Struct.Chain}
	 */
	static render = function(_context) { return ""; };
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.method != "GET") {
			throw new ExceptionHttpMethodNotAllowed();
		}
		if (_context.request.get_header("hx-request") != "true" && _context.request.path != self.__redirect_path) {
			_context.logger.debug("Htmx Fetching without view, internal redirect", {request_path: _context.request.path, redirect_path: self.__redirect_path}, Logger.TYPE_HTTP);
			throw new ExceptionHttpServerInternalRedirect(self.__redirect_path);
		}
		
		var _rendered = self.render(_context);
		if (is_instanceof(_rendered, Chain)) {
			_rendered
				.chain_callback(method(_context, function(_payload) {
					response.send_html(_payload);
				}))
				.on_error(method(_context, function(_err) {
					response.send_exception(_err);	
				}));
		}
		else {
			_context.response.send_html(_rendered);
		}
	};
}