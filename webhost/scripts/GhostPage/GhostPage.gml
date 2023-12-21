function GhostPage(): HtmxView() constructor {
	static ghost_slug = undefined;
	static path = "";
	static cached = undefined;
	
	static render = function(_context) {
		if (!is_undefined(self.cached)) {
			return self.cached;	
		}
		
		return global.clients.ghost.get_page(self.ghost_slug)
			.chain_callback(function(_result) {
				if (!is_array(_result[$ "pages"]) || array_length(_result[$ "pages"]) < 1) {
					throw new ExceptionHttpNotFound();	
				}
				var _page = _result.pages[0];
				self.cached = @'
					<section>
						<h1>'+ string(_page.title)+ @'</h1>
						'+ string(_page.html) + @'
					</section>
				';
				return self.cached;
			})
	};
}
