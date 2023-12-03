function ViewAbout(): HtmxView() constructor {
	static path = "about";
	static render = function(_context) {
		static cached = dedent(@'
			<h1>About HyperText GameMaker</h1>
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
		');
		return cached;
	}
}
