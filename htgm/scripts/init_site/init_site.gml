/// Feather ignore GM2017

/** Initialize the website */
function init_site(){
	SERVER = new HttpServer(5000, LOGGER);
	SERVER.logger.set_level(Logger.INFO);

	// static file host
	SERVER.add_file_server("static/*", "static");
	SERVER.add_sprite_server("images/{image_name}.png", "image_name");

	// add views
	SERVER.add_renders_by_tag("http_view");
	
	// websocket
	SERVER.add_websocket("fps", function(_context) { return new WebsocketFps(); });
}
