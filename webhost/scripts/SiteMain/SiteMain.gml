function SiteMain(): HtmxView() constructor {
	// View setup
	static path = "";
	
	// On-page components
	static navigation = new SiteNavigation();
	static footer = new SiteFooter();
	
	// Static properties
	static content_id = self.auto_id("content");
	static title = "Gamemaker Webserver";
	
	// Rendering functions
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
			<meta charset="utf-8">
			<title>'+ self.title +@'</title>
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<link rel="stylesheet" href="/static/pico.min.css">
			<link rel="stylesheet" href="/static/theme.css">
			<script src="/static/htmx.min.js"></script>
			<script src="/static/htmx_ext_ws.min.js"></script>
			
			'+ self.navigation.render(_context) +@'
			<main class="container" id="'+self.content_id+@'">
				'+ self.render_route(_context) +@'
			</main>
			'+ self.footer.render(_context) +@'
			</html>
		');
	};
}
