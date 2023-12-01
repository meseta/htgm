/** An incoming client session for the HTTP server
 * @param {Id.Socket} _client_socket The client's socket
 * @param {Struct.HttpServerRouter} _router The router that serves the paths
 * @param {Struct.Logger} _logger An optional logger to use. if not provided, one will be created
 */
function HttpServerSession(_client_socket, _router, _logger) constructor {
	// An HTTP connection session state machine, using SnowState to provide state machine
	
	/* @ignore */ self.__client_socket = _client_socket;
	/* @ignore */ self.__router = _router;
	/* @ignore */ self.__logger = _logger;
	
	/* @ignore */ self.__closed = false;
	
	/* @ignore */ self.__line_buffer = new HttpServerLineBuffer();

	self.request = undefined;
	self.response = undefined;

	/* @ignore */ self.__fsm = new SnowState("request");
	self.__fsm.add("request", {
		handle_data: function(_line_buffer) {
			// read first line of request
			var _str = _line_buffer.read_line();
			
			if (is_undefined(_str) || _str == "") {
				self.__logger.warning("Not HTTP session, closing", undefined, LOG_TYPE_HTTP);
				self.close();
				return;
			}
			
			var _tokens = string_split(_str, " ");
			if (array_length(_tokens) < 3) {
				self.__logger.warning("Malformed HTTP request, closing", {tokens: _tokens, line: _str}, LOG_TYPE_HTTP);
				self.close();
				return;
			}
			
			if (_tokens[2] != "HTTP/1.1") {
				self.__logger.warning("Unsupported HTTP request, closing", {tokens: _tokens, line: _str}, LOG_TYPE_HTTP);
				self.close();
				return;
			}
			
			var _method = _tokens[0];
			var _path = _tokens[1];
			
			// trim first slash
			if (string_char_at(_path, 1) == "/") {
				_path = string_delete(_path, 1, 1);
			}
			
			self.request = new HttpRequest(_method, _path);
			
			self.__fsm.change("headers");
		}
	});
	self.__fsm.add("headers", {
		handle_data: function(_line_buffer) {
			// read a header
			var _str = _line_buffer.read_line();
			
			if (is_undefined(_str)) return;
			
			if (_str == "") {
				// empty line means end of headers
				if (self.request.has_header("content-length") && self.request.get_header("content-length") != "0") {
					self.__fsm.change("data");
				}
				else {
					self.__fsm.change("dispatch");
				}
				return;
			}
			
			var _tokens = string_split(_str, ": ");
			if (array_length(_tokens) < 2) {
				self.__logger.warning("Malformed header request, closing", {tokens: _tokens, line: _str}, LOG_TYPE_HTTP);
				self.close();
				return;
			}
			
			self.request.set_header(_tokens[0], _tokens[1]);
		}
	});
	self.__fsm.add("data", {
		handle_data: function(_line_buffer) {
			var _buffer = _line_buffer.read_length_to_buffer(real(self.request.get_header("content-length")));
			if (buffer_exists(_buffer)) {
				self.request.set_data(_buffer);
				self.__fsm.change("dispatch");	
			}
		}
	});
	self.__fsm.add("dispatch", {
		enter: function() {
			self.__logger.info("Received request", {method: self.request.method, path: self.request.path}, LOG_TYPE_HTTP);
			var _header_only = (self.request.method == "HEAD" or self.request.method == "OPTIONS")
			
			// check accept encodings
			var _compress = false;
			if (!_header_only) {
				var _encodings = string_split(self.request.get_header("accept-encoding") ?? "", ",");
				var _compression_idx = array_find_index(_encodings, function(_encoding) {
					return string_trim(_encoding) == "deflate";
				})
				if (_compression_idx >= 0) {
					_compress = true;
				}
			}
			
			self.response = new HttpResponse(function() { self.__fsm.change("response")}, _header_only, _compress);
			
			try {
				self.__router.process_request(self.request, self.response);
			}
			catch (_err) {
				if (is_instanceof(_err, ExceptionHttpBase)) {
					self.__logger.exception(_err, undefined, LOG_INFO, LOG_TYPE_HTTP);
					self.response.send_string(_err.long_message, _err.http_code);
				}
				else {
					self.__logger.exception(_err, undefined, LOG_ERROR, LOG_TYPE_HTTP);
					self.response.send_string(HttpServer.status_code_to_string(500), 500);
				}
			}
		}
	});
	self.__fsm.add("response", {
		enter: function() {
			var _buffer = self.response.get_send_buffer();
			var _size =  self.response.get_send_size();
			
			network_send_raw(self.__client_socket, _buffer, _size);
				
			self.__logger.debug("Sent response", {response_code: self.response.status_code, size: _size}, LOG_TYPE_HTTP);
			self.response.cleanup();
			self.response = undefined;
			self.request.cleanup();
			self.request = undefined;

			self.close();
			self.__fsm.change("finished");
		}
	});
	self.__fsm.add("finished", {
		handle_data: function() { return; }
	});
	
	/** Handle received data
	 * @param {Id.Buffer} _incoming_buffer existing buffer to use
	 * @param {Real} _incoming_size bytes incoming
	 */
	static handle_data = function(_incoming_buffer, _incoming_size) {
		self.__line_buffer.concatenate(_incoming_buffer, _incoming_size);
		while(self.__closed == false && self.__line_buffer.has_data()) {
			self.__fsm.handle_data(self.__line_buffer);
		}
	};
	
	/** Close the client connection
	 */
	static close = function() {
		if (is_struct(self.request)) {
			self.request.cleanup();
		}
		if (is_struct(self.response)) {
			self.response.cleanup();
		}
		
		self.__line_buffer.cleanup();
	
		if (self.__client_socket != -1) {
			network_destroy(self.__client_socket);
			self.__client_socket = -1;
			self.__logger.debug("Client closed", {socket_id: self.__client_socket}, LOG_TYPE_HTTP)  
		}
		self.__closed = true;
	};
	
	/** Whether the client is closed
	 * @return {Bool}
	 */
	static is_closed = function() {
		return self.__closed;
	};
}