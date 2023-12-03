function ComponentNavigation(): HtmlComponent() constructor {
	static links = [
		new ComponentNavigationLink(ViewHome.path, "Home", true),
	];
	
	static render = function(_context) {
		return dedent(@'
			<nav hx-boost="true" class="container-fluid" style="height: 3.5em; border-bottom: 1px solid var(--primary); padding-left: 0px;">
				<div>
					<img src="/images/sLogo.png" alt="" style="height: 100%; padding-right: 0.5em;" />
					<strong>'+ ViewIndex.title +@' </strong>
				</div>
				<ul>
					'+ HtmlComponent.render_array(self.links, "", _context) + @'
				</ul>
			</nav>
		');
	};
}

/**
 * @param {String} _path
 * @param {String} _text
 * @param {Bool} _is_main
 */
function ComponentNavigationLink(_path, _text, _is_main=false): HtmlComponent() constructor {
	self.path = _path;
	self.text = _text;
	self.is_main = _is_main;
	
	static link_class = self.auto_id("link");
	
	static render = function(_context) {
		var _is_on_page = (self.path == _context.request.path_original) || (self.is_main && _context.request.path_original == "");
		return quote_fix(dedent(@'
			<li>
				<a
				 hx-on="click: htmx.findAll(`.'+self.link_class+ @'`).forEach((el) => htmx.addClass(el, `secondary`)); htmx.removeClass(this, `secondary`);"
				 hx-target="#'+ ViewIndex.content_id +@'"
				 href="'+ self.path +@'"
				 class="'+ self.link_class + (_is_on_page ? "" : " secondary") +@'"
				>
					'+ self.text +@'
				</a>
			</li>
		'));
	}
}
