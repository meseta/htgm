init_globals();
init_site();


// development options
if (OS_CONFIG == "Development") {
	
}
else {
	// slow everything down
	game_set_speed(20, gamespeed_fps);

	// turn off drawing
	draw_enable_drawevent(false);
	
	// don't ask to send sentry errors
	SENTRY.set_option("ask_to_send", false);
	SENTRY.set_option("ask_to_send_report", false);
	
	// Use Sentry's error handler
	exception_unhandled_handler(global.sentry.get_exception_handler());
}



// Wait 1 second to ensure previous process was closed,
// and to make sure we're going to be inside the room when this happens
call_later(2, time_source_units_seconds, function() {
	SERVER.start();
	
	if(OS_CONFIG == "Development") {
		url_open($"http://localhost:{SERVER.port}/");
	}
});
