/** Base constructor for a Render, that will dynamically render content */
function HttpServerRenderBase() constructor {
	static path = undefined;
	static paths = undefined;
		
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
	
	/** The render function for rendering this component
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 * @return {String}
	 */
	static render = function(_context) { return ""; };

	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.method != "GET") {
			throw new ExceptionHttpMethodNotAllowed()
			return;
		}
		
		var _rendered = self.render(_context);
		if (is_instanceof(_rendered, Chain)) {
			_rendered
				.chain_callback(method(_context, function(_payload) {
					response.send_html(_payload);
				}))
				.on_error(method(_context, function(_err) {
					logger.warning("Got error handling request", {err: _err});
					response.send_exception(_err);	
				}));
		}
		else {
			_context.response.send_html(_rendered);
		}
	};
}
