/** An HTTP response
 * @param {Function} _end_function a callback to call when the the respones is done sending
 * @param {Bool} _header_only whether the response should be only headers
 * @param {String} _compression Compression to use. Either "deflate" or "gzip"
 */
function HttpResponse(_end_function, _header_only=false, _compression="") constructor {
	// Handles an HTTP response

	self.status_code = 405;
	self.headers = {};
	
	/* @ignore */ self.__end_function = _end_function;
	/* @ignore */ self.__response_data_buffer = -1;
	/* @ignore */ self.__network_buffer = -1;
	/* @ignore */ self.__dirty = true;
	/* @ignore */ self.__header_only = _header_only;
	/* @ignore */ self.__compression = _compression;
	/* @ignore */ self.__should_cache = undefined;
	
	/** Clean up dynamic resources */
	static cleanup = function() {
		if (buffer_exists(self.__response_data_buffer)) {
			buffer_delete(self.__response_data_buffer);	
			self.__response_data_buffer = -1;
		}
		if (buffer_exists(self.__network_buffer)) {
			buffer_delete(self.__network_buffer);
			self.__network_buffer = -1;
		}
		self.__dirty = true;
	};

	/** Set status code to be returned in response
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	 */
	static set_status = function(_status_code) {
		self.status_code = _status_code
		self.__dirty = true;
		return self;
	};
	
	/** Set a header to be returned in response
	 * @param {String} _header HTTP header key
	 * @param {String} _value HTTP header value
	 * @return {Struct.HttpResponse}
	 */
	static set_header = function(_header, _value) {
		self.headers[$ _header] = _value;
		self.__dirty = true;
		return self;
	};
	
	/** Set a cookie
	 * @param {String} _name cookie name
	 * @param {String} _value cookie value
	 * @param {Struct} _options additional options
	 * @return {Struct.HttpResponse}
	 */
	static set_cookie = function(_name, _value, _settings={}) {
		var _cookie = $"{_name}={_value}";
		
		if (struct_exists(_settings, "domain")) {
			_cookie += $"; Domain={_settings.domain}";
		}
		if (struct_exists(_settings, "domain")) {
			_cookie += $"; Domain={_settings.domain}";
		}
		if (struct_exists(_settings, "max_age")) {
			_cookie += $"; Max-Age={_settings.max_age}";
		}
		if (struct_exists(_settings, "same_site")) {
			_cookie += $"; SameSite={_settings.same_site}";
		}
		if (struct_exists(_settings, "http_only") && !!_settings.http_only) {
			_cookie += "; HttpOnly";
		}
		if (struct_exists(_settings, "secure") && !!_settings.secure) {
			_cookie += "; Secure";
		}
		
		HttpServer.struct_set_multiple(self.headers, "Set-Cookie", _cookie);
		self.__dirty = true;
		return self;
	};
	
	/** Send a file
	 * @param {String} _filename Path to file
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	 */
	static send_file = function(_filename, _status_code=200) {
		if (buffer_exists(self.__response_data_buffer)) {
			throw "HttpResponse already has data, can't add another buffer";	
		}
		self.status_code = _status_code;
		var _buffer = buffer_load(_filename);
		self.headers[$ "Content-Type"] ??= HttpServer.filename_to_mimetype(_filename);
		self.__set_buffer_response(_buffer);
		return self;
	};
	
	/** Send a string
	 * @param {String} _string Path to file
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	 */
	static send_string = function(_string, _status_code=200) {
		if (buffer_exists(self.__response_data_buffer)) {
			throw "HttpResponse already has data, can't add another buffer";	
		}
		_string = string(_string);
		self.status_code = _status_code;
		var _buffer = buffer_create(string_byte_length(_string), buffer_fixed, 1);
		buffer_write(_buffer, buffer_text, _string);
		self.__set_buffer_response(_buffer);
		return self;
	};
	
	/** Send a string with an HTML mimetype
	 * @param {Any} _serializable JSON serializable value to send
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	 */
	static send_html = function(_string, _status_code=200) {
		self.headers[$ "Content-Type"] = "text/html";
		return self.send_string(_string, _status_code)
	};
	
	/** Send a struct or array or other serializable value as a JSON
	 * @param {Any} _serializable JSON serializable value to send
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	 */
	static send_json = function(_serializable, _status_code=200) {
		self.status_code = _status_code;
		self.headers[$ "Content-Type"] = "application/json";
		return self.send_string(json_stringify(_serializable))
	};

	/** Send nothing (204 response)
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	 */
	static send_empty = function(_status_code=204) {
		self.status_code = _status_code;
		if (buffer_exists(self.__response_data_buffer)) {
			buffer_delete(self.__response_data_buffer);
			self.__response_data_buffer = -1;	
		}
		self.__dirty = true;
		self.__end_function();
		return self;
	};

	/** Send an Exception (204 response)
	 * @param {Struct.ExceptionHttpBase} _err an Exception
	 * @return {Struct.HttpResponse}
	 */
	static send_exception = function(_err) {
		if (is_instanceof(_err, ExceptionHttpBase)) {
			self.send_string(_err.long_message, _err.http_code);
		}
		else {
			
			self.send_string(HttpServer.status_code_to_string(500), 500);
		}
	};

	/** Fetch or generate the buffer to be sending
	 * @return {Id.Buffer}
	 */
	static get_send_buffer = function() {
		if (buffer_exists(self.__network_buffer) && self.__dirty == false) {
			return self.__network_buffer;
		}
		
		if (buffer_exists(self.__network_buffer)) {
			buffer_delete(self.__network_buffer);	
		}
		
		var _response = {
			top_matter: $"HTTP/1.1 {self.status_code} {HttpServer.status_code_to_string(self.status_code)}\r\n" + 
				$"Date: {HttpServer.rfc_date_now()}\r\n" +
				$"Server: {game_display_name} {GM_version} (GameMaker/{GM_runtime_version})\r\n"
		};
		
		struct_foreach(self.headers, method(_response, function(_key, _value) {
			/// Feather ignore GM1010
			if (is_array(_value)) {
				top_matter += string_join_ext("\r\n", _value) + "\r\n";
			}
			else {
				top_matter += $"{_key}: {_value}\r\n";
			}
		}));
		
		_response.top_matter += "\r\n";
		
		if (!buffer_exists(self.__response_data_buffer) || self.__header_only) {
			self.__network_buffer = buffer_create(string_byte_length(_response.top_matter), buffer_fixed, 1);
			buffer_write(self.__network_buffer, buffer_text, _response.top_matter);
		}
		else {
			self.__network_buffer = buffer_create(string_byte_length(_response.top_matter) + buffer_get_size(self.__response_data_buffer), buffer_fixed, 1);
			buffer_write(self.__network_buffer, buffer_text, _response.top_matter);
			buffer_copy(self.__response_data_buffer, 0, buffer_get_size(self.__response_data_buffer), self.__network_buffer, string_byte_length(_response.top_matter));
		}
		
		self.__dirty = false;
		return self.__network_buffer;
	};
	
	/** Get the number of bytes in the response
	 * @return {Real}
	 */
	static get_send_size = function() {
		return buffer_get_size(self.get_send_buffer());
	};
	
	/** Whether we shoould instruct browser/CDN to cache this request
	 * @param {Bool} _should_cache Set to False to override cache value. Set to True to enable cache if nothing else has set it to false
	 */
	static set_should_cache = function(_should_cache) {
		if (_should_cache) {
			self.__should_cache ??= true;
		}
		else {
			self.__should_cache = false;
		}
	};
	
	/**Returns whether we should cache. Defaults to false;
	 * @return {Bool}
	 */
	static get_should_cache = function() {
		return self.__should_cache;
	};
	
	/** Sets the buffer as the response
	 * @param {Id.Buffer} _buffer The bufer to set as response
	 * @param {Bool} _delete_buffer_on_cleanup whether to delete the buffer on cleanup
	 * @ignore
	 */
	static __set_buffer_response = function(_buffer) {
		if (buffer_exists(self.__response_data_buffer)) {
			throw new ExceptionHttpInternal("HttpResponse already has data, can't add another buffer");
		}
		
		var _size = buffer_get_size(_buffer);
		if (self.__compression != "" && _size > 300 && !struct_exists(self.headers, "Content-Encoding")) { // size above which we will compress
			if (self.__compression == "deflate") {
				self.headers[$ "Content-Encoding"] = "deflate";
				var _compressed_buffer = buffer_compress(_buffer, 0, _size);
				buffer_delete(_buffer);
				_buffer = _compressed_buffer;
				_size = buffer_get_size(_compressed_buffer);
			}
			else if (self.__compression == "gzip") {
				self.headers[$ "Content-Encoding"] = "gzip";
				var _compressed_buffer = buffer_compress_gzip(_buffer, 0, _size);
				buffer_delete(_buffer);
				_buffer = _compressed_buffer;
				_size = buffer_get_size(_compressed_buffer);
			}
		}
		
		self.headers[$ "Content-Length"] = _size;
		self.__response_data_buffer = _buffer;
		self.__dirty = true;
		self.__end_function();
	};
}
