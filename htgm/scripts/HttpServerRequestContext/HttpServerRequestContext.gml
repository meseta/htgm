/** An HTTP request context that is passed to the handlers to view
 * @param {Struct.HttpRequest} _request The incoming request
 * @param {Struct.HttpResponse} _response The response going back out
 * @param {Struct.Logger} _logger logger to use
 */
function HttpServerRequestContext(_request, _response=undefined, _logger=undefined) constructor {
	self.request = _request;
	self.response = _response;
	
	_logger ??= LOGGER;
	self.logger = _logger.bind({request_time: HttpServer.rfc_date_now() });
	
	/* @ignore */ self.__render_stack = [];
	
	/** Checks if there is a render stack
	 * @return {Bool}
	 */
	static has_render_stack = function() {
		return array_length(self.__render_stack) > 0;
	};
	
	/** Gets the top-most 
	 * @return {Function}
	 */
	static pop_render_stack = function() {
		return array_pop(self.__render_stack);
	};
	
	/** Pushes a renderer to the stack
	 * @param {Function} _render Render function to push
	 */
	static push_render_stack = function(_render) {
		array_push(self.__render_stack, _render);
	};
}
