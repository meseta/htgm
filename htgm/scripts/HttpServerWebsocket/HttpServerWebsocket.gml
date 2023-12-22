/** Websocket handler
 * @param {Id.Socket} _client_socket The client's socket
 * @param {Struct.HttpServerWebsocketSessionBase} _session_handler The session handler to use
 * @param {Struct.Logger} _logger the Logger to use
 */
function HttpServerWebsocket(_client_socket, _session_handler, _logger) constructor {
	//  session state machine, using SnowState to provide state machine
	
	/* @ignore */ self.__client_socket = _client_socket;
	/* @ignore */ self.__session_handler = _session_handler;
	/* @ignore */ self.__logger = _logger;
	
	/* @ignore */ self.__closed = false;
	
	/* @ignore */ self.__state_final = false;
	/* @ignore */ self.__state_is_string = false;
	/* @ignore */ self.__state_opcode = 0;
	/* @ignore */ self.__state_length = 0;
	/* @ignore */ self.__state_mask = [0, 0, 0, 0];
	/* @ignore */ self.__state_data_frame_buffer = -1;
	/* @ignore */ self.__state_control_frame_buffer = -1;
	
	/* @ignore */ self.__fsm = new SnowState("header");
	
	self.__session_handler.on_connect(self);
	
	self.__fsm.add("header", {
		handle_data: function(_line_buffer) {
			if (!_line_buffer.has_data(1)) {
				_line_buffer.cleanup(); // trim the buffer back to empty
				return false;
			}
				
			var _read = _line_buffer.read_byte();
			self.__state_final = (_read & 0x80) == 0x80;
			self.__state_opcode = _read & 0x0f;
			
			if (self.__state_opcode == 0x1) {
				self.__state_is_string = true;
			}
			if (self.__state_opcode == 0x2) {
				self.__state_is_string = false;
			}
			
			self.__fsm.change("length7");
			return true;
		}
	});
	self.__fsm.add("length7", {
		handle_data: function(_line_buffer) {
			if (!_line_buffer.has_data(1)) {
				return false;
			}
			
			var _read = _line_buffer.read_byte();
			var _masked = (_read & 0x80) >> 7;
			var _length = _read & 0x7f;
				
			if (_masked == 0) { // oh no! drop the connection, data not masked
				self.__fsm.change("finished");
			}
			else if (_length == 126) {
				self.__fsm.change("length16");
			}
			else if (_length == 127) {
				self.__fsm.change("length32");
			}
			else {
				self.__state_length = _length;
				self.__fsm.change("mask");
			}
			return true
		}
	});
	self.__fsm.add("length16", {
		handle_data: function(_line_buffer) {
			if (!_line_buffer.has_data(2)) {
				return false;
			}
			
			var _high = _line_buffer.read_byte();
			var _low = _line_buffer.read_byte();
			self.__state_length = (_high << 8) | _low;
			self.__fsm.change("mask");
			return true
		}
	});
	self.__fsm.add("length32", {
		handle_data: function(_line_buffer) {
			if (!_line_buffer.has_data(4)) {
				return false;
			}
			
			var _high = _line_buffer.read_byte();
			var _byte2 = _line_buffer.read_byte();
			var _byte3 = _line_buffer.read_byte();
			var _low = _line_buffer.read_byte();
			self.__state_length = (_high << 24) | (_byte2 << 24) | (_byte3 << 24) | _low;
			self.__fsm.change("mask");
			return true
		}
	});
	self.__fsm.add("mask", {
		/** @param {Struct.HttpServerLineBuffer} _line_buffer */
		handle_data: function(_line_buffer) {
			if (!_line_buffer.has_data(4)) {
				return false;
			}
			
			self.__state_mask[0] = _line_buffer.read_byte();
			self.__state_mask[1] = _line_buffer.read_byte();
			self.__state_mask[2] = _line_buffer.read_byte();
			self.__state_mask[3] = _line_buffer.read_byte();
			
			if (self.__state_length > 0) {
				// if we're not a continuation, then delete the frame buffer
				if (buffer_exists(self.__state_data_frame_buffer) && (self.__state_opcode == 0x1 || self.__state_opcode == 0x2)) {
					buffer_delete(self.__state_data_frame_buffer);
					self.__state_data_frame_buffer = -1;
				}
				self.__fsm.change("payload");
			}
			else {
				self.__fsm.change("decode");
			}
			return true
		}
	});
	self.__fsm.add("payload", {
		handle_data: function(_line_buffer) {
			if (!_line_buffer.has_data(self.__state_length)) {
				return false;
			}
			
			var _buffer;
			if (self.__state_opcode == 0x0) {
				// continuation
				_buffer = self.__state_data_frame_buffer;
				if (buffer_exists(_buffer)) {
					// a continuation means more data gets added to the buffer
					buffer_resize(_buffer, buffer_get_size(_buffer) + self.__state_length);
				}
				else {
					// uh oh, continuation but we don't have buffer to continue
					self.__logger.debug("Received continuation frame without a buffer to continue, closing");
					self.__fsm.change("finished");
					return false;
				}
			}
			else if (self.__state_opcode == 0x1 || self.__state_opcode == 0x2) {
				// data frame
				if (buffer_exists(self.__state_data_frame_buffer)) {
					buffer_delete(self.__state_data_frame_buffer);
				}
				self.__state_data_frame_buffer = buffer_create(self.__state_length, buffer_fixed, 1);
				_buffer = self.__state_data_frame_buffer;
			}
			else {
				// control frame
				if (buffer_exists(self.__state_control_frame_buffer)) {
					buffer_delete(self.__state_control_frame_buffer);
				}
				self.__state_control_frame_buffer = buffer_create(self.__state_length, buffer_fixed, 1);
				_buffer = self.__state_control_frame_buffer;
			}

			// loop over the buffer, applying the xor mask
			for (var _i=0; _i<self.__state_length; _i++) {
				buffer_write(_buffer, buffer_u8, _line_buffer.read_byte() ^ self.__state_mask[_i % 4]);
			}
			buffer_seek(_buffer, buffer_seek_start, 0);
			
			self.__fsm.change("decode");
			return true
		}
	});
	self.__fsm.add("decode", {
		enter: function() {
			if (self.__state_final && (self.__state_opcode == 0x0 || self.__state_opcode == 0x1 || self.__state_opcode == 0x2)) {
				self.__fsm.change("dispatch");
			}
			else if (self.__state_opcode == 0x8) {
				self.__fsm.change("close");
			}
			else if (self.__state_opcode == 0x9) {
				self.__fsm.change("ping")
			}
			else if (self.__state_opcode == 0xA) {
				self.__fsm.change("pong");
			}
			else {
				self.__logger.debug("Opcode not understood", {opcode: self.__state_opcode})
				self.__fsm.change("header");
			}
		}
	});
	self.__fsm.add("dispatch", {
		enter: function() {
			self.__session_handler.on_data_buffer(self.__state_data_frame_buffer, self.__state_is_string);
			buffer_delete(self.__state_data_frame_buffer);
			self.__fsm.change("header");
		}
	});
	self.__fsm.add("ping", {
		enter: function() {
			// ping must be responded to with a pong
			if (buffer_exists(self.__state_control_frame_buffer)) {
				self.send_control_buffer(0xA, self.__state_control_frame_buffer); // pong with payload
			}
			else {
				self.send_control(0xA); // poing without payload
			}
			self.__fsm.change("header");
		}
	});
	self.__fsm.add("pong", {
		enter: function() {
			// no need to handle pong
			self.__fsm.change("header");
		}
	});
	self.__fsm.add("close", {
		enter: function(_line_buffer) {
			var _close_code = undefined;
			var _close_reason = undefined;
			if (buffer_exists(self.__state_control_frame_buffer)) {
				var _len = buffer_get_size(self.__state_control_frame_buffer);
				if (_len >= 2) {
					var _high = buffer_read(self.__state_control_frame_buffer, buffer_u8);
					var _low = buffer_read(self.__state_control_frame_buffer, buffer_u8);
					_close_code = (_high << 8)| _low;
						
					if (_len > 2) {
						_close_reason = buffer_read(self.__state_control_frame_buffer, buffer_text);
					}
				}
			}
			
			self.__logger.debug("Received websocket close opcode", {code: _close_code, reason: _close_reason});
			
			// Must echo close message
			// ping must be responded to with a pong
			if (buffer_exists(self.__state_control_frame_buffer)) {
				self.send_control_buffer(0x8, self.__state_control_frame_buffer); // close with payload
			}
			else {
				self.send_control(0x8); // close without payload
			}
			
			// dispatch
			if (!self.__closed) {
				self.__session_handler.on_close(_close_code, _close_reason);
			}
			
			self.__fsm.change("finished");
		}
	});
	self.__fsm.add("finished", {
		enter: function() { self.__closed = true; },
		handle_data: function() { return; }
	});
	
	/** Handle received data
	 * @param {Struct.HttpServerLineBuffer} _line_buffer linebuffer to use
	 */
	static handle_data = function(_line_buffer) {
		var _continue = true;
		
		while(!self.__closed && _continue) {
			// Keep looping over data handling until it reports not handled, then tsop
			// This helps us progress through the states in a single incoming data
			_continue = self.__fsm.handle_data(_line_buffer);
		}
	};
	
	/** Send a ping control value
	 * @param {Any} _value The value to send with the ping, can be real or string
	 */
	static send_ping = function(_value=undefined) {
		if (is_real(_value)) {
			self.send_control_real(0x9, _value);	
		}
		else if (is_string(_value)) {
			self.send_control_string(0x9, _value);	
		}
		else {
			self.send_control(0x9);	
		}
	};
	
	/** Send a data frame with a string value
	 * @param {String} _string The string to send
	 */
	static send_data_string = function(_string) {
		if (!self.__closed) {
			_string = string(_string);
			var _len = string_byte_length(_string);
			var _opcode = 0x1 | 0x80; // Text opcode with final bit set (we're not implementing continuations here
			
			var _buffer
			if (_len < 126) {
				_buffer = buffer_create(_len + 2, buffer_fixed, 1);
				buffer_write(_buffer, buffer_u8, _opcode); 
				buffer_write(_buffer, buffer_s8, _len);
			}
			else if (_len < 65536) {
				_buffer = buffer_create(_len + 4, buffer_fixed, 1);
				buffer_write(_buffer, buffer_u8, _opcode); 
				buffer_write(_buffer, buffer_s8, 126);
				buffer_write(_buffer, buffer_u8, (_len >> 8) & 0xff);
				buffer_write(_buffer, buffer_u8, _len & 0xff);
			}
			else {
				_buffer = buffer_create(_len + 10, buffer_fixed, 1);
				buffer_write(_buffer, buffer_u8, _opcode); 
				buffer_write(_buffer, buffer_s8, 127);
				buffer_write(_buffer, buffer_u32, 0); // let's be realistic, we're not going to send more than 4gb of data here
				buffer_write(_buffer, buffer_u8, (_len >> 24) & 0xff);
				buffer_write(_buffer, buffer_u8, (_len >> 16) & 0xff);
				buffer_write(_buffer, buffer_u8, (_len >> 8) & 0xff);
				buffer_write(_buffer, buffer_u8, _len & 0xff);
			}

			buffer_write(_buffer, buffer_text, _string);
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
		}
	};
	
	/** Send a data frame with a string value
	 * @param {Id.Buffer} _payload The number to send
	 */
	static send_data_buffer = function(_payload) {
		if (!self.__closed) {
			var _len = buffer_get_size(_payload)
			var _opcode = 0x2 | 0x80; // Binary opcode with final bit set (we're not implementing continuations here
			
			var _buffer
			if (_len < 126) {
				_buffer = buffer_create(_len + 2, buffer_fixed, 1);
				buffer_write(_buffer, buffer_u8, _opcode); 
				buffer_write(_buffer, buffer_s8, _len);
			}
			else if (_len < 65536) {
				_buffer = buffer_create(_len + 4, buffer_fixed, 1);
				buffer_write(_buffer, buffer_u8, _opcode); 
				buffer_write(_buffer, buffer_s8, 126);
				buffer_write(_buffer, buffer_u8, (_len >> 8) & 0xff);
				buffer_write(_buffer, buffer_u8, _len & 0xff);
			}
			else {
				_buffer = buffer_create(_len + 10, buffer_fixed, 1);
				buffer_write(_buffer, buffer_u8, _opcode); 
				buffer_write(_buffer, buffer_s8, 127);
				buffer_write(_buffer, buffer_u32, 0); // let's be realistic, we're not going to send more than 4gb of data here
				buffer_write(_buffer, buffer_u8, (_len >> 24) & 0xff);
				buffer_write(_buffer, buffer_u8, (_len >> 16) & 0xff);
				buffer_write(_buffer, buffer_u8, (_len >> 8) & 0xff);
				buffer_write(_buffer, buffer_u8, _len & 0xff);
			}

			buffer_copy(_payload, 0, _len, _buffer, buffer_tell(_buffer));
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
		}
	};
	
	
	/** Send a control frame with no payload
	 * @param {Real} _opcode The Opcode to send
	 */
	static send_control = function(_opcode) {
		if (!self.__closed) {
			var _buffer = buffer_create(2, buffer_fixed, 1);
			buffer_write(_buffer, buffer_u8, (_opcode & 0xf) | 0x80); // OP code with final bit set
			buffer_write(_buffer, buffer_u8, 0); // length is zero
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
		}
	};
	
	/** Send a control frame with a 64-bit float value
	 * @param {Real} _opcode The Opcode to send
	 * @param {Real} _number The number to send
	 */
	static send_control_real = function(_opcode, _number) {
		if (!self.__closed) {
			var _buffer = buffer_create(10, buffer_fixed, 1);
			buffer_write(_buffer, buffer_u8, (_opcode & 0xf) | 0x80); // OP code with final bit set
			buffer_write(_buffer, buffer_u8, 8); // length is zero
			buffer_write(_buffer, buffer_f64, real(_number));
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
		}
	};
	
	/** Send a control frame with a string value
	 * @param {Real} _opcode The Opcode to send
	 * @param {String} _string The number to send
	 */
	static send_control_string = function(_opcode, _string) {
		if (!self.__closed) {
			_string = string(_string);
			var _len = string_byte_length(_string);
			if (_len > 125) {
				// control frame must have payload length of 125 bytes or less
				_string = string_copy(_string, 1, 125);
				_len = 125;
			}
			
			var _buffer = buffer_create(_len+2, buffer_fixed, 1);
			buffer_write(_buffer, buffer_u8, (_opcode & 0xf) | 0x80); // OP code with final bit set
			buffer_write(_buffer, buffer_u8, _len);
			buffer_write(_buffer, buffer_text, _string);
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
		}
	};
	
	/** Send a control frame with a buffer
	 * @param {Real} _opcode The Opcode to send
	 * @param {Id.Buffer} _payload The buffer to send
	 */
	static send_control_buffer = function(_opcode, _payload) {
		if (!self.__closed) {
			// control frame must have payload length of 125 bytes or less
			var _len = min(125, buffer_get_size(_payload))
			
			var _buffer = buffer_create(_len+2, buffer_fixed, 1);
			buffer_write(_buffer, buffer_u8, (_opcode & 0xf) | 0x80); // OP code with final bit set
			buffer_write(_buffer, buffer_u8, _len);
			buffer_copy(_payload, 0, _len, _buffer, 2);
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
		}
	};
	
	/** Explicitly close the connection
	 * @param {Real} _close_code The close code
	 * @param {String} _close_reason The close reason
	 */
	static close = function(_close_code=undefined, _close_reason=undefined) {
		if (!self.__closed) {
			var _opcode = 0x8 | 0x80; // Close opcode with final bit set (we're not implementing continuations here
			
			var _len = 0;
			if (is_real(_close_code)) {
				_len = 2;	
			}
			
			if (is_string(_close_reason)) {
				_close_code ??= 0; // close code can't be undefined if we have a reason
				_close_reason = string(_close_reason);
				var _reason_length = string_byte_length(_close_reason);
				if (_reason_length > 123) {
					// control frame must have payload length of 125 bytes or less
					_close_reason = string_copy(_close_reason, 1, 125);
					_reason_length = 123;
				}
				_len = 2 + _reason_length;
			}
			
			var _buffer = buffer_create(_len+2, buffer_fixed, 1);
			buffer_write(_buffer, buffer_u8, _opcode);
			buffer_write(_buffer, buffer_u8, _len);
			
			if (is_real(_close_code)) {
				buffer_write(_buffer, buffer_u8, (_close_code >> 8) & 0xff);
				buffer_write(_buffer, buffer_u8, _close_code & 0xff);
			}
			if (is_string(_close_reason)) {
				buffer_write(_buffer, buffer_text, _close_reason);
			}
			network_send_raw(self.__client_socket, _buffer, buffer_get_size(_buffer));
			buffer_delete(_buffer);
			
			self.__closed = true;
			self.cleanup();
		}
	};
	
	/** Clean up */
	static cleanup = function() {
		if (!self.__closed) {
			self.__session_handler.on_close(undefined, undefined);
		}
		if (buffer_exists(self.__state_control_frame_buffer)) {
			buffer_delete(self.__state_control_frame_buffer);
		}
		if (buffer_exists(self.__state_data_frame_buffer)) {
			buffer_delete(self.__state_data_frame_buffer);
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
