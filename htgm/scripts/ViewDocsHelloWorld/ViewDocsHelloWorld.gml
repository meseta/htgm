function ViewDocsHelloWorld(): HtmxView() constructor {
	// View setup
	static path = "docs/hello-world";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	static demo_code_1 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		server = new HttpServer(5000);
				
		// Index view
		function Index(): HttpServerRenderBase() constructor {
			static path = "";
			
			static render = function() {
				return @`
					<!DOCTYPE html>
					<html>
					<head>
						<meta charset="utf-8">
						<title>Hello World</title>
					</head>
					<body>
						<h1>Hello World</h1>
						<p>
							This is a website made in GameMaker
						</p>
					</body>
					</html>
				`;
			}
		}
		
		//Add index
		server.add_render(Index);
	
		// This must run after entering the first room
		server.start();
	'));
	
	static render = function(_context) {
		static cached = @'
			<h1>Hello World</h1>
			<p>
				To build your first website, in an object or script that will run once the game has started,
				and instantiate the server.
			</p>
					
			'+self.demo_code_1.render()+@'

			<p>
				Once you run the project you should be able to open a browser and open the url
				<code>http://localhost:5000</code> to see your page
			</p>
			
			<script>hljs.highlightAll();</script>
		';
		return cached;
	}
}
