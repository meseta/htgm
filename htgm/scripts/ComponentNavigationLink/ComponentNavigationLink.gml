/**
 * @param {String} _target Target element ID
 * @param {String} _path The path of the navigation
 * @param {String} _text The text label
 * @param {String*} _alt_path Alternative path (used for main link highlighting)
 */
function ComponentNavigationLink(_target, _path, _text, _alt_path=undefined): HtmlComponent() constructor {
	self.target = _target;
	self.path = _path;
	self.text = _text;
	self.alt_path = _alt_path ?? self.path;
	self.link_class = self.auto_id(self.target+"-link");

	static render = function(_context) {
		var _is_on_page = string_starts_with(_context.request.path_original, self.path) || _context.request.path_original == self.alt_path;
		return convert_backticks(@'
			<li>
				<a
				 hx-on="click: htmx.findAll(`.'+self.link_class+ @'`).forEach((el) => htmx.addClass(el, `secondary`)); htmx.removeClass(this, `secondary`);"
				 hx-target="#'+ self.target +@'"
				 href="/'+ self.path +@'"
				 class="'+ self.link_class + (_is_on_page ? "" : " secondary") +@'"
				>
					'+ self.text +@'
				</a>
			</li>
		');
	}
}
