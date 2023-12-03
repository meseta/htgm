function ViewHome(): HtmxView() constructor {
	static path = "home";
	static render = function(_context) {
		static cached = dedent(@'
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
				<header>
					Example code
				</header>
				<pre>
					<code class="language-gml">
						function ViewHome(): HtmxView() constructor {
						
							static render = function(_context) {
								console.log("hello");
							}
						}
					</code>
				</pre>
			</article>
			
			<script>hljs.highlightAll();</script>
		');
		return cached;
	}
}
