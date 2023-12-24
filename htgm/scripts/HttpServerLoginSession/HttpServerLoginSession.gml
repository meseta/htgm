/** An HTTP login session that can contain data 
 * @param {String} _session_id the Session ID
 * @param {Real} _expire_seconds How long the session lasts, in seconds
 */
function HttpServerLoginSession(_session_id, _expire_seconds) constructor {
	self.session_id = _session_id;
	self.__session_data = {};
	self.__creation_time = date_current_datetime();
	self.__expiry_time = 0;
	self.extend(_expire_seconds);
	
	/** Checks if a sesson data exists
	 * @return {Bool}
	 */
	static has = function(_key) {
		return struct_exists(self.__session_data, _key);
	};
	
	/** Gets some session data
	 * @param {String} _key
	 * @return {Any}
	 */
	static get = function(_key) {
		return self.__session_data[$ _key];
	};
	
	/** Sets som esession data
	 * @param {String} _key
	 * @param {Any} _value
	 */
	static set = function(_key, _value) {
		self.__session_data[$ _key] = _value;
	};
	
	/** Whether expired
	 * @return {Bool}
	 */
	static is_valid = function() {
		return  date_current_datetime() < self.__expiry_time
	};
	
	/** Sets expiry
	 * @param {Real} _expire_seconds How long the session lasts, in seconds
	 */
	static extend = function(_expire_seconds) {
		self.__expiry_time = date_current_datetime() + _expire_seconds/(24*3600);
	};
}
