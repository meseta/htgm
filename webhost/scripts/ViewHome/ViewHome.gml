function ViewHome(): HtmxView() constructor {
	// View setup
	static path = "home";
	static shoud_cache = true;
	
	// On-page components
	static code_example1 = new HtmlCode(dedent(@'
		/** An example "view" */
		function ViewExample(): HtmxView() constructor {
		  // This view will be mounted at /about
		  static path = "about";
			
		  // Define a bunch of sub-components
		  static lines = [
		    new Para("Lorem ipsum dolor sit amet"),
		    new Para("Consectetur adipiscing elit"),
		    new Para("Etiam mi neque"),
		  ];
			
		  // This will be called to render the view
		  static render = function(_context) {
		    // Loop over array of components, and render
		    return @`
		      <h1>Hello world</h1>
		      `+ HtmlComponent.render_array(_lines, "", _context)
		  }
		}
	'));
	
	static code_example2 = new HtmlCode(dedent(@'
		/** An example component that renders a paragraph */
		function Para(_text): HtmlComponent() constructor {
			self.text = _text;
			
			static render = function(_context) {
				return $"<p>{self.text}</p>";
			}
		}
	'));
	
	static code_example3 = new HtmlCode(dedent(@'
		// Add ViewExample to the server
		// The `path` will be automatically used
		SERVER.add_render(ViewExample);
	'));
	
	static code_example4 = new HtmlCode(dedent(@'
		/** An example GET endpoint /users/{user_id} */
		SERVER.add_path("users/{user_id}", function(_context) {
		  if (_context.request.method != "GET") {	  
		    throw new ExceptionHttpMethodNotAllowed();
		  }
		  
		  var _user_id = _context.request.parameters.user_id;
		  var _user = global.users[$ _user_id];
		  if (is_undefined(_user)) {
			throw new ExceptionHttpNotFound("User not found");
		  }
		  
		  _context.response.send_json(_user);
		}
	'));

	static code_example5 = new HtmlCode(dedent(@'
		/** An example websocket handler */
		function WebsocketChat(): HttpServerWebsocketSessionBase() constructor {
		  // All connected chat clients
		  static chat_clients = [];
	
		  // add myself to chat clients list
		  array_push(self.chat_clients, self);
	
		  static on_data_buffer = function(_buffer, _is_string) {
		    // decode data
		    var _text = buffer_read(_buffer, buffer_text);
		    var _json = json_parse(_text);
		
		    // broadcast it to all clients
		    array_foreach(self.chat_clients, method({message: _json.message}, function(_client) {
			  _client.websocket.send_data_string(data);
		    })
		  }
	
		  static on_close = function(_close_code=undefined, _close_reason=undefined) {
		    // remove myself from chat clients list on disconnect
		    var _idx = array_get_index(self.chat_clients, self);
		    if (_idx != -1) {
			  array_delete(self.chat_clients, _idx, 1);
		    }
		  }
		}
	'));
	
	static render = function(_context) {
		static cached = @'
			<section style="text-align: center; margin-top: 3em;">
				<hgroup>
					<h1>HyperText GameMaker</h1>
					<h2>A web-server framework for GameMaker written in pure GML</h2>
				</hgroup>
				<p>
					<a href="/'+ViewDocs.path+@'" role="button">Documentation</a> &nbsp; 
					<a href="#" role="button" class="secondary outline">Download</a>
				</p>
			</section>
			
			<article>
				<h2>Make Webpages in GameMaker</h2>
				<p>Use re-usable components to build webpages easily</p>
				<div class="grid">
					<div>
						'+self.code_example1.render()+@'
					</div>
					<div>
						'+self.code_example2.render()+@'
						'+self.code_example3.render()+@'
					</div>
				</div>
			</article>
			
			<article>
				<h2>Make API Endpoints in GameMaker</h2>
				<p>Create REST endpoints for backend services</p>
				'+self.code_example4.render()+@'
			</article>
			
			<article>
				<h2>Make Websocket servers in GameMaker</h2>
				<p>Create Websocket endpoints for bi-bidirectional communication in browsers</p>
				'+self.code_example5.render()+@'
			</article>
			
			<script>hljs.highlightAll();</script>
			
			<section style="text-align: center;">
				<h1>Ready to start using HyperText GameMaker?</h1>
				<p>
					<a href="/'+ViewDocs.path+@'" role="button">Documentation</a> &nbsp; 
					<a href="#" role="button" class="secondary outline">Download</a>
				</p>
			</section>
		';
		return cached;
	}
}
