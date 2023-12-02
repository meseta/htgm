function SiteNavigation(): HtmxComponent() constructor {
	static links = [
		new SiteNavigationLink(HtmxPage1.path, "Change 1"),
		new SiteNavigationLink(HtmxPage2.path, "Change 2"),
	];
	
	static render = function(_context) {
		return dedent(@'
			<nav hx-boost="true" class="container-fluid">
			  <ul>
			    <li><strong>'+ SiteMain.title +@' </strong></li>
			  </ul>
			  <ul>
				'+ HtmxComponent.render_array(self.links, undefined, _context) + @'
			  </ul>
			</nav>
		');
	};
}

function SiteNavigationLink(_path, _text): HtmxComponent() constructor {
	self.path = _path;
	self.text = _text;
	static link_class = self.auto_id("link");
	
	static render = function(_context) {
		return dedent(@'
			<li>
				<a
				 hx-on="click: htmx.findAll(`.'+self.link_class+ @'`).forEach((el) => htmx.addClass(el, `outline`)); htmx.removeClass(this, `outline`);"
				 hx-target="#'+ SiteMain.content_id +@'"
				 href="'+ self.path +@'"
				 role="button"
				 class="'+ self.link_class + (self.path==_context.request.path_original ? "" : " outline") +@'"
				>
					'+ self.text +@'
				</a>
			</li>
		');
	}
}

function HtmxSprite(_sprite): HtmxComponent() constructor {
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