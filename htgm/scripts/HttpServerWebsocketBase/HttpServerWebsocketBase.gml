/** Base constructor for a Websocket renderer */
function HttpServerWebsocketBase() constructor {
	static path = undefined;
	static paths = undefined;
	
	/** Handle function for processing a websocket connection
	 * Must return a websocket session struct, or undefined to reject the connection
	 * @return {Struct.HttpServerWebsocketSessionBase}
	 */
	static handler = function(_context) {
		return undefined;
	}
}