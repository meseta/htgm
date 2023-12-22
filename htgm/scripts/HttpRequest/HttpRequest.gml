/** An HTTP request 
 * @param {String} _method The request method
 * @param {String} _path The request path
 */
function HttpRequest(_method, _path) constructor {
	self.method = _method;
	self.path = _path;
	self.path_original = _path;
	
	self.keep_alive = true;
	self.headers = {};
	self.data = -1;
	self.parameters = {};
	
	/** Clean up dynamic resources */
	static cleanup = function() {
		if (buffer_exists(self.data)) {
			buffer_delete(self.data);	
		}
	};
	
	/** Sets the path for redirects (will leave path_original the same)
	 * @param {String} _path The new path
	 * @return {Struct.HttpRequest}
	 */
	static set_path = function(_path) {
		self.path = _path;
		return self;
	};
	
	/** Sets the request body data
	 * @param {Id.Buffer} _buffer The buffer to set the data for
	 * @return {Struct.HttpRequest}
	 */
	static set_data = function(_buffer) {
		self.data = _buffer;
		return self;
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
	 * @return {Any}
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
		return self;
	};
	
	/** Gets a parameter, returning either string or undefined
	 * @param {String} _key the name of the header to get
	 * @return {Any}
	 */
	static get_parameter = function(_key) {
		return self.parameters[$ string_lower(_key)];
	};
	
	/** Sets parameters, sets the parameters
	 * @param {Struct} _parameters All the parameters to set
	 * @return {Struct.HttpRequest}
	 */
	static set_parameters = function(_parameters) {
		self.parameters = _parameters;
		return self;
	};
}
