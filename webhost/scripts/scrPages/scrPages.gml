function HtmxPage1(): HtmxView() constructor {
	static path = "page1";
	static render = function(_context) {
		static cached = dedent(@'
			<h1>Page 1</h1>
		');
		return cached;
	}
}

function HtmxPage2(): HtmxView() constructor {
	static path = "page2";
	static render = function(_context) {
		static cached = dedent(@'
			<h1>Page 2</h1>
		');
		return cached;
	}
}


