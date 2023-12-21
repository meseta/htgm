function ComponentNavigation(): HtmlComponent() constructor {
	static links = [
		new ComponentNavigationLink(ViewHome.path, "Home", ViewIndex.content_id, ViewIndex.path),
		new ComponentNavigationLink(ViewAbout.path, "About",  ViewIndex.content_id),
		new ComponentNavigationLink(ViewDocs.path, "Documentation",  ViewIndex.content_id),
	];
	
	static render = function(_context) {
		return @'
			<nav hx-boost="true" class="container-fluid" style="height: 3.5em; border-bottom: 1px solid var(--primary); padding-left: 0px;">
				<div>
					<img src="/images/sLogo.png" alt="" style="height: 100%; padding-right: 0.5em;" />
					<strong>'+ ViewIndex.title +@' </strong>
				</div>
				<ul>
					'+ HtmlComponent.render_array(self.links, "", _context) + @'
				</ul>
			</nav>
		';
	};
}
