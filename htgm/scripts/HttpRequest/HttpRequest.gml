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
	self.query = {};
	self.form = {};
	
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
	
	/** Gets whether a parameter exists
	 * @param {String} _key the name of the parameter to get
	 * @return {Bool}
	 */
	static has_parameter = function(_key) {
		return struct_exists(self.parameters, _key);
	};

	/** Gets a path paramete
	 * @param {String} _key the name of the query to get
	 * @return {Any}
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
	 * @return {Any}
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
	 * @return {Any}
	 */
	static get_form = function(_key) {
		return self.form[$ _key];
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
}
