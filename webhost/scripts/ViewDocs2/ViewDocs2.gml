function ViewDocs2(): HtmxView() constructor {
	// View setup
	static path = "docs/docs2";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	static render = function(_context) {
		static cached = @'
			<h2>Docs2</h2>
		';
		return cached;
	}
}
