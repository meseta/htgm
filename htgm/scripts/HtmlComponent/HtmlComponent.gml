/** Base constructor for a Component */
function HtmlComponent() constructor {
	/** Generate an ID based on the struct instance automatically
	 * @param {String} _id_prefix Custom ID prefix
	 */
	static auto_id = function(_id_prefix=undefined) {
		return is_undefined(_id_prefix) ? instanceof(self) : $"{_id_prefix}-{instanceof(self)}";
	}
	
	/** The render function for rendering this component
	 * @param {Struct.HttpServerRequestContext} _context The incoming request context
	 * @return {String}
	 */
	static render = function(_context) { return ""; };

	/** Utility function for rendering an array of components
	 * @param {Array<Struct.HtmlComponent>} _array The array of components to loop over
	 * @param {String} _delimiter The delimiter to insert between components
	 * @param {Struct.HttpServerRequestContext} _context The incoming request context
	 * @return {String}
	*/
	static render_array = function(_array, _delimiter, _context) {
		return string_join_ext(
			_delimiter,
			array_map(_array, method(_context, function(_component) {
				return _component.render(self);
			})),
		);
	};
}
