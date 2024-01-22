function ViewDocsRenderStack(): HtmxView() constructor {
	// View setup
	static path = "docs/render-stack";
	static redirect_path = "docs";
	static should_cache = true;
	
	// some demo
	static demos_created = false;
	if (!demos_created) {
		demos_created = true;
		
		global.server.add_render(function(): HttpServerRenderBase() constructor {
			static path = "demos/something";
			static redirect_path = "demos/template";
			
			static render = function(_context) {
				return "<p>This is Something</p>";
			}
		});
		
		global.server.add_render(function(): HttpServerRenderBase() constructor {
			static path = "demos/template";
			
			static render = function(_context) {
				var _render = _context.pop_render_stack();
				var _content = is_method(_render) ? _render(_context) : "<p>nothing here</p>";
				
				return "<h1>This is the template</h1>" + _content;
			}
		});
	}
	
	static demo_code_1 = new HtmlCode(dedent(@'
		// Add a page containing a table
		function ViewSomething(): HttpServerRenderBase() constructor {
			static path = "demos/something";
			static redirect_path = "demos/template";
			
			static render = function(_context) {
				return "<p>This is Something</p>";
			}
		}
	'));
	
	static demo_code_2 = new HtmlCode(dedent(@'
		// Add a page containing a table
		function ViewTemplate(): HttpServerRenderBase() constructor {
			static path = "demos/template";
			
			static render = function(_context) {
				var _render = _context.pop_render_stack();
				var _content = is_method(_render) ? _render(_context) : "<p>nothing here</p>";
				
				return "<h1>This is the template</h1>" + _content;
			}
		}
	'));
	
	
	static render = function(_context) {
		static cached = convert_backticks(@'
			<title>Render Stack and Redirects</title>
			<h1>Render Stack and Redirects</h1>
			<p>
				Render constructors are useful for creating pages that you can navigate to from a browser. The Render constructor
				may internally make use of components to provide more modularity the website. However, there is a special usage
				where we want to change what the Render is rendering based on what URL is being requested. To achieve this, HTGM
				can use a combination of internal redirects, and the render stack.
			</p>
			
			<h2>Internal Redirect</h2>
			<p>
				A Render constructor can sets its <code>redirect_path</code> static variable to indicate that it should redirect
				to a different path. When the server loads up the Render for a given path, and it has a <code>redirect_path</code>
				set, it will stop processing the render, and redirect to the redirected path instead.
			</p>
			
			'+ self.demo_code_1.render(_context) + @'
			
			<p>
				In the above example, a Render is created that has an internal redirect from <code>demos/something</code> to
				<code>demos/elsewhere</code>. The User won`t see this redirect, but the contents of <code>demos/template</code> 
				will be shown to them instead.
			</p>
			
			<h2>Render Stack</h2>
			<p>
				When the internal redirect happens, additionally, the <code>render()</code> mehtod of the constructor is added
				to the render stack inside the context variable. This is something the redirected Render can read, and therefore
				allow it to render the contents of the pre-redirect constructor inside it.
			</p>
			<p>
				This is very useful for implementing a parent or template Render, which can render other things as part of its
				content. The parent/template can contain the common elements of the page, like headers, nav bars, and footers,
				while the child Renders can contain the actual page content.
			</p>
				
			'+ self.demo_code_2.render(_context) + @'
			
			<p>
				In the above example, a template page has been implemented. Inside its render, it checks if there was any other
				stacked render function in the render stack. And if so, runs it. This means if we arrived at the template page
				directly, there would be no function on the render stack, and it will print out the fallback "nothing here". However
				if we arrived at the template by means of an internal redirect from <code>ViewSomething</code>, then ViewSomething`s
				render function would be on the stack, ready to be called to have its contents incorporated into the template.
				<ul>
					<li><a href="/demos/template" target="_blank">/demos/template</a></li>
					<li><a href="/demos/something" target="_blank">/demos/something</a></li>
				</ul>
			</p>
			<p>
				Redirects can be multiple levels deep. For example in this very website, <code>ViewIndex</code> contains the main
				website template, which includes the nav bars. While <code>ViewDocs</code> contains the documentation sidebar.
				Individual documentation pages such as this contain the HTML for just the documentation article, but internally
				redirects to <code>ViewDocs</code>, which internally redirects to <code>ViewIndex</code>.
			</p>
		
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
