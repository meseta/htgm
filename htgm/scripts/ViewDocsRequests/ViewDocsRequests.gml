function ViewDocsRequests(): HtmxView() constructor {
	// View setup
	static path = "docs/requests";
	static redirect_path = "docs";
	static shoud_cache = true;
	
		// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		SERVER.add_path("demos/form", function(_context) {
			_context.response.send_html(@'
				<form action="/demos/submit" method="post">
					<label for="name">Name: </label>
					<input type="text" name="name">
					<br>
					<label for="name">Fruit: </label>
					<input type="text" name="fruit">
					<br>
					<input type="submit" value="Submit">
				</form>
			');
		});
		
		SERVER.add_path("demos/submit", function(_context) {
			var _name = _context.request.get_form("name");
			var _fruit = _context.request.get_form("fruit");
			_context.response.send_string($"hello {_name} who likes {_fruit}");
		});
		
		SERVER.add_path("demos/file", function(_context) {
			_context.response.send_html(@'
				<form action="/demos/file-submit" method="post" enctype="multipart/form-data">
					<label for="name">Name: </label>
					<input type="text" name="name">
					<br>
					<input type="file" name="file">
					<br>
					<input type="submit" value="Submit">
				</form>
			');
		});
		
		SERVER.add_path("demos/file-submit", function(_context) {
			var _name = _context.request.get_form("name");
			var _file = _context.request.get_file("file");
			_context.response.send_string($"hello {_name} you uploaded filesize: {_file.size}");
		});
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		global.server.add_path("demos/request-headers", function(_context) {
			if (!_context.request.has_header("authorization")) {
				_context.response.send_string("Not authorized", 401);
			}
			_context.response.send_string("OK");
		});
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		global.server.add_path("demos/{name}", function(_context) {
			var _name = _context.request.get_parameter("name");
			var _id = _context.request.get_query("id");
			_context.response.send_string($"hello {_name}, your id is {_id}");
		});
	'));
	
	static demo_code_3 = new HtmlCode(dedent(@'
		global.server.add_path("demos/method", function(_context) {
			if (_context.request.method == "GET") {
				_context.response.send_string("a get request");
			}
			else if (_context.request.method == "POST") {
				_context.response.send_string("a post request");
			}
		});
	'));
	
	static demo_code_4 = new HtmlCode(dedent(@'
		global.server.add_path("demos/body", function(_context) {
			if (_context.request.get_header("content-type") == "application/json") {
				var _json = _context.request.get_data_as_json();
				_context.response.send_string($"payload: {_json.something}");
			}
			else {
				var _text = _context.request.get_data_as_string();
				_context.response.send_string($"payload: {_text}");
			}
		});
	'));
	
	static demo_code_5 = new HtmlCode(dedent(@'
		global.server.add_path("demos/form", function(_context) {
			_context.response.send_html(@`
				<form action="/demos/submit" method="post">
					<label for="name">Name: </label>
					<input type="text" id="name" name="name">
					<br>
					<label for="name">Fruit: </label>
					<input type="text" id="fruit" name="fruit">
					<br>
					<input type="submit" value="Submit">
				</form>
			`);
		});
		
		global.server.add_path("demos/submit", function(_context) {
			var _name = _context.request.get_form("name");
			var _name = _context.request.get_form("fruit");
			_context.response.send_string($"hello {_name} who likes {_fruit}");
		});
	'));
	
	static demo_code_6 = new HtmlCode(dedent(@'
		global.server.add_path("demos/file", function(_context) {
			_context.response.send_html(@`
				<form action="/demos/file-submit" method="post">
					<label for="name">Name: </label>
					<input type="text" id="name" name="name">
					<br>
					<input type="file" name="file">
					<br>
					<input type="submit" value="Submit">
				</form>
			`);
		});
		
		global.server.add_path("demos/file-submit", function(_context) {
			var _name = _context.request.get_form("name");
			var _file = _context.request.get_file("file");
			_context.response.send_string($"hello {_name} you uploaded filesize: {_file.size}");
		});
	'));
	
	static render = function(_context) {
		static cached = quote_fix(@'
			<h1>Requests</h1>
			<p>
				When handling requests, several pieces of data from the incoming request is made available via the context
				argument that is provided to render and callbacks.
			</p>
			
			<h2>Headers</h2>
			<p>
				The functions <code>context.request.has_header()</code> and <code>context.request.get_header()</code> can
				be used to check or fetch headers from the incoming request. The header name is lowercased during receiving,
				so these functions are not case sensitive on the header name.
			</p>
			
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, the <code>Authorization</code> header is checked, and if there isn`t one, a message
				is returned indicating a problem. If there was one, an OK message is returend
			</p>
				
			<h2>Path and Query parameters</h2>
			<p>
				The function <code>context.request.get_parameter()</code> can be used to fetch path parameters, and the
				function <code>context.request.get_parameter()</code> can be used to fetch query parameters from the incoming
				request.
			</p>
			
			'+ self.demo_code_2.render() + @'
			
			<p>
				In the above example, if the user requests the path <code>demos/steve?id=123</code>, then this would result in
				the value <code>steve</code> bein available as a parameter, and <code>123</code> being available as a query
				parameter.
			</p>
			
			<h2>Method</h2>
			<p>
				The HTTP method used can be accessed using <code>context.rquest.get_method()</code> it will have values like
				"GET", "POST", "DELET", and so on.
			</p>
			
			'+ self.demo_code_3.render() + @'
			
			<h2>Body data</h2>
			<p>
				The raw body data can be accessed using the property <code>context.request.data</code>, however it is more common
				to read this as a string or a json, using <code>context.request.get_data_as_string()</code> and 
				<code>context.request.get_data_as_json()</code>.
			</p>
			
			'+ self.demo_code_4.render() + @'
	
			<h2>Form parameters</h2>
			<p>
				If the incoming request contains form parameters, they can be accessed using
				<code>context.request.get_form("name")</code>. This can be used to fetch data from HTML forms.
			</p>
	
			'+ self.demo_code_5.render() + @'
			
			<p>
				In the above example, if a form is submitted to that page with the field name <code>name</code>, the value will
				be accessed. You can see <a href="/demos/form" target="_blank">the demo here</a>.
			</p>
			
			<h2>File uploads</h2>
			<p>
				Upload files can be accessed using <code>context.request.get_file_buffer("file")</code> and
				<code>context.request.get_file_name("file")</code> to get the buffer and the filename respectively. The buffers will
				be cleaned up once the endpoint responds.
			</p>
	
			'+ self.demo_code_6.render() + @'
			
			<p>
				In the above example, a file upload form submits a file, and the buffer length is printed out.
				You can see <a href="/demos/file" target="_blank">the demo here</a>.
			</p>
			
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
