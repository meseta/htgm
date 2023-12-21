function ViewDocs1(): HtmxView() constructor {
	static path = "docs/docs1";
	static redirect_path = "docs";
	
	static render = function(_context) {
		static cached = @'
			<h2>Docs1</h2>
		';
		return cached;
	}
}
