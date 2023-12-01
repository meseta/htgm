/**
 * Creates a chain of callbacks to make it easier (flatter) to write  the instance to ending point, from optional starting point
 * One limitation is that chains can only make use of a single function argument and return value. but these can be arrays.
 * 
 * Example 1:
 * A framework developer implementing chains in their async code can allow the user developer to receive a chain as a return value
 * which they can chain callbacks to, and which the framework dev's code will later fire off the callbacks for when the async
 * process completes.
 *
 * The framework developer's code looks like this:
 *
 *		function fetch_value_from_internet(_arg1) {
 *			var _chain = new Chain();
 *			set_up_the_fetching(_arg1, _chain.create_start_callback(), _chain.create_errback()); // this function will later call _chain.fire_callback(_result)
 *			return _chain;
 *		}
 *
 * The user developer's code using this framework looks like this:
 *
 *		fetch_value_from_internet(_arg1)
 *			.chain_callback(function(_result) {
 *				if (_result < 0) {
 *					throw "uh oh"
 *				}
 *				return fetch_another_value_from_internet(sqrt(_result));
 *			})
 *          .chain_delay(2)
 *			.chain_callback(function(_result) {
 *				deal_with_it(_result, 123);
 *			})
 *			.on_error(function(_err) {
 *				logger.info("something went wrong", {err: _err});
 *			})
 *	
 * Where before the equivalent code may have looked like this:
 * (where fetch_value_from_internet's arguments includes providing a callback and errorback)
 * 
 *		fetch_value_from_internet(
 *			_arg1,
 *			function(_result) {
 *				if (_result < 0) {
 *					logger.error("something went wrong", {err: "uh oh"});
 *				}
 *				fetch_another_value_from_internet(
 *					sqrt(_value),
 *					function(_result) {
 *						deal_with_it(_result, 123);
 *					},
 *					function(_err) {
 *						logger.error("something went wrong", {err: _err});
 *					}
 *				);
 *			},
 *			function(_err) {
 *				logger.error("something went wrong", {err: _err});
 *			}
 *		);
 *
 * 
 * Example 2:
 * If a user needs to do further asynchronous work, user may return a new ChainDeferred() to indicate that
 * the chain execution should wait until an async callback is run. Each chain is called with _callback and _errback callbacks
 * that can later be called to continue processing
 *
 *		fetch_value_from_internet(_arg1)
 *			.chain_callback(function(_result, _callback) {
 *              call_later(10, time_source_units_seconds, method({callback: _callback, result: _result}, function() { callback(sqrt(result)); }), false);
 *				return new ChainDeferred();
 *			})
 *			.chain_callback(function(_result) {
 *				deal_with_it(_result, 123);
 *			})
 *			.on_error(function(_err) {
 *				logger.info("something went wrong", {err: _err});
 *			})
 *
 * Example 3:
 * A user may return another Chain, it will be executed as well
 *
 *		fetch_value_from_internet(_arg1)
 *			.chain_callback(function(_result) {
 *              call_later(10, time_source_units_seconds, method({callback: _callback, result: _result}, function() { callback(sqrt(result)); }), false);
 *				return new ChainDeferred();
 *			})
 *			.chain_callback(function(_result) {
 *				deal_with_it(_result, 123);
 *			})
 *			.on_error(function(_err) {
 *				logger.info("something went wrong", {err: _err});
 *			})
 *
 *
 *
 */
 
function Chain() constructor {
	/** The list of callbacks that will be executed as we go */
	self.__callback_chain = [];

	/** The pointer into the callback array. We use this to point at the next function to execute */
	self.__callback_chain_pointer = 0;
	
	/** The error that will be run if an exception is thrown */
	self.__errback = undefined;
	
	/** Whether this chain has started */
	self.__started = false;
	
	/** Whether this chain has already errored, preventing any further execution */
	self.__errored = false;
	
	/** Whether this chain has already finished executing, if so, any new methods added to it will fire immediately */
	self.__finished = false;
	
	/** The stored last value, for chains that might finish execution, and will continue once the next callback is added to it */
	self.__last_result = undefined;
	
	/** Chains further functions onto the end of the chain, ready for execution */
	static chain_callback = function(_callback) {
		if (is_undefined(_callback)) {
			return self;
		}
		
		array_push(self.__callback_chain, _callback);
		
		if (self.__finished && !self.__errored) {
			// if chain was already finished, we're allowed to mark as unfinished and continue execution
			self.__finished = false;
			self.__run_chain();
		}
		
		return self;
	};
	
	/** Adds a call_later into the chain here, so when the call gets to this point we fire off a delay */
	static chain_delay = function(_time) {
		self.chain_callback(method({this: other, time: _time}, function(_result) {
			result = _result;
			call_later(time, time_source_units_seconds, function() {
				this.__accept(result);
			});
			return new ChainDeferred();
		}));
		return self;
	};
	
	/** Adds a convenience step in the chain to output log the result */
	static chain_debug_log = function(_debug_text="Chain debug log") {
		self.chain_callback(method({debug_text: _debug_text}, function(_result) {
			LOGGER.debug(debug_text, {result: _result})
			return _result;
		}));
		return self;
	};
	
	/** Sets the error handle for the whole chain. there can only be one of these */
	static on_error = function(_errback) {
		if (is_undefined(_errback)) {
			return self;	
		}
		self.__errback = _errback;
		return self;
	};
	
	/** Convenience function to add a simple logger to the error */
	static on_error_log = function() {
		self.__errback = self.__log_error;
		return self;
	};
	
	/** Creates a callback, and mark as started. the expectation is the firing callback will start the chain */
	static create_start_callback = function() {
		self.__started = true;
		return method(self, self.__accept);
	};
	
	/** Creates a callback, which will continue the chain*/
	static create_callback = function() {
		return method(self, self.__accept);
	};
	
	/** Creates an errback that can be called, which will end the chain*/
	static create_errback = function() {
		return method(self, self.__fire_errback);
	};
	
	/** Unconditional start */
	static start = function(_initial_value=undefined) {
		if (!self.__started) {
			self.__started = true;
			self.__accept(_initial_value);
		}
		return self;
	}
	
	/** Runs the errorback */
	static __fire_errback = function(_err) {
		if (self.__errored) {
			return;
		}
		
		self.__errored = true;
		if (is_method(self.__errback)) {
			self.__errback(_err);
		}
		else {
			throw _err;	
		}
	};
	
	/** Accept return value and run chain */
	static __accept = function(_result) {
		self.__last_result = _result;
		self.__run_chain();
	};
	
	/** Runs the chain */
	static __run_chain = function(_callback=undefined, _errback=undefined) {
		_callback ??= self.create_callback(); // iff callback is not provided, we use our own
		_errback ??= self.create_errback(); // if errback is not provided, we use our own
		
		while (self.__callback_chain_pointer < array_length(self.__callback_chain)) {
			if (self.__errored || self.__finished) {
				return;
			}
		
			// increment the pointer, and fetch the next thing to run
			var _pointer = self.__callback_chain_pointer;
			var _next = self.__callback_chain[_pointer];
			self.__callback_chain_pointer += 1;
			self.__callback_chain[_pointer] = undefined; // clear entry to free function for GC

			var _result;
			if(is_callable(_next)) {
				try {
					_result = _next(self.__last_result, _callback, _errback);
				}
				catch (_err) {
					_result = _errback(_err);
					self.__errored = true;
					return;
				}
			}
			else {
				_errback("Next value ("+string(_pointer)+") in chain is not a method");	
				return;
			}
			
			if (instanceof(_result) == script_get_name(Chain)) {
				// if the return value is another chain, then we attach ourselves to it
				_result.chain_callback(_callback);
				_result.on_error(_errback);
				return self;
			}
			
			if (instanceof(_result) == script_get_name(ChainDeferred)) {
				// the return value indicates that we should wait for the chain to asynchronously call its callback
				return self;
			}
			
			// prepare for next run
			self.__last_result = _result;
		}
		self.__finished = true;
		return self;
	};
	
	/** Simple function for logging the error, which can be used as the errback */
	static __log_error = function(_err) {
		LOGGER.error("Chain error", {err: _err})
	};
}