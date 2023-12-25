function ViewDocsStaticFiles(): HtmxView() constructor {
	// View setup
	static path = "docs/static-files";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		
		SERVER.add_file_server("demos/file-server/*", "static/demos");
		SERVER.add_sprite_server("demos/sprite-server/{sprite}.png", "sprite");
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a static file server
		global.server.add_file_server("demos/file-server/*", "static/demos");
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a sprite server
		global.server.add_sprite_server("demos/sprite-server/{sprite}.png", "sprite");
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static render = function(_context) {
		static cached = quote_fix(@'
			<title>Static Files and Sprites</title>
			<h1>Static Files and Sprites</h1>
			<p>
				Most websites have a need to serve a variety of static content, not just dynamically-generated pages.
				To help with this, HTGM has a couple ways serve up static content: A static file server, and a sprite server.
			</p>
			
			<h2>File Server</h2>
			<p>
				HTGM can create a dynamic path handler that will serve files from a folder in the datafiles of the GameMaker project.
				This allows you to include many static files in the project, without having to load them into the game itself. This is
				useful for things like image files, javascript libraries, or even whole HTML websites.
			</p>
						
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, a dynamic path <code>demos/file-server/*</code> is used, and mapped to a folder
				called <code>static/demos</code> inside the datafiles of the Gamemaker project. This means if a client
				accesses a path such as <code>demos/file-server/cat.png</code>, this is mapped to the file
				<code>static/demos/cat.png</code> in the datafiles folder of the project. HTGM will guess the MIME-type
				of the file based on its file extension. You can see <a href="/demos/file-server/cat.png" target="_blank">the demo here</a>.
			</p>
			
			<h2>Sprite Server</h2>
			<p>
				HTGM can serve any sprite that is included in the GameMaker project as a PNG. This allows you to make sprite
				assets in the project available to the webserver.
			</p>
						
			'+ self.demo_code_2.render() + @'
			
			<p>
				In the above example, a dynamic path <code>demos/sprite-server/{sprite}.png"</code> is used, and the sprite path variable
				is used to match sprite asset names in the project. This means if a client
				accesses a path such as <code>demos/sprite-server/sLogo.png</code>, this is mapped to the asset <code>sLogo</code> in the project.
				You can see <a href="/demos/sprite-server/sLogo.png" target="_blank">the demo here</a>.
			</p>

			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
