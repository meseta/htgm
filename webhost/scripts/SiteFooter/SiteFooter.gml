function SiteFooter(): HtmxComponent() constructor {
	static render = function(_context) {
		static cached = dedent(@'
			<footer hx-boost="true" class="container-fluid">
			</footer>
		');
		return cached;
	};
}
