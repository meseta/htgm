function ViewIndex(): HttpServerRenderBase() constructor {
	// View setup
	static path = "";
	
	// Static properties
	static content_id = self.auto_id("content");
	static title = "HyperText GameMaker";
	
	// On-page components
	static navigation = new ComponentNavigation();
	static footer = new ComponentFooter();
	static floating = new ComponentFloating();
	
	// Rendering dynamic routes
	static render_route = function(_context) {
		var _render = _context.request.pop_render_stack();
		return is_method(_render) ? _render(_context) : ViewHome.render(_context);
	};
	
	static render = function(_context) {
		return Chain.concurrent_struct({
			route: self.render_route(_context),
			navigation: self.navigation.render(_context),
			floating: self.floating.render(_context),
			footer: self.footer.render(_context),
		}).chain_callback(function(_rendered) {
			/// Feather ignore once GM1009
			return @'
				<!DOCTYPE html>
				<html data-theme="dark" style="height: 100%">
				<head>
					<meta charset="utf-8">
					<title>'+ self.title +@'</title>
					<link rel="icon" type="image/png" href="/images/sFavicon.png">
					<meta name="viewport" content="width=device-width, initial-scale=1">
					<link rel="stylesheet" href="/static/pico/pico.min.css">
					<link rel="stylesheet" href="/static/pico/theme.css">
					<script src="/static/htmx/htmx.min.js"></script>
					<script src="/static/htmx/ext_ws.min.js"></script>
				
					<link rel="stylesheet" href="/static/hljs/gml.min.css">
					<script src="/static/hljs/highlight.min.js"></script>
					<script src="/static/hljs/gml.min.js"></script>
				</head>
				<body style="min-height: 100%; background-image: linear-gradient(180deg, transparent, #ffffff11); background-attachment: fixed;">
					'+ _rendered.navigation +@'
					<main class="container" id="'+self.content_id+@'">
						'+ _rendered.route +@'
					</main>
					'+ _rendered.floating +@'
					'+ _rendered.footer +@'
				</body>
				</html>
		'});
	};
}
