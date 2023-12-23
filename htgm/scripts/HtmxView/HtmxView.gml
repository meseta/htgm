/** Base constructor for an Htmx-powered View, which will only redirect if
 * the request isn't coming from HTMX. Also sets caching settings */
function HtmxView(): HttpServerRenderBase() constructor {
	static should_cache = undefined;
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.get_header("hx-request") != "true" && is_string(self.redirect_path) &&  _context.request.path != self.redirect_path) {
			_context.push_render_stack(method(self, self.render));
			throw new ExceptionHttpServerInternalRedirect(self.redirect_path);
		}
		
		if (!is_undefined(self.should_cache) && _context.request.path == _context.request.path_original) {
			_context.response.set_should_cache(self.should_cache);
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