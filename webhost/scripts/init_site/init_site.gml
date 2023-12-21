/// Feather ignore GM2017

/** Initialize the website */
function init_site(){
	// The webserver
	#macro SERVER global.server
	SERVER = new HttpServer(5000, LOGGER);
	
	// static file host
	SERVER.add_file_server("static/*", "static");
	SERVER.add_sprite_server("images/{image_name}.png", "image_name");

	// add views
	SERVER.add_render(ViewHome);
	SERVER.add_render(ViewAbout);
	
	SERVER.add_render(ViewDocs1);
	SERVER.add_render(ViewDocs2);
	
	SERVER.add_render(ViewDocs);
	SERVER.add_render(ViewIndex);
	
	// websocket
	SERVER.add_websocket("fps", function(_context) { return new WebsocketFps(); });
}
