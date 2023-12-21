function ViewHome(): HtmxView() constructor {
	static path = "home";
	
	static code_example1 = new HtmlCode(@'
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
	');
	
	static code_example2 = new HtmlCode(@'
		/** An example component that renders a paragraph */
		function Para(_text): HtmlComponent() constructor {
			self.text = _text;
			
			static render = function(_context) {
				return $"<p>{self.text}</p>";
			}
		}
	');
	
	static code_example3 = new HtmlCode(@'
		// Add ViewExample to the server
		// The `path` will be automatically used
		SERVER.add_render(ViewExample);
	');
	
	static code_example4 = new HtmlCode(@'
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
	');

	static code_example5 = new HtmlCode(@'
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
	');
	
	static render = function(_context) {
		static cached = @'
			<section style="text-align: center; margin-top: 3em;">
				<hgroup>
					<h1>HyperText GameMaker</h1>
					<h2>A web-server framework for GameMaker written in pure GML</h2>
				</hgroup>
				<p>
					<a href="#" role="button">Documentation</a> &nbsp; 
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
			
			<article>
				<h2>About HyperText GameMaker</h2>
				<p>
					<strong>HyperText GameMaker</strong> is an open source framework that allows <a href="https://gamemaker.io">GameMaker</a>
					to be used as a webserver and server-side scripting language. GameMaker developers can use <strong>HTGM</strong>
					to create and host websites and APIs using only GML, without any external tools. It does this by providing a web-server
					written in pure GML, a component-framework, and integrations with <a href="https://htmx.org">HTMX</a> to provide
					simple-to-use dynamic website capabilities. For example, this website is built and hosted using <strong>HyperText GameMaker</strong>.
				</p>
				<p>
					The name <strong>HTGM (HyperText GameMaker)</strong> is derived from HTML (HyperText Markup Language), indicating that GameMaker
					can be used to render and output HyperText to the browser. Its principle of operation is that of a server-side scripting language
					similar to PHP or React SSR, in that each request from the browser is handled by GameMaker project that uses <strong>HTGM</strong>
					which renders an HTML document to be sent to the browser to display. <strong>HTGM</strong> can act as a REST API or Websocket server
					equally well.
				</p>
				<p>
					<strong>HTGM</strong> can be used to host websites if built and deployed to a server, or it can be used to provide browser-based
					in-game or debugging tools that can run inside a running GameMaker game, as real-time data connectivity is possible through the use
					of websockets. Giving players or gamedevs access to interactive tools built using web technologies such as HTML and Javascript.
					Because HTGM is a webserver, it can work with a wide range of web technologies. The demo project includes integration with HTMX, but
					can be extended to include the use of client-side frameworks such as React or Vue if desired.
				</p>
				<p>
					<strong>HTGM</strong> was created by <a href="https://meseta.dev">Meseta</a>, released under the
					<a href="https://opensource.org/license/mit/">MIT open source license</a>, and is free to use for commercial and non-commercial
					projects. The project is released as-is, and no support or warranties are provided, but those working on GameMaker projects in
					general may find help from the friendly <a href="https://discord.gg/gamemaker">GameMaker community on Discord</a>.
				</p>
			</article>
			
			<section style="text-align: center;">
				<h1>Ready to start using HyperText GameMaker?</h1>
				<p>
					<a href="#" role="button">Documentation</a> &nbsp; 
					<a href="#" role="button" class="secondary outline">Download</a>
				</p>
			</section>
		';
		return cached;
	}
}
