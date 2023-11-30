/**
 * @desc An HTTP server that can respond to HTTP requests
 * @param {Real} _port The port number to bind to
 * @param {Struct.Logger} _logger An optional logger to use. if not provided, one will be created
**/
function HttpServer(_port, _logger=undefined) constructor {
	/* @ignore */ self.__port = _port;
	/* @ignore */ self.__logger = _logger ?? new Logger("HttpServer", {port: _port});
	
	/* @ignore */ self.__socket = -1;
	/* @ignore */ self.__listener_instance = noone;
	/* @ignore */ self.__client_sessions = {};
	/* @ignore */ self.__router = new HttpServerRouter(self.__logger);
	
	/**
	 * @desc Start the server, returning whether successful
	 * @return {Bool}
	**/
	static start = function() {
		// can't start if already has a socket
		if (self.__socket != -1) {
			self.__logger.warning("Can't start server, already started", undefined, LOG_TYPE_HTTP);
			return false;
		}
		
		self.__logger.info("Starting server", undefined, LOG_TYPE_HTTP);
		self.__socket = network_create_server_raw(network_socket_tcp, self.__port, 20);
		if (self.__socket == -1) {
			self.__logger.error("Server port not available", undefined, LOG_TYPE_HTTP);
			return false;
		}
		
		self.__client_sessions = {};
		
		// spawn the listener instance if not already exists
		var _bound_handler = method(self, self.__async_networking_handler);
		if (!instance_exists(self.__listener_instance)) {
			self.__listener_instance = instance_create_depth(0, 0, 0, objHttpServerListener, {async_networking_handler: _bound_handler})
		}
		else {
			self.__listener_instance.async_networking_handler = _bound_handler;
		}
		return true;
	};
	
	/**
	 * @desc Stops the server and removes the listener
	 * @return {Bool}
	**/
	static stop = function() {
		struct_foreach(self.__client_sessions, function(_client_socket, _client_session) {
			_client_session.close();
		})
		if (self.__socket != -1) {
			network_destroy(self.__socket);
			self.__socket = -1;
		}
		if (instance_exists(self.__listener_instance)) {
			instance_destroy(self.__listener_instance);
		}
	};
	
	/**
	 * @desc Add a path to the router, this is an alias for HttpServerRouter.add_path
	 * @param {String} _path The path pattern to add
	 * @param {Function} _callback The function to call that will handle this path
	 * @return {Struct.HttpServerRouter}
	**/
	static add_path = function(_path, _callback) {
		return self.__router.add_path(_path, _callback);
	};
	
	/**
	 * @desc Add a file server, serving from files gamemaker can access
	 * @param {String} _path The path pattern to add
	 * @param {String} _web_root The file path that is the server root
	 * @param {String} _index_file The name of the index file in the root
	 * @return {Struct.HttpServerRouter}
	**/
	static add_file_server = function(_path, _web_root, _index_file="index.html") {
		var _fileserver = new HttpServerFileServer(_web_root, _index_file);
		return self.__router.add_path(_path, method(_fileserver, _fileserver.handler))
	}
	
	/**
	 * @desc Handles the incoming async_load from async networking event
	 * @param {Id.DsMap} _async_load the async_load map from async networking event
	 * @ignore
	**/
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
				if (struct_exists(self.__client_sessions, _client_socket)) {
					self.__handle_data(_client_socket, _async_load[? "buffer"], _async_load[? "size"])
				}
				break;
		}
	};
	
	/**
	 * @desc Handle connection events from incoming async_load
	 * @param {Id.Socket} _client_socket the client's socket ID
	 * @ignore
	**/
	static __handle_connect = function(_client_socket, _ip) {
		self.__logger.debug("Client connected", {socket_id: _client_socket, ip: _ip}, LOG_TYPE_HTTP)  
		var _child_logger = self.__logger.bind({socket_id: _client_socket, ip: _ip});
		self.__client_sessions[$ _client_socket] = new HttpServerSession(_client_socket, self.__router, _child_logger);
	};
	
	/**
	 * @desc Handle disconnect events from incoming async_load
	 * @param {Id.Socket} _client_socket the client's socket ID
	 * @ignore
	**/
	static __handle_disconnect = function(_client_socket) {
		self.__logger.debug("Client disconnected", {socket_id: _client_socket}, LOG_TYPE_HTTP) 
		var _client_session = self.__client_sessions[$ _client_socket];
		if (!is_undefined(_client_session)) {
			struct_remove(self.__client_sessions, _client_socket);
		}
	};
	
	/**
	 * @desc Handle incoming data, closing socket if necessary
	 * @param {Id.Socket} _client_socket the client's socket ID
	 * @param {Id.Buffer} _buffer the incoming buffer
	 * @param {Real} _size size of incoming buffer
	 * @ignore
	**/
	static __handle_data = function(_client_socket, _buffer, _size) {
		var _client_session = self.__client_sessions[$ _client_socket];
		_client_session.handle_data(_buffer, _size);
		
		if (_client_session.is_closed()) {
			struct_remove(self.__client_sessions, _client_socket);	
		}
	};
	
	/**
	* @desc Get the string representation of a status code
	* @param {Real} _code The numerical return code
	* @return {String}
	* @pure
	**/
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
	
	/**
	 * @desc Get the mime type from a file extension
	 * @param {String} _file_name The filename to guess mimetype of
	 * @return {String}
	 * @pure
	**/
	static filename_to_mimetype = function(_file_name) {
		var _len = string_length(_file_name);
		var _last_pos = string_last_pos(".", _file_name);
		
		var _extension = _last_pos == 0 ? "" : string_copy(_file_name, _last_pos, _len-_last_pos)
		
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
}
