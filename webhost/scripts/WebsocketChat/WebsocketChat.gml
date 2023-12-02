/** A base session handler base for websockets */
function WebsocketChat(): HttpServerWebsocketSessionBase() constructor {
	global.chat.register_client(self);
	
	/** Function that will be called when data is received from websocket
	 * @param {Id.Buffer} _buffer The buffer that was received
	 * @param {Bool} _is_string Whether the incoming packet type was a string
	 */
	static on_data_buffer = function(_buffer, _is_string) {
		var _text = buffer_read(_buffer, buffer_text);
		var _json = json_parse(_text);
		global.chat.broadcast(_json.chat_message);
	}
	
	/** Function that will be called when chat system wants to broadcast data to everyone
	 * @param {String} _text
	 */
	static on_broadcast = function(_text) {
		if (_text == "cat") {
			var _cat = new HtmxSprite(sTest);
			self.websocket.send_data_string(dedent(@'
				<div id="chat_room" hx-swap-oob="beforeend">
				    '+ _cat.render() +@'<br />
				</div>
			'));
		}
		else {
			self.websocket.send_data_string(dedent(@'
				<div id="chat_room" hx-swap-oob="beforeend">
				    '+ _text +@'<br />
				</div>
			'));
		}
	}
}

function ChatSystem() constructor {
	self.clients = [];
	
	static register_client = function(_client) {
		array_push(self.clients, weak_ref_create(_client));	
	}
	
	static broadcast = function(_text) {
		var _len = array_length(self.clients);
		for (var _i=_len-1; _i>=0; _i--) {
			var _client = self.clients[_i];
			if (weak_ref_alive(_client)) {
				_client.ref.on_broadcast(_text);	
			}
			else {
				array_delete(self.clients, _i, 1);	
			}
		}
	}
}

global.chat = new ChatSystem();