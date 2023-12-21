/** Base constructor for a View, which includes a redirect if the request isn't an htmx request */
function HtmxView(): HttpServerRenderBase() constructor {
	static redirect_path = "";
	
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
		if (_context.request.get_header("hx-request") != "true" && _context.request.path != self.redirect_path) {
			_context.logger.debug("Htmx Fetching without view, internal redirect", {request_path: _context.request.path, redirect_path: self.redirect_path});
			_context.request.push_render_stack(method(self, self.render));
			throw new ExceptionHttpServerInternalRedirect(self.redirect_path);
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