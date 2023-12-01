init_globals();

SERVER.add_file_server("static/*", "static");

SERVER.add_render(HtmxPage1);
SERVER.add_render(HtmxPage2);
SERVER.add_render(HtmxMain);

GAME = new GameManager();
GAME.set_debug_mode(true);

// make sure we're going to be inside the room when this happens
call_later(1, time_source_units_frames, function() {
	GAME.start();
});