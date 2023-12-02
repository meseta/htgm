/** Initialize the website */
function init_site(){
	// static file host
	SERVER.add_file_server("static/*", "static");

	// kubernetes heatlhchecks
	SERVER.add_path("healthz", function(_context) { _context.response.send_string("OK"); });
	SERVER.add_path("readiness", function(_context) { _context.response.send_string("OK"); });

	// add views
	SERVER.add_render(HtmxPage1);
	SERVER.add_render(HtmxPage2);
	SERVER.add_render(SiteMain);
	
	// websocket
	SERVER.add_websocket("websocket", function(_context) {
		return new HttpServerWebsocketSessionBase();
	});
}