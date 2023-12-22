/** A HTTP client that returns a Chain
 * You must run cleanup() to avoid a memory leak when this struct is no longer needed
 * @param {String*} _base_url The base url used for every request
 * @param {String*} _logger_name The name the internal logger will use
 * @param {Struct.Logger*} _parent_logger A parent logger to use
 * @author Meseta https://meseta.dev
 */
function HttpClient(_base_url="", _logger_name="HttpClient", _parent_logger=undefined) constructor {
	if (!is_undefined(_parent_logger)) {
		self.logger = _parent_logger.bind_named(_logger_name, {base_url: _base_url});
	}
	else {
		self.logger = new Logger(_logger_name, {base_url: _base_url});
	}
	
	/* @ignore */ self.__base_url = _base_url;
	/* @ignore */ self.__headers = {};
	/* @ignore */ self.__requests = {};
	/* @ignore */ self.__timeouts = new MinHeap();
	/* @ignore */ self.__call_later = call_later(10, time_source_units_frames, method(self, self.__step), true);
	/* @ignore */ self.__async_http_handler = undefined;
	
	/** Run cleanup to clean up any dynamic resources. The client is inoperable after running this */
	static cleanup = function() {
		call_cancel(self.__call_later);
	};

	/** Set several headers in the client using a struct
	 * @param {Struct} _header_struct
	 * @return {Struct.HttpClient}
	 */
	static set_headers = function(_header_struct) {
		struct_foreach(_header_struct, function(_header_name, _header_value) {
			self.__headers[$ _header_name] = string(_header_value);
		});
		return self;
	};
	
	/** Add a single header to the client
	 * @param {String} _header_name
	 * @param {String} _header_value
	 * @return {Struct.HttpClient}
	 */
	static add_header = function(_header_name, _header_value) {
		self.__headers[$ _header_name] = string(_header_value);
		return self;
	};
	
	/** Remove a header from the client 
	 * @param {String} _header_name
	 * @return {Struct.HttpClient}
	 */
	static remove_header = function(_header_name) {
		struct_remove(self.__headers, _header_name);
		return self;
	};
	
	/** Getter for reading the base URL 
	 * @return {String}
	 */
	static get_base_url = function() {
		return self.__base_url;
	}
	
	/** Setter for setting the base URL 
	 * @param {String} _url Base URL to set
	 * @return {Struct.HttpClient}
	 */
	static set_base_url = function(_url) {
		self.__base_url = _url;
		return self;
	}

	/** Make an HTTP request. this method returns a Chain 
	 * @param {String} _http_method Http Method, e.g "GET", "POST"
	 * @param {String} _url URL, this is appendend to the base URL
	 * @param {String|Struct*} _body Body of request, can be undefined or blank
	 * @param {Number*} _timeout Timeout for request in seconds
	 * @param {Bool*} _result_raw Whether to return raw result and headers or attempt to decode it
	 * @return {Struct.Chain}
	 */
	static request = function(_http_method, _url, _body=undefined, _timeout=15, _result_raw=false) {
		// register the async callback if needed
		self.__register_async_handler();
		
		var _header_map = json_decode(json_stringify(self.__headers));
		
		// handle json body
		if (is_struct(_body)) {
			_body = json_stringify(_body);
			_header_map[? "Content-Type"] = "application/json";
		}
		
		var _req_id = http_request(self.__base_url+_url, _http_method, _header_map, _body ?? "");
		ds_map_destroy(_header_map);
		
		var _expiry = get_timer() + _timeout*1000000;
		
		var _chain = new Chain();
		self.__requests[$ _req_id] = {
			http_method: _http_method,
			url: _url,
			callback: _chain.create_start_callback(),
			errback: _chain.create_errback(),
			expiry: _expiry,
			result_raw: _result_raw,
		};
		
		if (_timeout > 0) {
			self.__timeouts.insert(_req_id, _expiry);
		}
		
		return _chain;
	};
	
	/** Make an HTTP GET request. this method returns a Chain
	 * @param {String} _url URL, this is appendend to the base URL
	 * @param {String|Struct*} _body Body of request, can be undefined or blank
	 * @param {Number*} _timeout Timeout for request in seconds
	 * @return {Struct.Chain}
	 */
	static get = function(_url, _body=undefined, _timeout=15) {
		return self.request("GET", _url, _body, _timeout);	
	};
	
	/** Make an HTTP POST request. this method returns a Chain 
	 * @param {String} _url URL, this is appendend to the base URL
	 * @param {String|Struct*} _body Body of request, can be undefined or blank
	 * @param {Number*} _timeout Timeout for request in seconds
	 * @return {Struct.Chain}
	 */
	static post = function(_url, _body=undefined, _timeout=15) {
		return self.request("POST", _url, _body, _timeout);	
	};
	
	/** Make an HTTP PUT request. this method returns a Chain 
	 * @param {String} _url URL, this is appendend to the base URL
	 * @param {String|Struct*} _body Body of request, can be undefined or blank
	 * @param {Number*} _timeout Timeout for request in seconds
	 * @return {Struct.Chain}
	 */
	static put = function(_url, _body=undefined, _timeout=15) {
		return self.request("PUT", _url, _body, _timeout);	
	};
	
	/** Make an HTTP PATCH request. this method returns a Chain 
	 * @param {String} _url URL, this is appendend to the base URL
	 * @param {String|Struct*} _body Body of request, can be undefined or blank
	 * @param {Number*} _timeout Timeout for request in seconds
	 * @return {Struct.Chain}
	 */
	static patch = function(_url, _body=undefined, _timeout=15) {
		return self.request("PATCH", _url, _body, _timeout);	
	};
	
	/** Make an HTTP DELETE request. this method returns a Chain 
	 * @param {String} _url URL, this is appendend to the base URL
	 * @param {String|Struct*} _body Body of request, can be undefined or blank
	 * @param {Number*} _timeout Timeout for request in seconds
	 * @return {Struct.Chain}
	 */
	static del = function(_url, _body=undefined, _timeout=15) {
		return self.request("DELETE", _url, _body, _timeout);	
	};
	
	/** Convenience function for turning sypmbols into URL-safe entities
	 * @param {String} _str Input string
	 * @return {String}
	 */
	static url_encode = function(_str) {
		static _html_entities = [
			"%00", "%01", "%02", "%03", "%04", "%05", "%06", "%07", "%08", "%09", "%0a", "%0b", "%0c", "%0d", "%0e", "%0f",
			"%10", "%11", "%12", "%13", "%14", "%15", "%16", "%17", "%18", "%19", "%1a", "%1b", "%1c", "%1d", "%1e", "%1f", 
			"%20",   "!", "%22", "%23", "%24", "%25", "%26",   "'",   "(",   ")",   "*", "%2b", "%2c",   "-",   ".", "%2f", 
			  "0",   "1",   "2",   "3",   "4",   "5",   "6",   "7",   "8",   "9", "%3a", "%3b", "%3c", "%3d", "%3e", "%3f", 
			"%40",   "A",   "B",   "C",   "D",   "E",   "F",   "G",   "H",   "I",   "J",   "K",   "L",   "M",   "N",   "O",
			  "P",   "Q",   "R",   "S",   "T",   "U",   "V",   "W",   "X",   "Y",   "Z", "%5b", "%5c", "%5d", "%5e",   "_", 
			"%60",   "a",   "b",   "c",   "d",   "e",   "f",   "g",   "h",   "i",   "j",   "k",   "l",   "m",   "n",   "o",
			  "p",   "q",   "r",   "s",   "t",   "u",   "v",   "w",   "x",   "y",   "z",  "%7b", "%7c", "%7d",  "~", "%7f", 
			"%80", "%81", "%82", "%83", "%84", "%85", "%86", "%87", "%88", "%89", "%8a", "%8b", "%8c", "%8d", "%8e", "%8f", 
			"%90", "%91", "%92", "%93", "%94", "%95", "%96", "%97", "%98", "%99", "%9a", "%9b", "%9c", "%9d", "%9e", "%9f", 
			"%a0", "%a1", "%a2", "%a3", "%a4", "%a5", "%a6", "%a7", "%a8", "%a9", "%aa", "%ab", "%ac", "%ad", "%ae", "%af", 
			"%b0", "%b1", "%b2", "%b3", "%b4", "%b5", "%b6", "%b7", "%b8", "%b9", "%ba", "%bb", "%bc", "%bd", "%be", "%bf", 
			"%c0", "%c1", "%c2", "%c3", "%c4", "%c5", "%c6", "%c7", "%c8", "%c9", "%ca", "%cb", "%cc", "%cd", "%ce", "%cf", 
			"%d0", "%d1", "%d2", "%d3", "%d4", "%d5", "%d6", "%d7", "%d8", "%d9", "%da", "%db", "%dc", "%dd", "%de", "%df", 
			"%e0", "%e1", "%e2", "%e3", "%e4", "%e5", "%e6", "%e7", "%e8", "%e9", "%ea", "%eb", "%ec", "%ed", "%ee", "%ef", 
			"%f0", "%f1", "%f2", "%f3", "%f4", "%f5", "%f6", "%f7", "%f8", "%f9", "%fa", "%fb", "%fc", "%fd", "%fe", "%ff",
		]

		var _encoded = "";
		var _count = string_length(_str);
		for (var _i=1; _i<=_count; _i++) {
		    var _char = string_byte_at(_str, _i);
			_encoded += _html_entities[_char];
		}
		return _encoded;
	};
		
	/** Register the async handler, using AsyncWrapper
	 * @ignore
	 */ 
	static __register_async_handler = function() {
		if (is_undefined(self.__async_http_handler)) {
			self.__async_http_handler = method(self, self.__async_http);
			AsyncWrapper.add_async_http_callback(self.__async_http_handler);	
		}
	}
	
	/** A function that will be run every step to check timeout values
	 * @ignore
	 */ 
	static __step = function() {
		while (self.__timeouts.get_length()) {
			var _min_time = self.__timeouts.peek_min_priority();
			if(is_undefined(_min_time) || _min_time > get_timer()) {
				break;
			}
			var _req_id = self.__timeouts.pop_min_value();

			if (struct_exists(self.__requests, _req_id)) {
				var _request = self.__requests[$ _req_id];
				self.logger.warning("Request timed out", {http_method: _request.http_method, url: _request.url, req_id: _req_id})
				if (is_method(_request.errback)) {
					_request.errback("Request timed out");	
				}
				else {
					throw "Request timed out";	
				}
				struct_remove(self.__requests, _req_id);
			}
		}
	};
	
	/** The Async HTTP callback that will be run from async-http event
	 * @ignore
	 */ 
	static __async_http = function(_async_load) {
		var _req_id = _async_load[? "id"];
		if (!struct_exists(self.__requests, _req_id)) {
			return false;
		}
		
		var _request = self.__requests[$ _req_id];
		struct_remove(self.__requests, _req_id);
			
		var _status = _async_load[? "status"];
		var _http_status = _async_load[? "http_status"];
			
		if (_request.result_raw) {
			// full result array
			var _headers = _async_load[? "response_headers"];
			_request.callback([_async_load[? "result"], _http_status, _status, _headers]);
		}
		else {
			// GM weirdness at Runtime v2022.3.0.497. It's possible for http to fail but return 200 status
			// Also, non 200 returns status -1.
			// It seems the only way to be reliable is for the special case of 200, check status. but any non 200 is probably okay
			
			if ((_status >= 0 && _http_status == 200) || (_http_status > 200 && _http_status < 300)) {
				var _headers = _async_load[? "response_headers"];

				// decode json if headers is such
				var _content_type = _headers[? "content-type"] ?? (_headers[? "Content-Type"] ?? "");
				if (string_pos("application/json", _content_type) == 1) {
					try {
						var _struct = json_parse(_async_load[? "result"]);
					}
					catch (_err) {
						_request.errback(_err);	
					}
					_request.callback(_struct);
				}
				else {
					_request.callback(_async_load[? "result"]);
				}
			}
			else {
				self.logger.warning("Request failed", {status: _status, http_status: _http_status, http_method: _request.http_method, url: _request.url, req_id: _req_id})
				if (is_method(_request.errback)) {
					_request.errback(_http_status);
				}
			}
		}
		
		if (struct_names_count(self.__requests)) {
			// we're not done handling, there's more requests!
			return false;
		}
		else {
			// we're done handling, remove ourselves from the HTTP wrapper
			self.__async_http_handler = undefined;
			return true;
		}
	};
}
