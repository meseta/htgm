/** Base constructor for a Render, that will dynamically render content */
function HttpServerRenderBase() constructor {
	static path = undefined;
	static paths = undefined;
	
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
		_context.response.send_html(self.render(_context));
	};
}
