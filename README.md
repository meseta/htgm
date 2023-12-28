# HyperText GameMaker

Links:
* [HTGM Website](https://htgm.meseta.dev)
* [Usage Guide](https://htgm.meseta.dev/docs)
* [GitHub](https://github.com/meseta/htgm)
* [Download](https://github.com/meseta/htgm/releases)

![HyperText GameMaker](https://htgm.meseta.dev/static/opengraph.png)

HyperText GameMaker is an open source framework that allows GameMaker to be used as a webserver and server-side scripting language. GameMaker developers can use HTGM to create and host websites and APIs using only GML, without any external tools. It does this by providing a web-server written in pure GML, a component-framework, and integrations with HTMX to provide simple-to-use dynamic website capabilities. For example, the [HTGM Website](https://htgm.meseta.dev) is built and hosted using HyperText GameMaker.

The name HTGM (HyperText GameMaker) is derived from HTML (HyperText Markup Language), indicating that GameMaker can be used to render and output HyperText to the browser. Its principle of operation is that of a server-side scripting language similar to PHP or React SSR, in that each request from the browser is handled by GameMaker project that uses HTGM which renders an HTML document to be sent to the browser to display. HTGM can act as a REST API or Websocket server equally well.

HTGM can be used to host websites if built and deployed to a server, or it can be used to provide browser-based in-game or debugging tools that can run inside a running GameMaker game, as real-time data connectivity is possible through the use of websockets. Giving players or gamedevs access to interactive tools built using web technologies such as HTML and Javascript. Because HTGM is a webserver, it can work with a wide range of web technologies. The demo project includes integration with HTMX, but can be extended to include the use of client-side frameworks such as React or Vue if desired.

HTGM was created by [Meseta](https://meseta.dev), released under the MIT open source license, and is free to use for commercial and non-commercial projects. The project is released as-is, and no support or warranties are provided, but those working on GameMaker projects in general may find help from the friendly [GameMaker community on Discord](https://discord.gg/gamemaker).

## Change History
* v1.3.0
  * Add support for sessions
  * Add freeform context data
  * Add Websocket renderer support
  * Add multiple session cookie support
  * Add more sanitize functions
  * Fix empty form field handling
  * Fix duplicate header handling
  * Fix should_cache handling
* v1.2.0
  * Add form and file upload support
  * Add gzip support for content encoding
  * Support url entities in path and query
  * Add separate Query and Parameter in requests
  * Fixed hang when buffer goes above 65k
  * Fix memory leak for responses
* v1.1.1 Fix query param handling
* v1.1.0 Add redirect functionality to HttpServerRenderBase
* v1.0.0 Initial release