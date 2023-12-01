function chain_concurrent() {
	var _chain_array = array_create(argument_count);
	for (var _i=0; _i<argument_count; _i++) {
		_chain_array[_i] = argument[_i];
	}
	return chain_concurrent_array(_chain_array);
}

function chain_concurrent_array(_chain_array) {
	// works by attaching a callback on the end of every chain that checks for and runs this one
	// WARNING: this overrides each member chain's onerr function
	
	var _len = array_length(_chain_array);
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
		
		for (var _i=0; _i<_len; _i++) {
			var _chain = _chain_array[_i];
			_chain.chain_callback(_completion_check).on_error(_on_error);
		}
	}
	else {
		_completion_chain.start();
	}
		
	return _completion_chain;
}

/**
 * This is a sentinel constructor that should be returned from a chain in order to signal that the response is deferred
 * (i.e. the asynchronous callbacks will be used instead, which will halt the callback chain processing until those async callbacks are called)
 * The method is deliberately empty
 */
function ChainDeferred() constructor {}
