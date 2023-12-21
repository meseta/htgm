init_globals();
init_site();

draw_enable_drawevent(false);

GAME = new GameManager();
GAME.set_debug_mode(true);

// Wait 1 second to ensure previous process was closed,
// and to make sure we're going to be inside the room when this happens
call_later(2, time_source_units_seconds, function() {
	GAME.start();
});
