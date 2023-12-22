function ViewDocsGettingStarted(): HtmxView() constructor {
	// View setup
	static path = "docs/getting-started";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	static render = function(_context) {
		static cached = @'
			<h1>Getting Started</h1>
		';
		return cached;
	}
}
