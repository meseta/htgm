/** A buffer that can return one line of string at a time */
function HttpServerLineBuffer() constructor {
	self.__buffer = -1;
	
	/** Add a buffer to the data in this buffer
	 * @param {Id.Buffer} _incoming_buffer existing buffer to use
	 * @param {Real} _incoming_size bytes incoming
	 */
	static concatenate = function(_incoming_buffer, _incoming_size) {
		if (buffer_exists(self.__buffer)) {
			var _old_size = buffer_get_size(self.__buffer)
			var _new_size = _old_size + _incoming_size;
			buffer_resize(self.__buffer, _new_size);
			buffer_copy(_incoming_buffer, 0, _incoming_size, self.__buffer, _old_size);
		}
		else {
			var _new_size = _incoming_size;
			self.__buffer = buffer_create(_new_size, buffer_fast, 1);
			buffer_copy(_incoming_buffer, 0, _incoming_size, self.__buffer, 0);
		}
	};
	
	/** Whether buffer has data in it
	 * @return {Bool}
	 */
	static has_data = function(_amount=1) {
		if (buffer_exists(self.__buffer)) {
			return buffer_get_size(self.__buffer) - buffer_tell(self.__buffer) >= _amount;
		}
		return false;
	};
	
	/** Returns buffer tell
	 * @return {Real}
	 */
	static tell = function() {
		if (buffer_exists(self.__buffer)) {
			return buffer_tell(self.__buffer);
		}
		return -1;
	};
	
	/** Cleanup resources */
	static cleanup = function() {
		if (buffer_exists(self.__buffer)) {
			buffer_delete(self.__buffer);
			self.__buffer = -1;
		}
	};
	
	/** Read a line of text from the buffer
	 * @return {Any}
	 */
	static read_line = function() {
		if (!buffer_exists(self.__buffer)) return undefined;
		
		var _original_position = buffer_tell(self.__buffer);
		var _read_len = buffer_get_size(self.__buffer) - _original_position;
		var _last_byte = undefined;
		
		for (var _i=0; _i<_read_len; _i++) {
			var _byte = buffer_read(self.__buffer, buffer_u8);
			if (_byte == 0 or (_last_byte == 13 and _byte == 10)) {
				var _len = _i - 1;
				if (_len <= 0) return "";
				
				// copy buffer to temp buffer to read all of it into a string
				var _temp_buff = buffer_create(_len, buffer_fixed, 1);
				buffer_copy(self.__buffer, _original_position, _len, _temp_buff, 0);
				var _str = buffer_read(_temp_buff, buffer_string);
				buffer_delete(_temp_buff);
				
				return _str;
			}
			_last_byte = _byte;
		}
		
		// no return, return to original position
		buffer_seek(self.__buffer, buffer_seek_start, _original_position);
		return undefined;
	};
	
	/** Read a u8 from the buffer
	 * @return {Real}
	 */
	static read_byte = function() {
		return buffer_read(self.__buffer, buffer_u8);
	};
	
	/** Read some amount of bytes and return as a buffer
	 * @return {Id.Buffer}
	 */
	static read_length_to_buffer = function(_read_len) {
		if (!buffer_exists(self.__buffer) || buffer_get_size(self.__buffer) < buffer_tell(self.__buffer) + _read_len) return -1;
		
		var _original_position = buffer_tell(self.__buffer);
		var _out_buffer = buffer_create(_read_len, buffer_fixed, 1);
		buffer_copy(self.__buffer, _original_position, _read_len, _out_buffer,0);
		buffer_seek(self.__buffer, buffer_seek_start, _original_position + _read_len);
		
		return _out_buffer;
	};
}