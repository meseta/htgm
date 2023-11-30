/**
 * @desc An HTTP response
 * @param {Function} _end_function a callback to call when the the respones is done sending
 * @param {Bool} _header_only whether the response should be only headers
 * @param {Bool} _compress whether the response should be compressed using deflate/zlib
**/
function HttpResponse(_end_function, _header_only=false, _compress=false) constructor {
	// Handles an HTTP response

	/* @ignore */ self.__end_function = _end_function;
	/* @ignore */ self.__headers = {};
	/* @ignore */ self.__response_data_buffer = -1;
	/* @ignore */ self.__network_buffer = -1;
	/* @ignore */ self.__status_code = 405;
	/* @ignore */ self.__dirty = true;
	/* @ignore */ self.__delete_buffer_on_cleanup = false;
	/* @ignore */ self.__header_only = _header_only;
	/* @ignore */ self.__compress = _compress;
	
	/**
	 * @desc Clean up dynamic resources
	**/
	static cleanup = function() {
		if (self.__delete_buffer_on_cleanup && buffer_exists(self.__response_data_buffer)) {
			buffer_delete(self.__response_data_buffer);	
			self.__response_data_buffer = -1;
		}
		if (buffer_exists(self.__network_buffer)) {
			buffer_delete(self.__network_buffer);
			self.__network_buffer = -1;
		}
	};

	/**
	 * @desc Set status code to be returned in response
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	**/
	static set_status = function(_status_code) {
		self.__status_code = _status_code
		self.__dirty = true;
		return self;
	};
	
	/**
	 * @desc Set a header to be returned in response
	 * @param {string} _header HTTP header key
	 * @param {string} _value HTTP header value
	 * @return {Struct.HttpResponse}
	**/
	static set_header = function(_header, _value) {
		self.__headers[$ _header] = _value;
		self.__dirty = true;
		return self;
	};
	
	/**
	 * @desc Send a file
	 * @param {string} _filename Path to file
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	**/
	static send_file = function(_filename, _status_code=200) {
		if (buffer_exists(self.__response_data_buffer)) {
			throw "HttpResponse already has data, can't add another buffer";	
		}
		self.__status_code = _status_code;
		var _buffer = buffer_load(_filename);
		self.__headers[$ "Content-Type"] = HttpServer.filename_to_mimetype(_filename);
		self.__set_buffer_response(_buffer, true);
		return self;
	};
	
	/**
	 * @desc Send a string
	 * @param {string} _string Path to file
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	**/
	static send_string = function(_string, _status_code=200) {
		if (buffer_exists(self.__response_data_buffer)) {
			throw "HttpResponse already has data, can't add another buffer";	
		}
		self.__status_code = _status_code;
		var _buff = buffer_create(string_byte_length(_string), buffer_fixed, 1);
		buffer_write(_buff, buffer_text, _string);
		self.__set_buffer_response(_buff, true);
		return self;
	};
	
	/**
	 * @desc Send a struct or array or other serializable value as a JSON
	 * @param {Any} _serializable JSON serializable value to send
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	**/
	static send_json = function(_serializable, _status_code=200) {
		self.__status_code = _status_code;
		self.__headers[$ "Content-Type"] = "application/json";
		return self.send_string(json_stringify(_serializable))
	};

	/**
	 * @desc Send nothing (204 response)
	 * @param {Real} _status_code HTTP status code
	 * @return {Struct.HttpResponse}
	**/
	static send_empty = function(_status_code=204) {
		self.__status_code = _status_code;
		if (buffer_exists(self.__response_data_buffer)) {
			buffer_delete(self.__response_data_buffer);
			self.__response_data_buffer = -1;	
		}
		self.__dirty = true;
		self.__end_function();
		return self;
	};

	/**
	 * @desc Fetch or generate the buffer to be sending
	 * @return {Id.Buffer}
	**/
	static get_send_buffer = function() {
		if (buffer_exists(self.__network_buffer) && self.__dirty == false) {
			return self.__network_buffer;
		}
		
		if (buffer_exists(self.__network_buffer)) {
			buffer_delete(self.__network_buffer);	
		}
		
		var _response = {
			top_matter: $"HTTP/1.1 {self.__status_code} {HttpServer.status_code_to_string(self.__status_code)}\r\n" + 
				$"Date: {self.__rfc_date_now()}\r\n" +
				$"Server: {game_display_name} {GM_version} (GameMaker/{GM_runtime_version})\r\n"
		};
		
		struct_foreach(self.__headers, method(_response, function(_key, _value) {
			/// Feather ignore GM1010
			top_matter += $"{_key}: {_value}\r\n";
		}));
		
		_response.top_matter += "\r\n";
		
		if (!buffer_exists(self.__response_data_buffer) or self.__header_only) {
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
	
	/**
	 * @desc Get the number of bytes in the response
	 * @return {Real}
	**/
	static get_send_size = function() {
		return buffer_get_size(self.get_send_buffer());
	};
	
	/**
	 * @desc Get the status code
	 * @return {Real}
	**/
	static get_status_code = function() {
		return self.__status_code;
	};
	
	
	/**
	 * @desc Sets the buffer as the response
	 * @param {Id.Buffer} _buffer The bufer to set as response
	 * @param {Bool} _delete_buffer_on_cleanup whether to delete the buffer on cleanup
	 * @ignore
	**/
	static __set_buffer_response = function(_buffer, _delete_buffer_on_cleanup=false) {
		if (buffer_exists(self.__response_data_buffer)) {
			throw new ExceptionHttpInternal("HttpResponse already has data, can't add another buffer");
		}
		
		var _size = buffer_get_size(_buffer);
		if (self.__compress && _size > 300) { // size above which we will compress
			self.__headers[$ "Content-Encoding"] = "deflate";
			var _compressed_buffer = buffer_compress(_buffer, 0, _size);
			buffer_delete(_buffer);
			_buffer = _compressed_buffer;
			_size = buffer_get_size(_compressed_buffer);
		}
		
		self.__headers[$ "Content-Length"] = _size;	
		self.__delete_buffer_on_cleanup = _delete_buffer_on_cleanup;
		self.__response_data_buffer = _buffer;
		self.__dirty = true;
		self.__end_function();
	};
	
	/**
	 * @desc Get the current correctly formatted date
	 * @return {String}
	 * @ignore
	**/
	static __rfc_date_now = function() {
		var _prev_timezone = date_get_timezone();
		date_set_timezone(timezone_utc);
		
		var _str = self.__rfc_date(date_current_datetime());
		
		date_set_timezone(_prev_timezone);
		return _str;
	};
	
	/**
	 * @desc Get the correctly formatted date for a given gamemaker datetime
	 * @return {Real} _datetime the datetime in Gamemaker format (e.g. date_current_datetime());
	 * @return {String}
	 * @ignore
	**/
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
	
	/**
	 * @desc Pad a number zeros
	 * @return {Real} _number The number to pad
	 * @return {Real} _places How many places to pad to
	 * @return {String}
	 * @ignore
	**/
	static __zero_pad_string = function(_number, _places) {
		return string_replace(string_format(_number, _places, 0), " ", "0");
	};
}
