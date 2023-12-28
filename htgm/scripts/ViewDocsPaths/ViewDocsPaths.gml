function ViewDocsPaths(): HtmxView() constructor {
	// View setup
	static path = "docs/paths";
	static redirect_path = "docs";
	static should_cache = true;
	
	// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		SERVER.add_path("demos/hello", function(_context) {
			_context.response.send_html("<h1>Hello World</h1>")
		});
		
		SERVER.add_render(function(): HttpServerRenderBase() constructor {
			static path = "demos/hello2";
			
			static render = function() {
				return "<h1>Hello World 2</h1>";
			}
		});
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a path
		global.server.add_path("demos/hello", function(_context) {
			_context.response.send_html("<h1>Hello World</h1>")
		});
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// This is a render constructor
		function MyView(): HttpServerRenderBase() constructor {
			static path = "demos/hello2";
			
			static render = function() {
				return "<h1>Hello World 2</h1>";
			}
		}
		
		global.server.add_render(MyView);
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static demo_code_3 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add all constructors that have their assets tagged
		global.server.add_renders_by_tag("http_view");
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static render = function(_context) {
		static cached = convert_backticks(@'
			<title>Paths</title>
			<h1>Paths</h1>
			<p>
				HTGM works by assigning handler functions to handle specific paths, which will be run
				when a browser or other HTTP client makes a request. A path is the part of the URL following
				the domain name. e.g in <code>https://example.com/path/to/something</code>, the
				<code>/path/to/something</code> part is the path.
			</p>
			<p>
				There are multiple ways of assigning a handler to a path, ranging from simple functions, to
				render structs, to specialized pre-built functionality. A typical web server made using HTGM
				will consist of multiple paths. 
			</p>
			
			<h2>Simple Callback Functions</h2>
			<p>
				The simplest way to have HTGM respond to a path is to use the <code>add_path()</code>, which
				accepts the path, and the function to run when a client accesses that path. When the function
				is called, it will be provided with a single context argument of the type
				<code>Struct.HttpServerRequetsContext</code>, which contains the methods needed to return data
				to the client.
			</p>
						
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, a new HTTP server is created, listening on port 5000, and the path for
				"/demos/hello" is added, which will return a simple HTML page. You can see
				<a href="/demos/hello" target="_blank">the demo here</a>.
			</p>
			
			<h2>Render Structs/Constructors</h2>
			<p>
				HTGM can also accept a render struct/constructor, which contains extra methods and properties
				it can use to make paths more self-contained. Render structs/constructors can be added to the
				server using <code>add_render()</code>.
			</p>
						
			'+ self.demo_code_2.render() + @'
			
			<p>
				In the above example, a new constructor is created, using <code>HttpServerRenderBase</code> as
				the base constructor. This constructor sets the <code>path</code> static variable, and provides
				the <code>render()</code> function which will be called when the client accesses the path.
			</p>
			<p>
				The <code>render()</code> method will be provided a <code>Struct.HttpServerRequestContext</code>
				context argument, however, unlike the a Simple Callback function, the return value of the function
				is sent back to the client as an HTML document, rather than needing to use the context`s response
				argument. You can see <a href="/demos/hello2" target="_blank">the demo here</a>.
			</p>
			<p>
				The <code>render()</code> method can return a <code>Struct.Chain</code> for asynchronous responses.
			</p>
			
			<h2>Automatically adding by Asset Tag</h2>
			<p>
				There may often be many files to add. Rather than specifying them manually, one by one using
				<code>add_render()</code>, there is a convenience function that will add all the constructor assets
				that have been tagged in the asset browser with a given tag.
			</p>
						
			'+ self.demo_code_3.render() + @'
			
			<p>
				For this to work, the asset name must match the constructor name exactly.
			</p>
			
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
