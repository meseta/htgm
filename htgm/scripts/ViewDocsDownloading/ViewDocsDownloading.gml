function ViewDocsDownloading(): HtmxView() constructor {
	// View setup
	static path = "docs/downloading";
	static redirect_path = "docs";
	static should_cache = true;
	
	static render = function(_context) {
		static cached = @'
			<title>Downloading</title>
			<h1>Downloading</h1>
			<p>
				You can download just the HTGM library itself, which contains only the library ready for you to create
				a web server iny our own project, or you can download the project that is this website.
			</p>
			
			<h2>HTGM Library</h2>
			<p>
				To downlaod the library, click on the latest version in <a href="https://github.com/meseta/htgm/releases">the releases on GitHub</a>
				and download the file called <code>dev.meseta.htgm.yymps</code>. This is a GameMaker local
				package, and can be imported into your project via the <code>Tools &gt; Import Local Package</code>
				Menu.
			</p>
			
			<h2>HTGM Website</h2>
			<p>
				The source code zip file contains the source code for this website. If you want, you can
				download this, fire up GameMaker, and run your own copy of this website. The code for 
				this website has been open-sourced to serve as a demo/example website for use as reference.
			</p>
			<p>
				The style and layout of this website is also open source, you are free to re-use the style and
				layout for your own website, though you may want to customize the colors, content, and graphics.
				No credit is necessary.
			</p>
		';
		return cached;
	}
}
