function ViewIndex(): HttpServerRenderBase() constructor {
	// View setup
	static path = "";
	
	// Static properties
	static content_id = self.auto_id("content");
	static title = "HyperText GameMaker";

	// Rendering dynamic routes
	static render_route = function(_context) {
		var _render = _context.pop_render_stack();
		return is_method(_render) ? _render(_context) : ViewHome.render(_context);
	};
	
	static render = function(_context) {
		static _navigation = new ComponentNavigation();
		static _footer = new ComponentFooter();
		static _floating = new ComponentFloating();
	
		// Most of this site is static data, so we instruct our CDN to cache the page
		_context.response.set_should_cache(true);
		
		return Chain.concurrent_struct({
			route: self.render_route(_context),
			navigation: _navigation.render(_context),
			floating: _floating.render(_context),
			footer: _footer.render(_context),
		}).chain_callback(function(_rendered) {
			/// Feather ignore once GM1009
			return @'
				<!DOCTYPE html>
				<html data-theme="dark" lang="en"style="height: 100%">
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
					
				    <meta name="description" content="A web-server framework for GameMaker written in pure GML." />
				    <meta name="theme-color" content="#76428a" />

				    <!-- Open Graph / Facebook -->
				    <meta property="og:type" content="website" />
				    <meta property="og:title" content="HyperText GameMaker" />
				    <meta
				      property="og:description"
				      content="A web-server framework for GameMaker written in pure GML."
				    />
				    <meta
				      property="og:image"
				      content="https://htgm.meseta.dev/static/opengraph.png"
				    />

				    <!-- Twitter -->
				    <meta property="twitter:card" content="summary_large_image" />
				    <meta property="twitter:title" content="HyperText GameMaker" />
				    <meta
				      property="twitter:description"
				      content="A web-server framework for GameMaker written in pure GML."
				    />
				    <meta
				      property="twitter:image"
				      content="https://htgm.meseta.dev/static/opengraph.png"
				    />
					
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