function ComponentNavigation(): HtmlComponent() constructor {
	static render = function(_context) {
		static _links = [
			new ComponentNavigationLink(ViewIndex.content_id, ViewHome.path, "Home", ViewIndex.path),
			new ComponentNavigationLink(ViewIndex.content_id, ViewAbout.path, "About"),
			new ComponentNavigationLink(ViewIndex.content_id, ViewDocs.path, "Usage Guide"),
		];
	
		return @'
			<nav hx-boost="true" class="container-fluid" style="height: 3.5em; border-bottom: 1px solid var(--primary); padding-left: 0px;">
				<div>
					<img src="/images/sLogo.png" alt="" style="height: 100%; padding-right: 0.5em;" />
					<strong>'+ ViewIndex.title +@' </strong>
				</div>
				<ul>
					'+ HtmlComponent.render_array(_links, "", _context) + @'
					<li><a href="https://github.com/meseta/htgm/releases" class="secondary" target="_blank">Download</a></li>
				</ul>
			</nav>
		';
	};
}
