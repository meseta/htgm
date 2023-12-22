function ComponentDocsNavigation(): HtmlComponent() constructor {
	static render = function(_context) {
		static _links_1 = [
			new ComponentNavigationLink(ViewDocs.content_id, ViewDocsGettingStarted.path, "Getting Started", ViewDocs.path),
		];
	
		static _links_2 = [
			new ComponentNavigationLink(ViewDocs.content_id, ViewDocsPaths.path, "Paths"),
			new ComponentNavigationLink(ViewDocs.content_id, ViewDocsStaticFiles.path, "Static Files and Sprites"),
			new ComponentNavigationLink(ViewDocs.content_id, ViewDocsComponents.path, "Reusable Components"),
			//new ComponentNavigationLink(ViewDocs.content_id, ViewDocsPages.path, "Htmx Views"),
			//new ComponentNavigationLink(ViewDocs.content_id, ViewDocsPages.path, "Caching and Metadata"),
		];
		
		static _links_3 = [
			new ComponentNavigationLink(ViewDocs.content_id, ViewDocsDynamicPaths.path, "Dynamic Paths"),
			//new ComponentNavigationLink(ViewDocs.content_id, ViewDocsPages.path, "Response Types"),
			// new ComponentNavigationLink(ViewDocs.content_id, ViewDocsAddingPage.path, "Websockets"),
		];
	
		return @'
			<nav hx-boost="true">
				<ul>
					'+ HtmlComponent.render_array(_links_1, "", _context) + @'
				</ul>
				<br />
				<b>Building a website</b>
				<ul>
					'+ HtmlComponent.render_array(_links_2, "", _context) + @'
				</ul>
				<br />
				<b>Building an API</b>
				<ul>
					'+ HtmlComponent.render_array(_links_3, "", _context) + @'
				</ul>
			</nav>
		';
	};
}

