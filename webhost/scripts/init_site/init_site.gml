/** Initialize the website */

/// Feather ignore GM2017
function init_site(){
	// static file host
	SERVER.add_file_server("static/*", "static");
	SERVER.add_sprite_server("images/{image_name}.png", "image_name");

	// add views
	SERVER.add_render(ViewHome);
	SERVER.add_render(ViewAbout);
	SERVER.add_render(ViewIndex);
	
	// websocket
	SERVER.add_websocket("fps", function(_context) { return new WebsocketFps(); });
}
