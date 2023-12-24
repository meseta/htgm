function ViewDocsSessions(): HtmxView() constructor {
	// View setup
	static path = "docs/sessions";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		SERVER.add_path("demos/sessions/login", function(_context) {
			_context.response.send_html(@'
				<form action="/demos/sessions/start" method="post">
					<label for="name">Name: </label>
					<input type="text" id="name" name="name">
					<br>
					<input type="submit" value="Submit">
				</form>
			');
		});
		
		SERVER.add_path("demos/sessions/start", function(_context) {
			var _name = _context.request.get_form("name");
			_context.start_session();
			_context.session.set("name", _name);
			_context.response.send_string($"hello {_name} you have logged in");
		});
		
		
		SERVER.add_path("demos/sessions/continue", function(_context) {
			if (_context.has_session()) {
				var _name = _context.session.get("name");
				_context.response.send_string($"hello {_name} you are logged in");
			}
			else {
				_context.response.send_string($"you are not logged in");
			}
		});
		
		
		SERVER.add_path("demos/sessions/logout", function(_context) {
			_context.close_session();
			_context.response.send_string($"You have been logged out");
		});
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		global.server.add_path("demos/sessions/login", function(_context) {
			_context.response.send_html(@`
				<form action="/demos/sessions/start" method="post">
					<label for="name">Name: </label>
					<input type="text" id="name" name="name">
					<br>
					<input type="submit" value="Submit">
				</form>
			`);
		});
		
		global.server.add_path("demos/sessions/start", function(_context) {
			var _name = _context.request.get_form("name");
			_context.start_session();
			_context.session.set("name", _name);
			_context.response.send_string($"hello {_name} you have logged in");
		});
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		global.server.add_path("demos/sessions/continue", function(_context) {
			if (_context.has_session()) {
				var _name = _context.session.get("name");
				_context.response.send_string($"hello {_name} you are logged in");
			}
			else {
				_context.response.send_string($"you are not logged in");
			}
		});
	'));
	
	static demo_code_3 = new HtmlCode(dedent(@'
		global.server.add_path("demos/sessions/logout", function(_context) {
			_context.close_session();
			_context.response.send_string($"You have been logged out");
		});
	'));
	
	static render = function(_context) {
		static cached = quote_fix(@'
			<h1>Sessions</h1>
			<p>
				HTGM is able to create persistent sessions for visitors, allowing data to be persisted across multiple requests.
				It works by setting a session ID in a cookie, which on subsequent requests will retrieve the session, similar to 
				how sessions work in PHP.
			</p>
			
			<h2>Creating a session</h2>
			<p>
				When ready to, a session can be created using <code>context.response.start_session()</code>. This will create a new
				session, and send the session ID to the client as a cookie.
			</p>
						
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, a form is used to submit the username to the login endpoint, which then creates a session and
				assigns the name to session storage. You can see <a href="/demos/sessions/login" target="_blank">the demo here</a>.
			</p>
			
			<h2>Reading from a session</h2>
			<p>
				If a session cookie is presented, a <code>context.session</code> variable is available of the type <code>Struct.HttpServerLoginSession</code>,
				which has functions for setting and getting variables. <code>context.has_session()</code> can be used to check whether
				a session is present and valid.
			</p>
			
			'+ self.demo_code_2.render() + @'
			
			<p>
				In the above example, assuming the user has logged in previously, it will be able to fetch the stored username from
				session storage. You can see <a href="/demos/sessions/continue" target="_blank">the demo here</a>.
			</p>
			
			<h2>Closing a session</h2>
			<p>
				Sessions normally have a set validity period. But sessions can be closed early using <code>context.close_session()</code>
			</p>
			
			'+ self.demo_code_3.render() + @'
			
			<p>
				In the above example, the user`s session will be closed. You can see <a href="/demos/sessions/logout" target="_blank">the demo here</a>.
				Once you go here, try going back to the demo link in the previous section, to see that you have logged out.
			</p>
			
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
