function Iterators() constructor {
	/** A version of array_foreach that can be interrupted by throwing Iterators.STOP_ITERATION, returning whether iteration completed or not
	 * @param {Array} _array An array to iterate over
	 * @param {Function} _function Delegate to run
	 * @return {Bool} something
	 */
	static foreach = function(_array, _function) {
		try {
			array_foreach(_array, _function);
		}
		catch (_err) {
			if (_err == Iterators.STOP_ITERATION) {
				return false;
			}
			throw _err;
		}

		return true;
	}
	
	/** A sentinel value that can be thrown to signal stopping iterations */
	/// Feather ignore once GM2017
	static STOP_ITERATION = {};
}

// initialize statics
new Iterators();