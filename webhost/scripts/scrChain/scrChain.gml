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
}

function chain_concurrent_struct(_chain_struct) {
	// works by attaching a callback on the end of every chain that checks for and runs this one
	// WARNING: this overrides each member chain's onerr function
	
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
}

/**
 * This is a sentinel constructor that should be returned from a chain in order to signal that the response is deferred
 * (i.e. the asynchronous callbacks will be used instead, which will halt the callback chain processing until those async callbacks are called)
 * The method is deliberately empty
 */
function ChainDeferred() constructor {}
