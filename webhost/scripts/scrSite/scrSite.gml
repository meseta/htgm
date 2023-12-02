/** Initialize the website */
function init_site(){
	// static file host
	SERVER.add_file_server("static/*", "static");
	SERVER.add_sprite_server("images/{image_name}.png", "image_name");

	// kubernetes heatlhchecks
	SERVER.add_path("healthz", function(_context) { _context.response.send_string("OK"); });
	SERVER.add_path("readiness", function(_context) { _context.response.send_string("OK"); });

	// add views
	SERVER.add_render(HtmxPage1);
	SERVER.add_render(HtmxPage2);
	SERVER.add_render(SiteMain);
	
	// websocket
	SERVER.add_websocket("chatroom", function(_context) {
		return new WebsocketChat();
	});
}