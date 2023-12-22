/** An HTML image that is actually a gamemaker sprite
 * @param {Asset.GMSprite} _sprite A gamemaker sprite index
 */
function HtmlSprite(_sprite): HtmlComponent() constructor {
	static _generated = {}; // keep track of generated images
	
	var _image_name = sprite_get_name(_sprite);
	var _filename = $"images/{_image_name}.png";
		
	self.image_tag = _generated[$ _filename];
	if (is_undefined(self.image_tag)) {
		if (asset_get_type(_image_name) != asset_sprite) {
			throw new ExceptionHttpNotFound($"Image {_image_name} not found");
		}
		
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

		var _buffer = buffer_load(_filename);
		self.image_tag = @'<img src="data:image/jpeg;base64,'+buffer_base64_encode(_buffer, 0, buffer_get_size(_buffer))+@'" />';
		buffer_delete(_buffer);
		_generated[$ _filename] = self.image_tag;
	}
	
	static render = function(_context) {
		return self.image_tag;
	}
}