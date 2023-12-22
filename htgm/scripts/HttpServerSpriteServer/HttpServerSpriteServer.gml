/** A server for serving sprites from inside game assets
 * @param {String} _parameter_name The parameter name inside the path to use
 */
function HttpServerSpriteServer(_parameter_name) constructor {
	static max_age = 3600; // max age of cache
	
	/* @ignore */ self.__parameter_name = _parameter_name;
	
	/** Handle function for processing a request
	 * @param {Struct.HttpServerRequestContext} _context The incoming request contex
	 */
	static handler = function(_context) {
		if (_context.request.method != "GET") {
			throw new ExceptionHttpMethodNotAllowed()
			return;
		}
					
		static _generated = {}; // keep track of generated images
		
		var _image_name = _context.request.parameters[$ self.__parameter_name];
		var _filename = $"images/{_image_name}.png";
		
		if (!struct_exists(_generated, _filename)) {
			if (asset_get_type(_image_name) != asset_sprite) {
				throw new ExceptionHttpNotFound($"Image {_image_name} not found");
			}
		
			var _sprite = asset_get_index(_image_name);
			// create surface
			var _width = sprite_get_width(_sprite);
			var _height = sprite_get_height(_sprite);
		
			var _surface = surface_create(_width, _height);
			surface_set_target(_surface);
			draw_clear_alpha(c_black, 0);
			draw_sprite_stretched(_sprite, 0, 0, 0, _width, _height);
			surface_reset_target();
		
			surface_save(_surface, _filename);
			surface_free(_surface);
			_generated[$ _filename] = true;
		}
		
		// read and return the image
		_context.response.set_should_cache(true);
		_context.response.send_file(_filename);
	};
}
