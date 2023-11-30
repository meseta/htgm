/**
 * @desc The game manager! Provides overall game state
**/
function GameManager() constructor {
	/* @ignore */ self.__logger = LOGGER.bind_named("GameManager", {config: OS_CONFIG});
	/* @ignore */ self.__debug_mode = false;
	
	/* @ignore */ self.__fsm = new SnowState("init");
	
	// Set up state machine
	self.__fsm.on("state changed", function(_dest_state, _source_state, _trigger_name) {
		self.__logger.info("State Change", {source_state: _source_state, dest_state: _dest_state, trigger_name: _trigger_name }, LOG_TYPE_NAVIGATION);
	});
	self.__fsm.add("init");
	self.__fsm.add("running", {
		enter: function() {
			SERVER.start();
		},
		leave: function() {
			SERVER.stop();
		}
	});
	self.__fsm.add_transition("t_start", "init", "running");

	/**
	 * @desc Sets the game's debug mode
	 * @param {Bool} _mode Whether to turn debug mode on or off
	 * @return {Struct.GameManager}
	**/
	static set_debug_mode = function(_mode=true) {
		self.__debug_mode = _mode;
		return self;
	};
	
	/**
	 * @desc Trigger a mode change in the game
	 * @param {String} _trigger_name State machine trigger
	 * @return {Bool} Whether trigger was successful
	**/
	static trigger = function(_trigger_name) {
		var _current_state = self.__fsm.get_current_state();
		if (self.__fsm.transition_exists(_trigger_name, _current_state) || self.__fsm.transition_exists(_trigger_name, "*")) {
			return self.__fsm.trigger(_trigger_name);
		}
		else {
			self.__logger.error("Couldn't trigger game state change, trigger doesn't exist", {trigger_name: _trigger_name, current_state: _current_state}, LOG_TYPE_NAVIGATION);
			return false;
		}
	};
	
	/**
	 * @desc Trigger the game start trigger
	 * @return {Bool} Whether trigger was successful
	**/
	static start = function() {
		return self.trigger("t_start");
	};
}
