/** A base session handler base for websockets */
function HttpServerWebsocketSessionBase() constructor {
	self.websocket = undefined;
	
	/** Function that will be called when websocket connects 
	 * @param {Struct.HttpServerWebsocket} _websocket The websocket in question
	 */
	static on_connect = function(_websocket) {
		self.websocket = _websocket;
	};
	
	/** Function that will be called when data is received
	 * @param {Id.Buffer} _buffer The buffer that was received
	 * @param {Bool} _is_string Whether the incoming packet type was a string
	 */
	static on_data_buffer = function(_buffer, _is_string) {};
	
	/** Function that will be called when incoming close is received
	 * @param {Real} _close_code The close code received
	 * @param {String} _close_reason The close reason received
	 */
	static on_close = function(_close_code=undefined, _close_reason=undefined) {}
}
