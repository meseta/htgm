/**
 * An HTTP client that returns a Chain
 * You must run `cleanup()` to avoid a memory leak when this struct is no longer needed
 */
function HttpClient(_base_url="", _logger_name=undefined) constructor {
	/** the bound loger, making use of the global logger */
	self.logger = new Logger(_logger_name ?? "HttpClient", {base_url: _base_url});
	
	/** Base URL is prepended to all requests */
	self.__base_url = _base_url;
	
	/** The map used to maintain any headers that will be sent with all requests */
	self.__header_map = ds_map_create();
	
	/** Internal record of ongoing requests */
	self.__requests = {};
	
	/** Internal record of ongoing timeouts */
	self.__timeouts = new MinHeap();
	
	/** Timeout handler, runs every few frames */
	self.__call_later = call_later(10, time_source_units_frames, method(self, self.__step), true);
	
	/** This variable will eventuall hold a persistent ref to this method, without it, GC would get rid of the callback; the target object uses weakrefs. */
	self.__async_http_handler = undefined;
	static __register_async_handler = function() {
		if (is_undefined(self.__async_http_handler)) {
			self.__async_http_handler = method(self, self.__async_http);
			add_async_http_callback(self.__async_http_handler);	
		}
	}
	
	/** Run cleanup to clean up any dynamic resources. The client is inoperable after running this */
	static cleanup = function() {
		ds_map_destroy(self.__header_map);
		call_cancel(self.__call_later);
	};

	/** Set several headers in the client using a struct */
	static set_headers = function(_header_struct) {
		var _len = variable_struct_names_count(_header_struct);
		var _header_names = variable_struct_get_names(_header_struct);
		for (var _i; _i<_len; _i++) {
			var _header_name = _header_names[_i];
			self.__header_map[? _header_name] = _header_struct[$ _header_name];
		}
		return self;
	};
	
	/** Add a single header to the client */
	static add_header = function(_header_name, _header_value) {
		self.__header_map[? _header_name] = _header_value;
		return self;
	};
	
	/** Remove a header from the client */
	static remove_header = function(_header_name) {
		ds_map_delete(self.__header_map, _header_name);
		return self;
	};
	
	/** Getter for reading the base URL */
	static get_base_url = function() {
		return self.__base_url;
	}
	
	/** Setter for setting the base URL */
	static set_base_url = function(_url) {
		self.__base_url = _url;
	}
	
	/** Make an HTTP request. this method returns a Chain */
	static request = function(_http_method, _url, _body, _timeout=15, _result_raw=false) {
		// register the async callback if needed
		self.__register_async_handler();
		
		var _req_id = http_request(self.__base_url+_url, _http_method, self.__header_map, _body ?? "");
		
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
	
	/** Make an HTTP GET request. this method returns a Chain */
	static get = function(_url, _body=undefined, _timeout=15) {
		return self.request("GET", _url, _body, _timeout);	
	};
	
	/** Make an HTTP POST request. this method returns a Chain */
	static post = function(_url, _body=undefined, _timeout=15) {
		return self.request("POST", _url, _body, _timeout);	
	};
	
	/** Make an HTTP PUT request. this method returns a Chain */
	static put = function(_url, _body=undefined, _timeout=15) {
		return self.request("PUT", _url, _body, _timeout);	
	};
	
	/** Make an HTTP PATCH request. this method returns a Chain */
	static patch = function(_url, _body=undefined, _timeout=15) {
		return self.request("PATCH", _url, _body, _timeout);	
	};
	
	/** Make an HTTP DELETE request. this method returns a Chain */
	static del = function(_url, _body=undefined, _timeout=15) {
		return self.request("DELETE", _url, _body, _timeout);	
	};
	
	/** Convenience function for turning sypmbols into URL-safe entities*/
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
	
	static __step = function() {
		while (self.__timeouts.get_length()) {
			var _min_time = self.__timeouts.peek_min_priority();
			if(is_undefined(_min_time) || _min_time > get_timer()) {
				break;
			}
			var _req_id = self.__timeouts.pop_min_value();

			if (variable_struct_exists(self.__requests, _req_id)) {
				var _request = self.__requests[$ _req_id];
				self.logger.warning("Request timed out", {http_method: _request.http_method, url: _request.url, req_id: _req_id})
				if (is_method(_request.errback)) {
					_request.errback("Request timed out");	
				}
				else {
					throw "Request timed out";	
				}
				variable_struct_remove(self.__requests, _req_id);
			}
		}
	};
	
	static __async_http = function(_async_load) {
		var _req_id = _async_load[? "id"];
		if (!variable_struct_exists(self.__requests, _req_id)) {
			return false;
		}
		
		var _request = self.__requests[$ _req_id];
		variable_struct_remove(self.__requests, _req_id);
			
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
				else {
					throw "Request failed";
				}
			}
		}
			
		return true;
	};
}
