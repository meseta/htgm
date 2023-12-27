/** An HTTP server that can respond to HTTP requests
 * @param {Real} _port The port number to bind to
 * @param {Struct.Logger} _logger An optional logger to use. if not provided, one will be created
 */
function HttpServer(_port, _logger=undefined) constructor {
	self.port = _port;
	
	/* @ignore */ self.logger = _logger ?? new Logger("HttpServer", {port: _port});
	
	/* @ignore */ self.__socket = -1;
	/* @ignore */ self.__bound_handler = method(self, self.__async_networking_handler);
	/* @ignore */ self.__client_sessions = {};
	/* @ignore */ self.__router = new HttpServerRouter(self.logger);
	
	/** Start the server, returning whether successful
	 * @return {Bool}
	 */
	static start = function() {
		// can't start if already has a socket
		if (self.__socket != -1) {
			self.logger.warning("Can't start server, already started");
			return false;
		}
		
		self.logger.info("Starting server");
		self.__socket = network_create_server_raw(network_socket_tcp, self.port, 20);
		if (self.__socket == -1) {
			self.logger.error("Server port not available");
			return false;
		}
		
		self.__client_sessions = {};
		
		// spawn the listener instance if not already exists
		AsyncWrapper.remove_async_networking_callback(self.__bound_handler);
		AsyncWrapper.add_async_networking_callback(self.__bound_handler);
		return true;
	};
	
	/** Stops the server and removes the listener
	 * @return {Bool}
	 */
	static stop = function() {
		struct_foreach(self.__client_sessions, function(_client_socket, _client_session) {
			_client_session.close();
		})
		if (self.__socket != -1) {
			network_destroy(self.__socket);
			self.__socket = -1;
		}
		AsyncWrapper.remove_async_networking_callback(self.__bound_handler);
	};
	
	/** Add a path to the router, this is an alias for HttpServerRouter.add_path
	 * @param {String} _path The path pattern to add
	 * @param {Function} _callback The function to call that will handle this path
	 * @return {Struct.HttpServer}
	 */
	static add_path = function(_path, _callback) {
		self.logger.info("Added path", {path: _path});
		self.__router.add_path(_path, _callback);
		return self;
	};
	
	/** Add a single file, serving from files gamemaker can access
	 * @param {String} _path The path pattern to add
	 * @param {String} _file The file path
	 * @return {Struct.HttpServer}
	 */
	static add_file = function(_path, _file) {
		self.logger.info("Added file", {path: _path});
		var _file_handler = new HttpServerFile(_file);
		self.__router.add_path(_path, method(_file_handler, _file_handler.handler));
		return self;
	};
		
	/** Add a file server, serving from files gamemaker can access
	 * @param {String} _path The path pattern to add
	 * @param {String} _web_root The file path that is the server root
	 * @param {String} _index_file The name of the index file in the root
	 * @return {Struct.HttpServer}
	 */
	static add_file_server = function(_path, _web_root, _index_file="index.html") {
		self.logger.info("Added file server", {path: _path});
		var _file_handler = new HttpServerFileServer(_web_root, _index_file);
		self.__router.add_path(_path, method(_file_handler, _file_handler.handler));
		return self;
	};
	
	/** Add a sprite server, serving sprite assets
	 * @param {String} _path The path pattern to add
	 * @param {String} _parameter_name The parameter name inside the path to use
	 * @return {Struct.HttpServer}
	 */
	static add_sprite_server = function(_path, _parameter_name="image_name") {
		self.logger.info("Added sprite server", {path: _path});
		var _sprite_handler = new HttpServerSpriteServer(_parameter_name);
		self.__router.add_path(_path, method(_sprite_handler, _sprite_handler.handler));
		return self;
	};
	
	/** Add a constructor with a render to the router
	 * @param {Function|Struct.HttpServerRenderBase} _render
	 * @param {Bool} _websocket whether this handles websockets
	 * @return {Struct.HttpServer}
	 */
	static add_render = function(_render, _websocket=false) {
		var _inst = is_struct(_render) && !is_method(_render) ? _render : new _render();
		if (!is_method(_inst[$ "handler"])) {
			throw new ExceptionHttpServerSetup("Render does not have a handler method");
		}
		if (!is_string(_inst[$ "path"]) && is_array(_inst[$ "paths"])) {
			throw new ExceptionHttpServerSetup("Render does not have any paths");
		}
		
		var _bound_handler = method(_inst, _inst.handler);
		if (is_string(_inst[$ "path"])) {
			self.logger.info("Added render", {path: _inst.path, websocket: _websocket})
			self.__router.add_path(_inst.path, _bound_handler, _websocket);
		}
		if (is_array(_inst[$ "paths"])) {
			array_foreach(_inst.paths, method({this: other, bound_handler: _bound_handler, websocket: _websocket}, function(_path) {
				this.__logger.info("Added render", {path: _path, websocket: websocket})
				this.__router.add_path(_path, bound_handler, websocket);
			}));
		}
		return self;
	};
	
	/** Add renders based on asset tag. Script resource must have the same name as the constructor in this case
	 * @param {String} _tag_name
	 * @return {Struct.HttpServer}
	 */
	static add_renders_by_tag = function(_tag_name) {
		array_foreach(tag_get_asset_ids(_tag_name, asset_script), function(_asset) {
			self.add_render(_asset);
		});
		return self;
	};
	
	/** Add a websocket route, this is an alias for HttpServerRouter.add_path
	 * @param {String} _path The path pattern to add
	 * @param {Function} _callback The function to call that will handle this path
	 * @return {Struct.HttpServer}
	 */
	static add_websocket = function(_path, _callback) {
		self.logger.info("Added websocket", {path: _path});
		self.__router.add_path(_path, _callback, true);
		return self;
	};
	
	/** Set the default cache control
	 * @param {String} _cache_control The cache control header
	 * @return {Struct.HttpServer}
	 */
	static set_default_cache_control = function(_cache_control) {
		self.__router.set_default_cache_control(_cache_control);
		return self;
	};
	
	/** Handles the incoming async_load from async networking event
	 * @param {Id.DsMap} _async_load the async_load map from async networking event
	 * @ignore
	 */
	static __async_networking_handler = function(_async_load) {
		var _type = _async_load[? "type"];
		var _async_id = _async_load[? "id"];
		switch (_type) {
			case network_type_connect: 
			case network_type_non_blocking_connect:
				if (_async_id == self.__socket) {
					self.__handle_connect(_async_load[? "socket"], _async_load[? "ip"])
				}
				break;
				
			case network_type_disconnect:
				if (_async_id == self.__socket) {
					self.__handle_disconnect(_async_load[? "socket"]);
				}
				break;
				
			case network_type_data:
				var _client_socket = _async_load[? "id"];
				var _buffer = _async_load[? "buffer"];
				if (struct_exists(self.__client_sessions, _client_socket) && buffer_exists(_buffer)) {
					self.__handle_data(_client_socket, _buffer, _async_load[? "size"])
				}
				break;
		}
	};
	
	/** Handle connection events from incoming async_load
	 * @param {Id.Socket} _client_socket the client's socket ID
	 * @ignore
	 */
	static __handle_connect = function(_client_socket, _ip) {
		self.logger.debug("Client connected", {socket_id: _client_socket, ip: _ip})  
		var _child_logger = self.logger.bind({socket_id: _client_socket, ip: _ip});
		self.__client_sessions[$ _client_socket] = new HttpServerSession(_client_socket, self.__router, _child_logger);
	};
	
	/** Handle disconnect events from incoming async_load
	 * @param {Id.Socket} _client_socket the client's socket ID
	 * @ignore
	 */
	static __handle_disconnect = function(_client_socket) {
		self.logger.debug("Client disconnected", {socket_id: _client_socket}) 
		var _client_session = self.__client_sessions[$ _client_socket];
		if (!is_undefined(_client_session)) {
			_client_session.close();
			struct_remove(self.__client_sessions, _client_socket);
		}
	};
	
	/** Handle incoming data, closing socket if necessary
	 * @param {Id.Socket} _client_socket the client's socket ID
	 * @param {Id.Buffer} _buffer the incoming buffer
	 * @param {Real} _size size of incoming buffer
	 * @ignore
	 */
	static __handle_data = function(_client_socket, _buffer, _size) {
		var _client_session = self.__client_sessions[$ _client_socket];
		_client_session.handle_data(_buffer, _size);
		
		if (_client_session.is_closed()) {
			struct_remove(self.__client_sessions, _client_socket);	
		}
	};
	
	/** Decode any url entities
	 * @param {String} _str Input string
	 * @return {String}
	 */
	static url_decode = function(_str) {
		_str = string_replace_all(_str, "+", " ");
		var _parts = string_split(_str, "%");
		var _count = array_length(_parts);
		var _decoded = _parts[0];
		for (var _i=1; _i<_count; _i++) {
			var _part = _parts[_i];
			if (string_length(_part) < 2) {
				_decoded += "%"+_part;
			}
			else {
				var _code = 0;
				
				var _char1 = ord(string_lower(string_char_at(_part, 1)));
				if (_char1 >= 48 && _char1 <= 57) {
					_code += (_char1-48) << 4;	
				}
				else if (_char1 >= 65 && _char1 <= 90) {
					_code += (_char1-55) << 4;	
				}
				else if (_char1 >= 97 && _char1 <= 102) {
					_code += (_char1-87) << 4;	
				}
				else {
					_decoded += "%"+_part;
					continue;	
				}
				
				var _char2 = ord(string_char_at(_part, 2));
				if (_char2 >= 48 && _char2 <= 57) {
					_code += (_char2-48);	
				}
				else if (_char2 >= 65 && _char2 <= 90) {
					_code += (_char2-55);	
				}
				else if (_char2 >= 97 && _char2 <= 102) {
					_code += (_char2-87);	
				}
				else {
					_decoded += "%"+_part;
					continue;	
				}
				
				_decoded += chr(_code) + string_delete(_part, 1, 2);
			}
		}
		
		return _decoded;
	};
	
	/** Updates a struct with a key/value, but if the key already exists, make it an array
	 * This is used in a couple places in the HTTP protocol, such as for query params and forms
	 * @param {Struct} _struct The struct to update
	 * @param {String} _key
	 * @param {Any} _value
	 */
	static struct_set_multiple = function(_struct, _key, _value) {
		if (struct_exists(_struct, _key)) {
			if (is_array(_struct[$ _key])) {
				array_push(_struct[$ _key], _value);
			}
			else {
				_struct[$ _key] = [_struct[$ _key], _value];
			}
		}
		else {
			_struct[$ _key] = _value;
		}	
		
	}
	
	/** Get the string representation of a status code
	* @param {Real} _code The numerical return code
	* @return {String}
	* @pure
	 */
	static status_code_to_string = function(_code) {
		switch (_code) {
			case 100: return "Continue";
			case 101: return "Switching Protocols";
			case 102: return "Processing";
			case 200: return "OK";
			case 201: return "Created";
			case 202: return "Accepted";
			case 203: return "Non-authoritative Information";
			case 204: return "No Content";
			case 205: return "Reset Content";
			case 206: return "Partial Content";
			case 207: return "Multi-Status";
			case 208: return "Already Reported";
			case 226: return "IM Used";
			case 300: return "Multiple Choices";
			case 301: return "Moved Permanently";
			case 302: return "Found";
			case 303: return "See Other";
			case 304: return "Not Modified";
			case 305: return "Use Proxy";
			case 307: return "Temporary Redirect";
			case 308: return "Permanent Redirect";
			case 400: return "Bad Request";
			case 401: return "Unauthorized";
			case 402: return "Payment Required";
			case 403: return "Forbidden";
			case 404: return "Not Found";
			case 405: return "Method Not Allowed";
			case 406: return "Not Acceptable";
			case 407: return "Proxy Authentication Required";
			case 408: return "Request Timeout";
			case 409: return "Conflict";
			case 410: return "Gone";
			case 411: return "Length Required";
			case 412: return "Precondition Failed";
			case 413: return "Payload Too Large";
			case 414: return "Request-URI Too Long";
			case 415: return "Unsupported Media Type";
			case 416: return "Requested Range Not Satisfiable";
			case 417: return "Expectation Failed";
			case 418: return "I'm a teapot";
			case 421: return "Misdirected Request";
			case 422: return "Unprocessable Entity";
			case 423: return "Locked";
			case 424: return "Failed Dependency";
			case 426: return "Upgrade Required";
			case 428: return "Precondition Required";
			case 429: return "Too Many Requests";
			case 431: return "Request Header Fields Too Large";
			case 444: return "Connection Closed Without Response";
			case 451: return "Unavailable For Legal Reasons";
			case 499: return "Client Closed Request";
			case 500: return "Internal Server Error";
			case 501: return "Not Implemented";
			case 502: return "Bad Gateway";
			case 503: return "Service Unavailable";
			case 504: return "Gateway Timeout";
			case 505: return "HTTP Version Not Supported";
			case 506: return "Variant Also Negotiates";
			case 507: return "Insufficient Storage";
			case 508: return "Loop Detected";
			case 510: return "Not Extended";
			case 511: return "Network Authentication Required";
			case 599: return "Network Connect Timeout Error";
			default:
				if (100 >= _code and _code < 200) return "Informational";
				if (200 >= _code and _code < 300) return "Success";
				if (300 >= _code and _code < 400) return "Redirection";
				if (400 >= _code and _code < 500) return "Client Error";
				return "Server Error";
		}
	};
	
	/** Get the mime type from a file extension
	 * @param {String} _file_name The filename to guess mimetype of
	 * @return {String}
	 * @pure
	 */
	static filename_to_mimetype = function(_file_name) {
		var _last_pos = string_last_pos(".", _file_name);
		var _extension = _last_pos == 0 ? "" : string_delete(_file_name, 1, _last_pos);
		
		switch (_extension) {
			case "aac": return "audio/aac";
			case "abw": return "application/x-abiword";
			case "arc": return "application/x-freearc";
			case "avi": return "video/x-msvideo";
			case "azw": return "application/vnd.amazon.ebook";
			case "bin": return "application/octet-stream";
			case "bmp": return "image/bmp";
			case "bz": return "application/x-bzip";
			case "bz2": return "application/x-bzip2";
			case "cda": return "application/x-cdf";
			case "csh": return "application/x-csh";
			case "css": return "text/css";
			case "csv": return "text/csv";
			case "doc": return "application/msword";
			case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
			case "eot": return "application/vnd.ms-fontobject";
			case "epub": return "application/epub+zip";
			case "gz": return "application/gzip";
			case "gif": return "image/gif";
			case "htm": return "text/html";
			case "html": return "text/html";
			case "ico": return "image/vnd.microsoft.icon";
			case "ics": return "text/calendar";
			case "jar": return "application/java-archive";
			case "jpeg": return "image/jpeg";
			case "jpg": return "image/jpeg";
			case "js": return "text/javascript";
			case "json": return "application/json";
			case "jsonld": return "application/ld+json";
			case "mid": return "audio/midi audio/x-midi";
			case "midi": return "audio/midi audio/x-midi";
			case "mjs": return "text/javascript";
			case "mp3": return "audio/mpeg";
			case "mp4": return "video/mp4";
			case "mpeg": return "video/mpeg";
			case "mpkg": return "application/vnd.apple.installer+xml";
			case "odp": return "application/vnd.oasis.opendocument.presentation";
			case "ods": return "application/vnd.oasis.opendocument.spreadsheet";
			case "odt": return "application/vnd.oasis.opendocument.text";
			case "oga": return "audio/ogg";
			case "ogv": return "video/ogg";
			case "ogx": return "application/ogg";
			case "opus": return "audio/opus";
			case "otf": return "font/otf";
			case "png": return "image/png";
			case "pdf": return "application/pdf";
			case "php": return "application/x-httpd-php";
			case "ppt": return "application/vnd.ms-powerpoint";
			case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
			case "rar": return "application/vnd.rar";
			case "rtf": return "application/rtf";
			case "sh": return "application/x-sh";
			case "svg": return "image/svg+xml";
			case "swf": return "application/x-shockwave-flash";
			case "tar": return "application/x-tar";
			case "tif": return "image/tiff";
			case "tiff": return "image/tiff";
			case "ts": return "video/mp2t";
			case "ttf": return "font/ttf";
			case "txt": return "text/plain";
			case "vsd": return "application/vnd.visio";
			case "wav": return "audio/wav";
			case "weba": return "audio/webm";
			case "webm": return "video/webm";
			case "webp": return "image/webp";
			case "woff": return "font/woff";
			case "woff2": return "font/woff2";
			case "xhtml": return "application/xhtml+xml";
			case "xls": return "application/vnd.ms-excel";
			case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
			case "xml": return "application/xml";
			case "xul": return "application/vnd.mozilla.xul+xml";
			case "zip": return "application/zip";
			case "3gp": return "video/3gpp";
			case "3g2": return "video/3gpp2";
			case "7z": return "application/x-7z-compressed";
			default: return "application/octet-stream";
		}
	};
	
	/** Get the current correctly formatted date
	 * @return {String}
	 */
	static rfc_date_now = function() {
		var _prev_timezone = date_get_timezone();
		date_set_timezone(timezone_utc);
		
		var _str = self.__rfc_date(date_current_datetime());
		
		date_set_timezone(_prev_timezone);
		return _str;
	};
	
	/** Get the correctly formatted date for a given gamemaker datetime
	 * @return {Real} _datetime the datetime in Gamemaker format (e.g. date_current_datetime());
	 * @return {String}
	 * @ignore
	 */
	static __rfc_date = function(_datetime) {	
		var _weekday;
		switch(date_get_weekday(_datetime)) {
			case 0: _weekday = "Sun"; break;
			case 1: _weekday = "Mon"; break;
			case 2: _weekday = "Tue"; break;
			case 3: _weekday = "Wed"; break;
			case 4: _weekday = "Thu"; break;
			case 5: _weekday = "Fri"; break;
			case 6: _weekday = "Sat"; break;
		}
		
		var _day = self.__zero_pad_string(date_get_day(_datetime), 2);
		
		var _month;
		switch(date_get_month(_datetime)) {
			case 1: _month = "Jan"; break;
			case 2: _month = "Feb"; break;
			case 3: _month = "Mar"; break;
			case 4: _month = "Apr"; break;
			case 5: _month = "May"; break;
			case 6: _month = "Jun"; break;
			case 7: _month = "Jul"; break;
			case 8: _month = "Aug"; break;
			case 9: _month = "Sep"; break;
			case 10: _month = "Oct"; break;
			case 11: _month = "Nov"; break;
			case 12: _month = "Dec"; break;
		}
		
		var _year = string(date_get_year(_datetime));
		var _hours = self.__zero_pad_string(date_get_hour(_datetime), 2);
		var _minutes = self.__zero_pad_string(date_get_minute(_datetime), 2);
		var _seconds = self.__zero_pad_string(date_get_second(_datetime), 2);
		
		return $"{_weekday}, {_day} {_month} {_year} {_hours}:{_minutes}:{_seconds} GMT";
	};
	
	/** Pad a number zeros
	 * @return {Real} _number The number to pad
	 * @return {Real} _places How many places to pad to
	 * @return {String}
	 * @ignore
	 */
	static __zero_pad_string = function(_number, _places) {
		return string_replace(string_format(_number, _places, 0), " ", "0");
	};
}
