function ComponentDocsNavigation(): HtmlComponent() constructor {
	static links = [
		new ComponentNavigationLink(ViewDocs1.path, "Docs1", ViewDocs.content_id, ViewDocs.path),
		new ComponentNavigationLink(ViewDocs2.path, "Docs2", ViewDocs.content_id),
	];
	
	static render = function(_context) {
		return @'
				<nav hx-boost="true">
					<ul>
						'+ HtmlComponent.render_array(self.links, "", _context) + @'
					</ul>
				</nav>
		';
	};
}

