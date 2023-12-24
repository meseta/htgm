/** An incoming client session for the HTTP server
 * @param {Id.Socket} _client_socket The client's socket
 * @param {Struct.HttpServerRouter} _router The router that serves the paths
 * @param {Struct.Logger} _logger An optional logger to use. if not provided, one will be created
 */
function HttpServerSession(_client_socket, _router, _logger) constructor {
	/* @ignore */ self.__client_socket = _client_socket;
	/* @ignore */ self.__router = _router;
	/* @ignore */ self.__logger = _logger;
	
	/* @ignore */ self.__closed = false;
	
	/* @ignore */ self.__line_buffer = new HttpServerLineBuffer();
	/* @ignore */ self.__fsm = new SnowState("request");
	
	self.request = undefined;
	self.response = undefined;
	self.upgrade = undefined;

	self.__fsm.add("request", {
		handle_data: function(_line_buffer) {
			// read first line of request
			var _str = _line_buffer.read_line();
			
			if (is_undefined(_str) || _str == "") {
				self.__logger.warning("Not HTTP session, closing");
				self.close();
				return;
			}
			
			var _tokens = string_split(_str, " ");
			if (array_length(_tokens) < 3) {
				self.__logger.warning("Malformed HTTP request, closing", {tokens: _tokens, line: _str});
				self.close();
				return;
			}
			
			if (_tokens[2] != "HTTP/1.1") {
				self.__logger.warning("Unsupported HTTP request, closing", {tokens: _tokens, line: _str});
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
				self.__logger.debug("Got headers", {headers: self.request.headers})
				if (self.request.get_header("connection") == "Upgrade") {
					var _upgrade = self.request.get_header("upgrade");
					if (_upgrade == "websocket") {
						self.__fsm.change("upgrade");
					}
					else {
						self.__logger.warning("Unsupported Upgrade, closing", {upgrade: _upgrade});
						self.close();	
					}
				}
				else {
					if (self.request.get_header("connection") == "close") {
						self.request.keep_alive = false;
					}
					
					if (self.request.has_header("content-length") && self.request.get_header("content-length") != "0") {
						self.__fsm.change("data");
					}
					else {
						self.__fsm.change("dispatch");
					}
				}
				return;
			}
			
			var _tokens = string_split(_str, ": ");
			if (array_length(_tokens) < 2) {
				self.__logger.warning("Malformed header request, closing", {tokens: _tokens, line: _str});
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
			
			self.__logger.info("Received request", {method: self.request.method, path: self.request.path});
			var _header_only = (self.request.method == "HEAD" or self.request.method == "OPTIONS")
			
			// check accept encodings
			var _compression = "";
			if (!_header_only) {
				var _encodings = array_map(string_split(self.request.get_header("accept-encoding") ?? "", ","), function(_encoding) { return string_trim(_encoding); });
				if (array_contains(_encodings, "deflate")) {
					_compression = "deflate";
				}
				else if (array_contains(_encodings, "gzip")) {
					_compression = "gzip";	
				}
			}
			
			self.response = new HttpResponse(function() { self.__fsm.change("response")}, _header_only, _compression);
			
			try {
				self.__router.process_request(self.request, self.response);
			}
			catch (_err) {
				if (is_instanceof(_err, ExceptionHttpBase)) {
					self.__logger.exception(_err, undefined, Logger.INFO);
					self.response.send_string(_err.long_message, _err.http_code);
				}
				else {
					self.__logger.exception(_err, undefined, Logger.ERROR);
					self.response.send_string(HttpServer.status_code_to_string(500), 500);
				}
			}
		}
	});
	self.__fsm.add("response", {
		enter: function() {
			if (!self.request.keep_alive) {
				self.response.set_header("Connection", "close");
			}
			if (!self.response.get_should_cache()) {
				self.response.set_header("Cache-Control", self.__router.get_default_cache_control());
			}
			
			var _buffer = self.response.get_send_buffer();
			var _size =  self.response.get_send_size();
			
			network_send_raw(self.__client_socket, _buffer, _size);
				
			self.__logger.debug("Sent response", {response_code: self.response.status_code, size: _size});
			self.__fsm.change("cleanup");
		}
	});
	self.__fsm.add("cleanup", {
		enter: function() {
			var _keepalive = self.request.keep_alive;
			if (is_struct(self.request)) {
				self.request.cleanup();
				self.request = undefined;
			}
			if (is_struct(self.response)) {
				self.response.cleanup();
				self.response = undefined;
			}
				
			if (_keepalive) {
				self.__fsm.change("request");
			}
			else {
				self.close();
				self.__fsm.change("finished");
			}
		}
	});
	self.__fsm.add("upgrade", {
		enter: function() {
			// force keep_alive to false, so that when we cycle to `cleanup` we close properly
			// rather than try to accept the next request
			self.request.keep_alive = false;
			
			if (self.request.has_header("sec-websocket-key")) {
				// handle accept, implement the websocket Accept handshake
				var _key = self.request.get_header("sec-websocket-key");
				var _hash = sha1_string_utf8(_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");	

				var _buff = buffer_create(20, buffer_fixed, 1);
				for(var _i=0; _i<40; _i+=2) {
					var _nibble_low = string_byte_at(_hash, _i+2) - 0x30;
					if(_nibble_low > 16) { // it's in the alpha range
						_nibble_low -= 39 // bring it back down
					}
					var _nibble_high = string_byte_at(_hash, _i+1) - 0x30;
					if(_nibble_high > 16) { // it's in the alpha range
						_nibble_high -= 39 // bring it back down
					}
					buffer_write(_buff, buffer_u8, _nibble_low | _nibble_high << 4);
				}
				var _accept = buffer_base64_encode(_buff, 0, 20);
				buffer_delete(_buff);
			
				var _switch_protocol_response = "HTTP/1.1 101 Switching Protocols\r\n" +
										"Upgrade: websocket\r\n" +
										"Connection: Upgrade\r\n" +
										"Sec-WebSocket-Accept: " + _accept + "\r\n" +
										"\r\n";
				var _len = string_byte_length(_switch_protocol_response);
				var _response_buff = buffer_create(_len, buffer_fixed, 1);
				buffer_write(_response_buff, buffer_text, _switch_protocol_response);
				network_send_raw(self.__client_socket, _response_buff, _len);
				buffer_delete(_response_buff);
	
				self.__fsm.change("websocket")
			}
			else {
				self.__logger.debug("No sec-websocket-key presented for upgrade, closing", undefined);
				self.__fsm.change("cleanup");
			}
		},
	});
	self.__fsm.add("websocket", {
		enter: function() {
			self.__logger.info("Received websocket request", {method: self.request.method, path: self.request.path});
			
			var _session_handler = undefined;
			try {
				_session_handler = self.__router.process_websocket(self.request);
			}
			catch (_err) {
				self.__logger.exception(_err);
				self.__fsm.change("cleanup");
				return;
			}
			
			if (is_undefined(_session_handler)) {
				self.__logger.debug("Websocket handler not found for path");
				self.__fsm.change("cleanup");
			}
			else {
				self.upgrade = new HttpServerWebsocket(self.__client_socket, _session_handler, self.__logger);	
			}
		},
		handle_data: function(_line_buffer) {
			self.upgrade.handle_data(_line_buffer);
			if (self.upgrade.is_closed()) {
				self.__fsm.change("cleanup");
			}
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
		var _tell = -1;
		while(self.__closed == false && self.__line_buffer.has_data() && _tell != self.__line_buffer.tell()) {
			_tell = self.__line_buffer.tell();
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
		if (is_struct(self.upgrade)) {
			self.upgrade.cleanup();
		}
		
		self.__line_buffer.cleanup();
	
		if (self.__client_socket != -1) {
			network_destroy(self.__client_socket);
			self.__client_socket = -1;
			self.__logger.debug("Client closed", {socket_id: self.__client_socket})  
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
