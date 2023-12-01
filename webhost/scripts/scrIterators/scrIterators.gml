/** An object that can be thrown to signal stopping iterations */
function ExceptionStopIteration() constructor {}

/** A version of array_foreach that can be interrupted by throwing ExceptionStopIteration, returning whether iteration completed or not
 * @param {Array} _array An array to iterate over
 * @param {Function} _function Delegate to run
 * @return {Bool} something
 */
function array_foreach_interruptible(_array, _function) {

	try {
		array_foreach(_array, _function);
	}
	catch (_err) {
		if (is_instanceof(_err, ExceptionStopIteration)) {
			return false;
		}
		throw _err;
	}

	return true;
}