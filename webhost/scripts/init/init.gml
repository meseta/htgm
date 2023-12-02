init_globals();
init_site();

draw_enable_drawevent(false);

GAME = new GameManager();
GAME.set_debug_mode(true);

// make sure we're going to be inside the room when this happens
call_later(1, time_source_units_frames, function() {
	GAME.start();
});
