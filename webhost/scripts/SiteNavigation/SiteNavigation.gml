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
	
	static render = function(_context) {
		return dedent(@'
			<li>
				<a
				 hx-on="click: document.querySelectorAll(`nav ul li a`).forEach((el) => el.classList.add(`outline`)); this.classList.remove(`outline`);"
				 hx-target="#'+ SiteMain.content_id +@'"
				 href="'+ self.path +@'"
				 role="button"
				 class="'+  (self.path==_context.request.path_original ? "" : "outline") +@'"
				>
					'+ self.text +@'
				</a>
			</li>
		');
	}
}