init_globals();


SERVER.add_path(
	"", 
	/// @param {Struct.HttpRequest} _request @param {Struct.HttpResponse} _response
	function(_request, _response) {
		_response.send_string("hello world!");
	}
);

GAME = new GameManager();
GAME.set_debug_mode(true);

// make sure we're going to be inside the room when this happens
call_later(1, time_source_units_frames, function() {
	GAME.start();
});