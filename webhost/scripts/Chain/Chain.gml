/**
 * Creates a chain of callbacks to make it easier (flatter) to write async code
 * @author Meseta https://meseta.dev
 */
function Chain() constructor {
	/* @ignore */ self.__callback_chain = [];
	/* @ignore */ self.__callback_chain_pointer = 0;
	/* @ignore */ self.__errback = undefined;
	/* @ignore */ self.__started = false;
	/* @ignore */ self.__errored = false;
	/* @ignore */ self.__finished = false;
	/* @ignore */ self.__last_result = undefined;
	
	/** Chains further functions onto the end of the chain, ready for execution
	 * @param {Function} _callback The callback to run
	 * @return {Struct.Chain}
	 */
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
	
	/** Adds a call_later into the chain here, so when the call gets to this point we fire off a delay
	 * @param {Number} _time The number of seconds
	 * @return {Struct.Chain}
	 */
	static chain_delay = function(_time) {
		self.chain_callback(method({this: other, time: _time}, function(_result) {
			result = _result;
			call_later(time, time_source_units_seconds, function() {
				this.__accept(result);
			});
			return Chain.DEFERRED;
		}));
		return self;
	};
	
	/** Adds a convenience step in the chain to output log the result 
	 * @param {String} _debug_text Text to add
	 * @param {Struct.Logger} _logger The logger to use
	 * @return {Struct.Chain}
	 */
	static chain_debug_log = function(_debug_text="Chain debug log", _logger=undefined) {
		self.chain_callback(method({debug_text: _debug_text, logger: _logger}, function(_result) {
			if (!is_undefined(logger)) {
				logger.debug(debug_text, {result: _result})
			}
			else {
				show_debug_message(debug_text, result);	
			}
			return _result;
		}));
		return self;
	};
	
	/** Sets the error handle for the whole chain. there can only be one of these
	 * @param {Function} _errback The callback to run on error
	 * @return {Struct.Chain}
	 */
	static on_error = function(_errback) {
		if (is_undefined(_errback)) {
			return self;	
		}
		self.__errback = _errback;
		return self;
	};
	
	/** Creates a callback, and mark as started. the expectation is the firing callback will start the chain
	 * @return {Function}
	 */
	static create_start_callback = function() {
		self.__started = true;
		return method(self, self.__accept);
	};
	
	/** Creates a callback, which will continue the chain
	 * @return {Function}
	 */
	static create_callback = function() {
		return method(self, self.__accept);
	};
	
	/** Creates an errback that can be called, which will end the chain
	 * @return {Function}
	 */
	static create_errback = function() {
		return method(self, self.__fire_errback);
	};
	
	/** Unconditional start 
	 * @param {Any*} _initial_value The initial value to be passed to the first callback
	 */
	static start = function(_initial_value=undefined) {
		if (!self.__started) {
			self.__started = true;
			self.__accept(_initial_value);
		}
		return self;
	}
	
	/** Runs the errorback
	 * @param {Any*} _err The error to use
	 * @ignore
	 */
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
	
	/** Accept return value and run chain
	 * @param {Any*} _result The result to pass onto the chain
	 * @ignore
	 */
	static __accept = function(_result) {
		self.__last_result = _result;
		self.__run_chain();
	};
	
	/** Runs the chain 
	 * @param {Function*} _callback
	 * @param {Function*} _errback
	 * @return {Struct.Chain}
	 * @ignore
	 */
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
			
			if (is_instanceof(_result, Chain)) {
				// if the return value is another chain, then we attach ourselves to it
				_result.chain_callback(_callback);
				_result.on_error(_errback);
				return self;
			}
			
			if (_result == Chain.DEFERRED) {
				// the return value indicates that we should wait for the chain to asynchronously call its callback
				return self;
			}
			
			// prepare for next run
			self.__last_result = _result;
		}
		self.__finished = true;
		return self;
	};

	/** Utility function to execute an array of Chains concurrently and create a new Chain
	 * Works by attaching a callback on the end of every chain that checks for and runs this one
	 * WARNING: this overrides each member chain's onerr function
	 * @param {Array<Struct.Chain>} _chain_array Array of chains
	 * @return {Struct.Chain}
	 */
	static concurrent_array = function(_chain_array) {
		// Loop over array to ensure only chains are added
		var _filtered_chain_array = array_filter(_chain_array, function(_chain) { return is_instanceof(_chain, Chain); });
	
		var _len = array_length(_filtered_chain_array);
		var _completion_chain = new Chain();
	
		if (_len > 0) {
			var _completion_check = method(
				{
					callback: _completion_chain.create_start_callback(),
					completion_count: 0,
					chain_number: _len,
				},
				function() {
					completion_count += 1;
					if (completion_count == chain_number) {
						callback();	
					}
				}
			)
			var _on_error = _completion_chain.create_errback();
		
			array_foreach(_filtered_chain_array, method({completion_check: _completion_check, on_error: _on_error}, function(_chain) {
				_chain.chain_callback(completion_check).on_error(on_error);
			}));
		}
		else {
			_completion_chain.start();
		}
		
		return _completion_chain;
	};
	
	/** Alias for concurrent_array using the argument array */
	static concurrent = function(_chains=undefined) {
		var _chain_array = array_create(argument_count);
		for (var _i=0; _i<argument_count; _i++) {
			_chain_array[_i] = argument[_i];
		}
		return Chain.concurrent_array(_chain_array);
	}

	/** Utility function to execute a struct of Chains concurrently and create a new Chain
	 * with the result. Works by attaching a callback on the end of every chain that checks for and runs this one
	 * WARNING: this overrides each member chain's onerr function
	 * @param {Struct} _chain_struct Struct of chains and other values
	 * @return {Struct.Chain}
	 */
	static concurrent_struct = function(_chain_struct) {
		
		// Loop over struct to ensure only chains are added
		var _results = {};
		var _chain_name_pairs = [];
		struct_foreach(_chain_struct, method({results: _results, chain_name_pairs: _chain_name_pairs}, function(_name, _chain) {
			if (is_instanceof(_chain, Chain)) {
				array_push(chain_name_pairs, [_chain, _name]);	
			}
			else {
				results[$ _name] = _chain;	
			}
		}));
	
		var _len = array_length(_chain_name_pairs);
		var _completion_chain = new Chain();
	
		if (_len > 0) {
			var _completion_check = method(
				{
					callback: _completion_chain.create_start_callback(),
					completion_count: 0,
					chain_number: _len,
					results: _results,
				},
				function(_name, _result) {
					completion_count += 1;
					results[$ _name] = _result;
					if (completion_count == chain_number) {
						callback(results);
					}
				}
			)
			var _on_error = _completion_chain.create_errback();
		
			array_foreach(_chain_name_pairs, method({completion_check: _completion_check, on_error: _on_error}, function(_chain_name_pair) {
				var _chain = _chain_name_pair[0];
				var _name = _chain_name_pair[1];
				_chain.chain_callback(method({completion_check: completion_check, name: _name}, function(_result) { completion_check(name, _result) })).on_error(on_error);
			}));
		}
		else {
			_completion_chain.start(_results);
		}
		
		return _completion_chain;
	};
	
	
	/**
	 * This is a sentinel that should be returned from a chain in order to signal that the response is deferred
	 * (i.e. the asynchronous callbacks will be used instead, which will halt the callback chain processing until those async callbacks are called)
	 * The method is deliberately empty
	 */
	/// Feather ignore once GM2017
	static DEFERRED = {};
}

// initialize statics
new Chain();