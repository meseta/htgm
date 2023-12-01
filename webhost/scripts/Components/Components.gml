function HtmxNavigation(): HtmxComponent() constructor {
	static links = [
		new HtmxNavigationLink(HtmxPage1.path, "Change 1"),
		new HtmxNavigationLink(HtmxPage2.path, "Change 2"),
	];
	
	static render = function(_context) {
		static cached = dedent(@'
			<div hx-boost="true">
				'+ HtmxComponent.render_array(self.links, "<br />", _context) + @'
			</div>
		');
		return cached;
	};
}

function HtmxNavigationLink(_path, _text): HtmxComponent() constructor {
	self.path = _path;
	self.text = _text;
	
	static render = function() {
		return $"<a hx-target='#{HtmxMain.content_id}' href='{self.path}'>{self.text}</a>";
	}
}