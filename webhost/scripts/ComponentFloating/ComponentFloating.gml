function ComponentFloating(): HtmlComponent() constructor {
	static element_id = self.auto_id();
	
	static call = call_later(2, time_source_units_seconds, function() { ComponentFloating.average_fps = ComponentFloating.average_fps * 0.99 + fps_real * 0.01; }, true);
	static average_fps = fps_real;
	
	static render = function(_context) {
		static cached = dedent(@'
			<aside style="position: fixed; bottom: 0; right: 0;" hx-ext="ws" ws-connect="/metrics">
				<article style="margin: 0; padding: 0.5em 1em;">
					<div id="'+ self.element_id + @'" ><small>Server stats offline</small></div>
				</article>
			</aside>
		');
		return cached;
	};
	
	static render_content = function() {
		return @'
			<div id="'+ self.element_id +@'" hx-swap-oob="true">
				<small>
				Server fps_real:
				<span style="font-variant-numeric: tabular-nums; display: inline-block; width: 6ch; text-align: right;">'+ string_format(self.average_fps, 0, 0) +@'</span>
				</small>
			</div>
		';	
	}
}

function WebsocketMetrics(): HttpServerWebsocketSessionBase() constructor {
	self.call = call_later(1, time_source_units_seconds, method(self, self.tick), true);
	
	static on_close = function(_close_code=undefined, _close_reason=undefined) {
		call_cancel(self.call);
	};
	
	static tick = function() {
		self.websocket.send_data_string(ComponentFloating.render_content());
	};
}