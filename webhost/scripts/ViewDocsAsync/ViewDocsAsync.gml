function ViewDocsAsync(): HtmxView() constructor {
	// View setup
	static path = "docs/async";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	static render = function(_context) {
		static cached = @'
			<h1>Async Rendering</h1>
		';
		return cached;
	}
}
