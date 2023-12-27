/** Handles routing requests to specific handler functions
 * @param {Struct.Logger} _logger logger to use
 */
function HttpServerRouter(_logger) constructor {
	/* @ignore */ self.__logger = _logger;
	/* @ignore */ self.__handlers = [];
	/* @ignore */ self.__websocket_handlers = [];
	/* @ignore */ self.__paths = {};
	/* @ignore */ self.__not_found_handler = self.__default_not_found_handler;
	/* @ignore */ self.__default_cache_control = "no-cache";
	
	/** Add a path to the router
	 * @param {String} _path The path pattern to add
	 * @param {Function} _callback The function to call that will handle this path
	 * @param {Bool} _is_websocket Whether the pathi s a websocket path
	 * @return {Struct.HttpServerRouter}
	 */
	static add_path = function(_path, _callback, _is_websocket=false) {
		var _check_path = _path == "" ? "/" : _path;
		if (struct_exists(self.__paths, _check_path)) {
			throw new ExceptionHttpServerSetup("HttpServerRouter Path already exists", $"The path {_path} already exists in the router")	
		}
		// validate paths
		var _pattern_parts = string_split(_path, "/", true);
		array_foreach(_pattern_parts, function(_part) {
			var _left = string_count("{", _part);
			var _right = string_count("}", _part);
			var _stars = string_count("*", _part);
			
			if (_left != _right or _left > 1 or _right > 1 or _stars > 1) {
				throw new ExceptionHttpServerSetup("HttpServerRouter Path format incorrect", $"Path part {_part} is incorrectly formatted");
			}
			
			if (_stars == 1 and _part != "*") {
				throw new ExceptionHttpServerSetup("HttpServerRouter Path too many wildcards", $"Path part {_part} must be exactly a wildard '*' if at all");
			}
		});
		
		self.__paths[$ _check_path] = true;
		
		var _handlers = _is_websocket ? self.__websocket_handlers : self.__handlers;
		array_push(_handlers, {
			pattern_parts: _pattern_parts,
			callback: _callback
		});
		
		return self;
	};
	
	/** Process a request and run the handler for the path
	 * @param {Struct.HttpRequest} _request The incoming request
	 * @param {Struct.HttpResponse} _response The response going back out
	 */
	static process_request = function(_request, _response) {
		// try to process request body. This could error at this point
		_request.decode_content();
		
		var _context = new HttpServerRequestContext(_request, _response, self.__logger.bind({}));
		var _foreach_context = {this: other, completed: false, context: _context};
		
		var _internal_redirect;
		
		do {
			_internal_redirect = false;
			try {
				Iterators.foreach(self.__handlers, method(_foreach_context, function(_handler) {
					/// Feather ignore GM1013
					var _match = this.__path_match(_handler.pattern_parts, context.request.path);
					if (!is_undefined(_match)) {
						context.request.set_parameters(_match.parameters, _match.query);
						_handler.callback(context);
						completed = true;
						throw Iterators.STOP_ITERATION;
					}
				}));
			}
			catch (_err) {
				if (is_instanceof(_err, ExceptionHttpServerInternalRedirect)) {
					var _path = _err.path;
					self.__logger.debug("Internal redirect", {path: _path});
					_response.cleanup();
					_request.set_path(_path);
					_internal_redirect = true;
				}
				else {
					throw _err;
				}
			}
		} until (!_internal_redirect);
		
		if (!_foreach_context.completed) { // if we didn't run a callback run the default handler
			self.__not_found_handler(_context);
		}
	};
	
	/** Process a websocket, returning the handler object if successful
	 * @param {Struct.HttpRequest} _request The incoming request
	 * @return {Struct.HttpServerwebsocketSessionBase|Undefined}
	 */
	static process_websocket = function(_request) {
		var _context = new HttpServerRequestContext(_request, undefined, self.__logger.bind({}));
		var _foreach_context = {this: other, session_handler: undefined, context: _context};
		
		Iterators.foreach(self.__websocket_handlers, method(_foreach_context, function(_handler) {
			/// Feather ignore GM1013
			var _match_params = this.__path_match(_handler.pattern_parts, context.request.path);
			if (!is_undefined(_match_params)) {
				context.request.set_parameters(_match_params);
				session_handler = _handler.callback(context);
				throw Iterators.STOP_ITERATION;
			}
		}));
		
		return _foreach_context.session_handler;
	};
	
	/** Set the handler for paths that aren't found
	 * @param {Function} _function The incoming request
	 * @return {Struct.HttpServerRouter}
	 */
	static set_not_found_handler = function(_function) {
		self.__not_found_handler = _function;
		return self;
	};
	
	/** Set the default cache control
	 * @param {String} _cache_control The cache control header
	 * @return {Struct.HttpServerRouter}
	 */
	static set_default_cache_control = function(_cache_control) {
		self.__default_cache_control = _cache_control;
		return self;
	};
	
	/** Get the default cache control
	 * @return {String}
	 */
	static get_default_cache_control = function() {
		return self.__default_cache_control;
	};
	
	/** Try to match a path to a pattern, either a matches struct is returned, or undefined
	 * @param {Array<string>} _pattern_parts The split array of the pattern that the raw path matches to
	 * @param {string} _raw_path The response going back out
	 * @return {Any}
	 * @ignore
	 */
	static __path_match = function(_pattern_parts, _raw_path) {
		// handle queries
		var _query_pos = string_pos("?", _raw_path);
		var _query_string;
		var _path_string;
		if (_query_pos > 0) {
			_query_string = string_copy(_raw_path, _query_pos+1, string_length(_raw_path)-_query_pos);
			_path_string = string_copy(_raw_path, 1, _query_pos-1);
		}
		else {
			_query_string = "";
			_path_string = _raw_path;
		}
		
		var _param_struct = {}
		
		 // trim first "/"
		var _unresolved_paths = string_split_ext(_path_string, ["/", "\\"], true);
		var _unresolved_paths_len = array_length(_unresolved_paths);
		
		var _paths = [];
		for (var _i=0; _i<_unresolved_paths_len; _i++) {
			var _unresolved_path = _unresolved_paths[_i];
			if (_unresolved_path == ".") continue;
			else if (_unresolved_path == "..") { // try to go up
				if (array_length(_paths) > 0) {
					array_pop(_paths);	
				}
				else {
					return undefined; // no match
				}
			}
			else if (_unresolved_path == "~") {
				_paths = [];	
			}
			else {
				array_push(_paths, _unresolved_path);	
			}
		}
		var _paths_len = array_length(_paths);
		
		var _patterns_len = array_length(_pattern_parts);
		if (_paths_len < _patterns_len) return undefined; // path can't be smaller than pattern
		if (_paths_len > _patterns_len && array_last(_pattern_parts) != "*") return undefined; // if path is longer, pattern can't not end in wildcard
		
		for (var _i=0; _i<_patterns_len; _i++) {
			var _pattern = _pattern_parts[_i];
			
			// check for wildcard
			if (_pattern == "*") {
				// remove the earlier parts of the path, and store the rest in _param_struct.
				array_delete(_paths, 0, _i); // NOTE: in-place _path mutation, but we discard this array anyway so it's okay
				_param_struct[$ "*"] = string_join_ext("/", _paths);
				break;
			}
			
			// check for exact match
			var _path = _paths[_i];
			var _before_pos = string_pos("{", _pattern);
			if (_before_pos == 0) { // no { found
				if (_pattern == _path) { // exact text match
					continue;
				}
				else { // not a match
					return undefined;
				}
			}
			
			// Match part before {
			if (_before_pos > 1) {
				if (string_copy(_path, 1, _before_pos-1) != string_copy(_pattern, 1, _before_pos-1)) {
					return undefined;
				}
			}
			
			// Match part after }
			var _path_len = string_length(_path);
			var _after_pos = string_pos("}", _pattern);
			var _pattern_length = string_length(_pattern);
			var _after_len = _pattern_length - _after_pos;
			if (_after_len > 0) {
				if (string_delete(_path, 1, _path_len-_after_len) != string_delete(_pattern, 1, _after_pos)) {
					return undefined;
				}
			}

			// it's a match! extract the param
			var _param_name = string_copy(_pattern, _before_pos+1, _after_pos-_before_pos-1);
			var _match = string_copy(_path, _before_pos, _path_len-(_before_pos-1)-(_pattern_length-_after_pos));
			
			_param_struct[$ HttpServer.url_decode(_param_name)] = HttpServer.url_decode(_match);
		}
		
		// decode query params
		var _query_struct = {};
		if (_query_string != "") {
			var _query_params = string_split(_query_string, "&", true);
			
			array_foreach(_query_params, method(_query_struct, function(_query_param) {
				var _query_params_pair = string_split(_query_param, "=", false, 1);
				var _key = HttpServer.url_decode(_query_params_pair[0]);
				
				if (string_length(_key) > 0) {
					var _value = array_length(_query_params_pair) > 1 ? _query_params_pair[1] : undefined;
					_value = HttpServer.url_decode(_value);
					HttpServer.struct_set_multiple(self, _key, _value)
				}
			}));
		}
		
		return {
			parameters: _param_struct,
			query: _query_struct,
		};
	};
	
	/** Default handler for when path isn't found
	 * @param {Struct.HttpServerRequestContext} _context The incoming request context
	 * @ignore
	 */
	static __default_not_found_handler = function(_context) {
		_context.response.send_string(HttpServer.status_code_to_string(404), 404);	
	};
}
