function ViewDocsComponents(): HtmxView() constructor {
	// View setup
	static path = "docs/components";
	static redirect_path = "docs";
	static shoud_cache = true;
	
	// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		
		// Add a page containing a table
		global.server.add_render(function(): HttpServerRenderBase() constructor {
			static path = "demos/table";
			
			static DataRow = function(_a, _b, _c): HtmlComponent() constructor {
				self.a = _a;
				self.b = _b;
				self.c = _c;
		
				static render = function(_context) {
					return $"<tr><td>{self.a}</td><td>{self.b}</td><td>{self.c}</td></tr>";
				}
			}
			
			static data = [
			  new DataRow(1, 2, 3),
			  new DataRow(4, 5, 6),
			  new DataRow(7, 8, 9),
			]
			
			static render = function(_context) {
				var _component = new DataRow("X", "Y", "Z");
				return "<table>" + 
					new DataRow("A", "B", "C").render(_context) +
					HtmlComponent.render_array(self.data, "", _context) +
					_component.render(_context) + 
					"</table>";
			}
		});
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		// Create a server on port 5000
		global.server = new HttpServer(5000);
		
		// Define a component for a table row for some data
		function ComponentDataRow(_a, _b, _c): HtmlComponent() constructor {
			self.a = _a;
			self.b = _b;
			self.c = _c;
		
			static render = function(_context) {
				return $"<tr><td>{self.a}</td><td>{self.b}</td><td>{self.c}</td></tr>";
			}
		}
		
		// Add a page containing a table
		function ViewTable(): HttpServerRenderBase() constructor {
			static path = "demos/table";
			
			static data = [
			  new ComponentDataRow(1, 2, 3),
			  new ComponentDataRow(4, 5, 6),
			  new ComponentDataRow(7, 8, 9),
			]
			
			static render = function(_context) {
				var _component = new ComponentDataRow("X", "Y", "Z");
				return "<table>" + 
					new ComponentDataRow("A", "B", "C").render(_context) +
					HtmlComponent.render_array(self.data, "", _context) +
					_component.render(_context) + 
					"</table>";
			}
		
		// Add it to the server
		global.server.add_render(ViewTable);
				
		// This must run after entering the first room
		global.server.start();
	'));
	
	static render = function(_context) {
		static cached = convert_backticks(@'
			<title>Resuable Components</title>
			<h1>Resuable Components</h1>
			<p>
				The benefit and advantage of dynamically generating HTML is being able to simplify that task by defining and
				reusing components, rather than having to write out HTML over and over again.
			</p>
			
			<h2>HtmlComponent</h2>
			<p>
				While there is no strict pattern for how to implement reusable components, some components are included in the
				HTGM library and can be used as a starting point, such as the base <code>HtmlComponent</code> constructor.
			</p>
						
			'+ self.demo_code_1.render() + @'
			
			<p>
				In the above example, a reusable component is defined, that will render out one row of an HTML table.
				The component accepts constructor arguments, which it will save internally. A <code>render()</code> is provided
				to draw render out the component as HTML. You can see <a href="/demos/table" target="_blank">the demo here</a>.
			</p>
		
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
