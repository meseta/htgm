/** Base constructor for an Htmx-powered View, which will only redirect if
 * the request isn't coming from HTMX. Also sets caching settings */
function HtmxView(): HttpServerRenderBase() constructor {
	static should_cache = undefined;
	
	/** Convenience function to return whether the incoming request was from 
	 * an HTMX hx-request
	 * @param {Struct.HttpServerRequestContext} _context
	 * @return {Bool}
	 */
	static is_hx_request = function(_context) {
		return	_context.request.get_header("hx-request") == "true";
	}
	
	/** Convenience function to do an HX-Redirect
	 * @param {Struct.HttpServerRequestContext} _context
	 * @return {Bool}
	 */
	static hx_redirect = function(_context, _path) {
		_context.response.set_header("HX-Redirect", _path);
	}
	
	/** Convenience function to do an HX-Replace-URL
	 * @param {Struct.HttpServerRequestContext} _context
	 * @return {Bool}
	 */
	static hx_replace_url = function(_context, _path) {
		_context.response.set_header("HX-Replace-Url", _path);
	}
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (is_string(self.no_session_redirect_path) && !_context.has_session()) {
			if (self.is_hx_request(_context)) {
				_context.response.set_header("HX-Replace-Url", self.no_session_redirect_path);
			}
			else {
				_context.response.set_header("HX-Location", self.no_session_redirect_path);
			}
			throw new ExceptionHttpServerInternalRedirect(self.no_session_redirect_path);
		}
		
		if (!self.is_hx_request(_context) && is_string(self.redirect_path) &&  _context.request.path != self.redirect_path) {
			_context.push_render_stack(method(self, self.render));
			throw new ExceptionHttpServerInternalRedirect(self.redirect_path);
		}
		
		if (!is_undefined(self.should_cache) && _context.request.path == _context.request.path_original) {
			_context.response.set_should_cache(self.should_cache);
		}
		
		_context.response.set_header("Vary", "HX-Request"); // prevent mixup of caching
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