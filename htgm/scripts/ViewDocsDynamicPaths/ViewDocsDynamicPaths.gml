function ViewDocsDynamicPaths(): HtmxView() constructor {
	// View setup
	static path = "docs/dynamic-paths";
	static redirect_path = "docs";
	static should_cache = true;
	
	// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		SERVER.add_path("demos/wildcard/*/path", function(_context) {
			_context.response.send_html("<h1>Wildcard match</h1>")
		});
		SERVER.add_path("demos/wildcard_end/*", function(_context) {
			_context.response.send_html("<h1>Wildcard end match</h1>")
		});
		SERVER.add_path("demos/fruit/{fruit_name}/like", function(_context) {
			_context.response.send_html($"<h1>I like {_context.request.get_parameter("fruit_name")}</h1>")
		});
		SERVER.add_path("demos/users/{user_name}/likes_fruit/{fruit_name}", function(_context) {
			var _user_name = _context.request.get_parameter("user_name");
			var _fruit_name = _context.request.get_parameter("fruit_name");
			_context.response.send_html($"<h1>{_user_name} likes {_fruit_name}</h1>")
		});
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a path
		global.server.add_path("demos/wildcard/*/path", function(_context) {
			_context.response.send_html("<h1>Wildcard match</h1>")
		});
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a path
		global.server.add_path("demos/wildcard_end/*", function(_context) {
			_context.response.send_html("<h1>Wildcard end match</h1>")
		});
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static demo_code_3 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a path
		global.server.add_path("demos/fruit/{fruit_name}/like", function(_context) {
			_context.response.send_html($"<h1>I like {_context.request.get_parameter("fruit_name")}</h1>")
		});
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static demo_code_4 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
				
		// Add a path
		global.server.add_path("demos/users/{user_name}/likes_fruit/{fruit_name}", function(_context) {
			var _user_name = _context.request.get_parameter("user_name");
			var _fruit_name = _context.request.get_parameter("fruit_name");
			_context.response.send_html($"<h1>{_user_name} likes {_fruit_name}</h1>")
		});
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	
	static render = function(_context) {
		static cached = convert_backticks(@'
			<title>Dynamic Paths</title>
			<h1>Dynamic Paths</h1>
			<p>
				When adding paths, it is possible to have HTGM match path based on a pattern, rather than an exact string. Doing
				so makes path matching dynamic. An example of a dynamic path is <code>/demos/users/{user_name}</code>, which will
				match a client accessing that URL by that pattern
			</p>
			
			<h2>Wildcard Paths</h2>
			<p>
				The simplest type of dynamic path is a wildcard path, where the path string contains an asterisk <code>*</code>,
				which will match any value.
			</p>
						
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, the wildcard path <code>demos/wildcard/*/path</code> is added. This will match any request
				that follows this pattern, where <code>*</code> can be anything. For example, both the following URLs will match
				this pattern.
				<ul>
					<li><a href="/demos/wildcard/anything/path" target="_blank">/demos/wildcard/anything/path</a></li>
					<li><a href="/demos/wildcard/everything/path" target="_blank">/demos/wildcard/everything/path</a></li>
					<li><a href="/demos/wildcard/123/path" target="_blank">/demos/wildcard/123/path</a></li>
				</ul>
			</p>
			<p>
				However the following do not match. These will return a not-found page.
				<ul>
					<li><a href="/demos/wildcard/two/segments/path" target="_blank">/demos/wildcard/two/segments/path</a></li>
					<li><a href="/demos/wildcard//path" target="_blank">/demos/wildcard//path</a></li>
					<li><a href="/demos/wildcard/path" target="_blank">/demos/wildcard/path</a></li>
				</ul>
			</p>
			
			<h2>Wildcard End Paths</h2>
			<p>
				Normally asterisk will only match one segment of the path, e.g. <code>demo/wildcard/*/path</code> will not match
				<code>demo/wildcard/two/segments/path</code>. However the exception is if the wildcard is on the end of the path,
				which will cause it to match any path regardless of how many segments.
			</p>
		
						
			'+ self.demo_code_2.render() + @'
			
			<p>
				In the above example, the wildcard path <code>demos/wildcard_end/*</code> is added. This will match any request
				that begins with <code>demos/wildcard_end/</code> and can have any ending, for example:
				<ul>
					<li><a href="/demos/wildcard_end/anything" target="_blank">/demos/wildcard_end/anything</a></li>
					<li><a href="/demos/wildcard_end/1/2/3/4/5" target="_blank">/demos/wildcard_end/1/2/3/4/5</a></li>
				</ul>
			</p>
			<p>
				However the it will not match a blank value. So the following will return a not-found page
				<ul>
					<li><a href="/demos/wildcard_end" target="_blank">/demos/wildcard_end</a></li>
					<li><a href="/demos/wildcard_end/" target="_blank">/demos/wildcard_end/</a></li>
				</ul>
			</p>
			
			<h2>Path Parameters</h2>
			<p>
				In addition to wildcard paths, the path can also capture the pattern and make the value available as a path parameter,
				allowing you to create paths that dynamically render content based on what was requested
			</p>
						
			'+ self.demo_code_3.render() + @'
			
			<p>
				In the above example, a path pattern of <code>demos/fruit/{fruit_name}/like</code> is added. This makes the variable
				<code>fruit_name</code> avalaible in the context to be used during rendering. For example:
				<ul>
					<li><a href="/demos/fruit/apple/like" target="_blank">/demos/fruit/apple/like</a></li>
					<li><a href="/demos/fruit/banana/like" target="_blank">/demos/fruit/banana/like</a></li>
				</ul>
			</p>
					
			<h2>Multiple Path Parameters</h2>
			<p>
				Multiple path parameters can be used together
			</p>
						
			'+ self.demo_code_4.render() + @'
			
			<p>
				In the above example, a path pattern of <code>demos/users/{user_name}/likes_fruit/{fruit_name}</code> is added.
				This makes the variables <code>user_name</code> and <code>fruit_name</code> boht avalaible in the context to be
				used during rendering. For example:
				<ul>
					<li><a href="/demos/users/steve/likes_fruit/apple" target="_blank">/demos/users/steve/likes_fruit/apple</a></li>
				</ul>
			</p>

			
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
