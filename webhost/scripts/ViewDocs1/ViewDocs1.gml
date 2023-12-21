function ViewDocs1(): HtmxView() constructor {
	// View setup
	static path = "docs/docs1";
	static redirect_path = "docs";
	static cache_control = "public, max-age=300";
	
	static render = function(_context) {
		static cached = @'
			<h2>Docs1</h2>
		';
		return cached;
	}
}
