function HtmxMain(): HtmxView() constructor {
	static path = "";
	static content_id = self.auto_id("content");
	
	static navigation = new HtmxNavigation();
	
	static render_route = function(_context) {
		switch(_context.request.path_original) {
			default:
			case HtmxPage1.path: return HtmxPage1.render(_context);
			case HtmxPage2.path: return HtmxPage2.render(_context);
		}
	};
	
	static render = function(_context) {
		return dedent(@'
			<!DOCTYPE html>
			<html>
			<script src="/static/htmx.min.js"></script>
			<div id="'+self.content_id+@'">
				'+ self.render_route(_context) +@'
			</div>
			'+ self.navigation.render() +@'
			</html>
		');
	};
}

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


