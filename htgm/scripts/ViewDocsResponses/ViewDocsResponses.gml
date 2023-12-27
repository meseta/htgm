function ViewDocsResponses(): HtmxView() constructor {
	// View setup
	static path = "docs/responses";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	static demo_code_1 = new HtmlCode(dedent(@'
		global.server.add_path("demos/headers", function(_context) {
			_context.response.set_header("Access-Control-Allow-Origin", "*"); 
			_context.response.send_string("OK");
		});
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		global.server.add_path("demos/json", function(_context) {
			_context.response.send_json({a: 1, b: 2});
		});
	'));
	
	static demo_code_3 = new HtmlCode(dedent(@'
		global.server.add_path("demos/empty", function(_context) {
			_context.response.send_empty();
		});
	'));
	
	static demo_code_4 = new HtmlCode(dedent(@'
		global.server.add_path("demos/empty", function(_context) {
			_context.response.send_json({error: not found}, 400);
		});
	'));
	
	static render = function(_context) {
		static cached = convert_backticks(@'
			<title>Responses</title>
			<h1>Responses</h1>
			<p>
				When using <code>add_path</code> to add a handler for a path, it is possible to change several aspects of the
				response, including the HTTP Status code, the response headers, as well as returning buffers instead of strings.
				The functionality to do so are available in the context argument.
			</p>
			
			<h2>Sending headers</h2>
			<p>
				The function <code>context.response.set_header()</code> Can be used to set headers in the response.
			</p>
						
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, the endpoint sets the header <code>Access-Control-Allow-Origin</code> to the value <code>*</code>.
			</p>
			
			<h2>Json</h2>
			<p>
				A convenient function is provided to send structs or other serializable things as JSON.
			</p>
			
			'+ self.demo_code_2.render() + @'
			
			<p>
				In the above example, a struct is being sent. This will get automatically run through <code>json_stringify()</code>
				and the right content-type headers will be set.
			</p>
			
			<h2>Empty</h2>
			<p>
				Sometimes an empty response is needed. This is a special-type of HTTP response that has no body (not even a string).
			</p>
			
			'+ self.demo_code_3.render() + @'
			
			<p>
				In the above example, no response body will be sent. The status code of 204 will be used by default, unless otherwise
				specified. Some servers should send such a response for actions that result in no output.
			</p>
			
			<h2>Status Codes</h2>
			<p>
				The various send functions have optional arguments to set the status code. The default in most cases is 200, other than
				the <code>send_empty()</code> which defaults to 204.
			</p>
			
			'+ self.demo_code_4.render() + @'
			
			<p>
				In the above example, a JSON is being sent with a status code of 400. This is useful for some clients that read the
				status code to decide if an action has succeded or not.
			</p>
			
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
