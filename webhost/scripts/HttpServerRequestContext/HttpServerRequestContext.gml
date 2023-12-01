/** An HTTP request context that is passed to the handlers to view
 * @param {Struct.HttpRequest} _request The incoming request
 * @param {Struct.HttpResponse} _response The response going back out
 * @param {Struct.Logger} _logger logger to use
 */
function HttpServerRequestContext(_request, _response, _logger) constructor {
	self.request = _request;
	self.response = _response;
	self.logger = _logger.bind({request_time: HttpResponse.__rfc_date_now() });
}
