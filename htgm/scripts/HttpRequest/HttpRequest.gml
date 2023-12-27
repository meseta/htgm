/** An HTTP request 
 * @param {String} _method The request method
 * @param {String} _path The request path
 */
function HttpRequest(_method, _path) constructor {
	
	// request content
	self.method = _method;
	self.path = HttpServer.url_decode(_path);
	self.path_original = self.path;
	self.query = {};
	
	// header content
	self.keep_alive = true;
	self.headers = {};
	self.parameters = {};
	self.cookies = {};
	
	// body content
	self.data = -1;
	self.form = {};
	self.files = {};
	
	/** Clean up dynamic resources */
	static cleanup = function() {
		if (buffer_exists(self.data)) {
			buffer_delete(self.data);	
		}
		
		struct_foreach(self.files, function(_name, _file) {
			_file.cleanup();
		})
	};

	/** Sets the path for redirects (will leave path_original the same)
	 * @param {String} _path The new path
	 * @return {Struct.HttpRequest}
	 */
	static set_path = function(_path) {
		self.path = _path;
		return self;
	};
	
	/** Sets the request body data, and decode it if supported
	 * @param {Id.Buffer} _buffer The buffer to set the data for
	 * @return {Struct.HttpRequest}
	 */
	static set_data = function(_buffer) {
		self.data = _buffer;
		
		return self;
	};
	
	/** Gets the buffer as a string
	 * @return {String}
	 */
	static get_data_as_string = function() {
		if (!buffer_exists(self.data)) {
			return "";	
		}
		
		buffer_seek(self.data, buffer_seek_start, 0);
		var _string = buffer_read(self.data, buffer_text);
		return _string;
	};
	
	/** Gets the buffer as a json
	 * @return {Struct*}
	 */
	static get_data_as_json = function() {
		if (!buffer_exists(self.data)) {
			return "";	
		}
		
		buffer_seek(self.data, buffer_seek_start, 0);
		var _string = buffer_read(self.data, buffer_text);
		try {
			return json_decode(_string);
		}
		catch (_err) {
			return undefined;	
		}
	};
	
	/** Checks if a header exists
	 * @param {String} _key the name of the header to get
	 * @return {Bool}
	 */
	static has_header = function(_key) {
		return struct_exists(self.headers, string_lower(_key));
	};
	
	/** Gets a header, returning either string or undefined
	 * @param {String} _key the name of the header to get
	 * @return {String*}
	 */
	static get_header = function(_key) {
		return self.headers[$ string_lower(_key)];
	};
		
	/** Sets a header
	 * @param {String} _key the name of the header to set
	 * @param {String} _value the value to set
	 * @return {Struct.HttpRequest}
	 */
	static set_header = function(_key, _value) {
		self.headers[$ string_lower(_key)] = string(_value);
		
		// additionally decode cookies
		if (string_lower(_key) == "cookie") {
			var _cookies = self.__decode_header_values(_value);
			struct_foreach(_cookies, function(_cookie_name, _cookie_value) {
				HttpServer.struct_set_multiple(self.cookies, _cookie_name, _cookie_value);	
			})
		}
		return self;
	};
	
	/** Checks if a cookie exists
	 * @param {String} _name name of the cookie
	 * @return {Bool}
	 */
	static has_cookie = function(_name) {
		return struct_exists(self.cookies, _name);
	};
	
	/** Gets a cookie, returning either string or undefined
	 * @param {String} _name the name of the cookie to get
	 * @return {String|Array<String>|Undefined}
	 */
	static get_cookie = function(_name) {
		return self.cookies[$ _name];
	};
	
	/** Gets whether a parameter exists
	 * @param {String} _key the name of the parameter to get
	 * @return {Bool}
	 */
	static has_parameter = function(_key) {
		return struct_exists(self.parameters, _key);
	};

	/** Gets a path paramete
	 * @param {String} _key the name of the query to get
	 * @return {String*}
	 */
	static get_parameter = function(_key) {
		return self.parameters[$ _key];
	};
	
	/** Gets whether a query param exists
	 * @param {String} _key the name of the query parameter to get
	 * @return {Bool}
	 */
	static has_query = function(_key) {
		return struct_exists(self.query, _key);
	};

	/** Gets a query value
	 * @param {String} _key the name of the query to get
	 * @return {String*}
	 */
	static get_query = function(_key) {
		return self.query[$ _key];
	};
	
	/** Gets whether a form value exists
	 * @param {String} _key the name of the form data to get
	 * @return {Bool}
	 */
	static has_form = function(_key) {
		return struct_exists(self.form, _key);
	};

	/** Gets a form value, returning either string or undefined
	 * @param {String} _key the name of the query to get
	 * @return {String*}
	 */
	static get_form = function(_key) {
		return self.form[$ _key];
	};
	
	/** Gets whether a file exists
	 * @param {String} _key the name of the form data to get
	 * @return {Bool}
	 */
	static has_file = function(_key) {
		return struct_exists(self.files, _key);
	};

	/** Gets a file, returning either string or undefined
	 * @param {String} _key the name of the query to get
	 * @return {Id.Buffer}
	 */
	static get_file = function(_key) {
		return self.files[$ _key];
	};
	
	/** Gets the name of the file returning either string or undefined
	 * @param {String} _key the name of the query to get
	 * @return {String*}
	 */
	static get_file_name = function(_key) {
		return self.file_names[$ _key];
	};
	
	/** Sets parameters, sets the parameters and query
	 * @param {Struct} _parameters All the parameters to set
	 * @param {Struct} _query All the query params to set
	 * @return {Struct.HttpRequest}
	 */
	static set_parameters = function(_parameters, _query) {
		self.parameters = _parameters;
		self.query = _query;
		return self;
	};
	
	/** Decodes the content of the request, used for form data */
	static decode_content = function() {
		var _content_type = self.get_header("content-type");
		if (!is_string(_content_type)) {
			return;
		}
		var _content_type_data = self.__decode_header_values(_content_type);
		
		if(_content_type_data._ == "application/x-www-form-urlencoded") {
			var _string = self.get_data_as_string();	
			
			// split string
			var _variables = string_split(_string, "&", true);
			array_foreach(_variables, method(self.form, function(_variable) {
				var _pair = string_split(_variable, "=", false, 1);
				var _key = HttpServer.url_decode(_pair[0]);
				
				if (string_length(_key) > 0) {
					var _value = array_length(_pair) > 1 ? _pair[1] : undefined;
					_value = HttpServer.url_decode(_value);
					HttpServer.struct_set_multiple(self, _key, _value);
				}
			}));
		}
		else if(_content_type_data._ == "multipart/form-data") {
			// decode the boundary value
			if (!struct_exists(_content_type_data, "boundary")) {
				throw new ExceptionHttpBadRequest("Multipart boundary not found");
			}
			
			// make the boundary buffer
			var _boundary = "--" + _content_type_data.boundary;
			var _boundary_len = string_byte_length(_boundary);
			var _boundary_buffer = buffer_create(_boundary_len, buffer_fixed, 1);
			buffer_write(_boundary_buffer, buffer_text, _boundary);
			
			var _line_buffer = new HttpServerLineBuffer(self.data);
			_line_buffer.seek(0);
			
			// keep reading lines as long as we have data, the 5 is because the final
			// bytes are always `--\r\n` so we need to check that we have at least this
			// many
			
			var _tell = -1;
			while (_line_buffer.has_data(5) && _tell != _line_buffer.tell()) {
				_tell = _line_buffer.tell();
				
				var _buff = _line_buffer.read_until_bytes(_boundary_buffer);
				if (is_undefined(_buff)) {
					// didn't find any more boundaries
					break;
				}
				if (_buff != -1) {
				
					// for each multipart, we spin up a new line buffer to read
					var _part_line_buffer = new HttpServerLineBuffer(_buff);
					
					// read headers
					var _name = undefined;
					var _filename = undefined;
					var _content_type = undefined;
					var _content_length = undefined;
					
					// check headers
					while (_part_line_buffer.has_data()) {
						var _header = _part_line_buffer.read_line();
						if (is_undefined(_header)) break;
						
						if (_header = "") break; // end of headers
						
						// decode heade
						var _header_split = string_split(_header, ":", false, 1);
						var _header_key = string_lower(_header_split[0]);
						var _header_value = string_trim_start(_header_split[1]);
						
						if (_header_key == "content-disposition") {
							var _header_struct = self.__decode_header_values(_header_value);
							if (_header_struct._ != "form-data") {
								_part_line_buffer.cleanup();
								buffer_delete(_boundary_buffer);
								throw new ExceptionHttpBadRequest("Multipart content-disposition was not form-data");
							}
							
							if (struct_exists(_header_struct, "name")) {
								_name = HttpServer.url_decode(string_replace_all(_header_struct.name, @'"', ""));
							}
							else if (struct_exists(_header_struct, "filename")) {
								_filename = HttpServer.url_decode(string_replace_all(_header_struct.filename, @'"', ""));
							}
						}
						else if (_header_key == "content-type") {
							_content_type = _header_value;
						}
						else if (_header_key == "content-length") {
							_content_length = real(_header_value);
						}
					}
				
					// ready to read data, read the rest of the buffer, minus 2 for \r\n
					var _content_buff = _part_line_buffer.read_until_end(2);
					_part_line_buffer.cleanup();
					if (is_undefined(_content_buff)) {
						buffer_delete(_boundary_buffer);
						throw new ExceptionHttpBadRequest("Multipart didn't contain any data");
					}
				
					if (is_undefined(_filename) && is_undefined(_content_type)) {
						// probably just form data.
						var _value = "";
						if (buffer_exists(_content_buff)) { // buffer can be non-existent for blank strings
							_value = buffer_read(_content_buff, buffer_text);
							buffer_delete(_content_buff);
						}
						HttpServer.struct_set_multiple(self.form, _name, _value);
					}
					else {
						// probably a file
						var _file = new HttpRequestFile(_content_buff, buffer_get_size(_content_buff), _content_type, _filename);
						HttpServer.struct_set_multiple(self.files, _name, _file);
					}
				}
				
				// check if we're done. the next two bytes after the boundary are either "--" for a completion or "\r\n"
				var _next_1 = _line_buffer.read_byte();
				var _next_2 = _line_buffer.read_byte();
				if (_next_1 == 13 && _next_2 == 10) {
					continue; // \r\n	
				}
				else if (_next_1 == 45 && _next_2 == 45) {
					break; // --
				}
			}
			
			buffer_delete(_boundary_buffer);
			_line_buffer.seek(0);
		}
	}
	
	/** Decodes header values that are semicolon-separated
	 * @param {String} _string the header value
	 * @return {Struct}
	 * @ignore
	 */
	static __decode_header_values = function(_string) {
		var _pairs = string_split(_string, ";");
			
		return array_reduce(_pairs, function(_struct, _pair) {
			var _parts = string_split(string_trim_start(_pair), "=");
			if (array_length(_parts) == 1) {
				_struct._ = _parts[0];
			}
			else {
				_struct[$ HttpServer.url_decode(_parts[0]) ] = HttpServer.url_decode(_parts[1]);	
			}
			return _struct;
		}, {_: undefined});
	}
}
