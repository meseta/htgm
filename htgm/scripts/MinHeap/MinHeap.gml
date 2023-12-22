/** A min-heap implementation (i.e. priority queue). value-priority pairs can be inserted into the heap, which wil
 * efficiently maintain sort order, and the minimum priorty value can be queried at any time
 * @author Meseta https://meseta.dev
 */
function MinHeap() constructor {
	/* @ignore */ self.__values = []; //  Heap-ordered storage. array of value/priority pairs, the zerth index is maintained to be lowest priority
	/* @ignore */ self.__length = 0;

	/** Returns how many elements are in the heap
	 * @return {Real}
	 */
	static get_length = function() {
		return self.__length;
	};
	
	/** Insert a value into the heap
	 * @param {Any} _value The value to insert
	 * @param {Real} _priority The priority of the value to insert, can be any number
	 */
	static insert = function(_value, _priority) {
		array_push(self.__values, [_value, _priority]);
		self.__length += 1
		self.__shift_up(self.__length-1);
	};
	
	/** Removes the lowest value/priority pair from the heap, and returns it as an array
	 * in the format [value, priority]; undefined will be returned if there's no values available
	 * @return {Array*}
	 */
	static pop_min = function() {
		if (self.__length == 0) {
			return undefined;
		}
		var _result = self.__values[0];
		self.__remove_min();
		return _result
	};
	
	/** Removes the lowest value/priority pair from the heap, and returns the value
	 * @return {Any*}
	 */
	static pop_min_value = function() {
		if (self.__length == 0) {
			return undefined;
		}
		var _result = self.__values[0][0];
		self.__remove_min();
		return _result;
	};
	
	/** Removes the lowest value/priority pair from the heap, and returns the priority
	 * @return {Real*}
	 */
	static pop_min_priority = function() {
		if (self.__length == 0) {
			return undefined;
		}
		var _result = self.__values[0][1];
		self.__remove_min();
		return _result;
	};
	
	/** Fetch the lowest value/priority pair from the heap without removing it, and returns it as an array
	 * in the format [value, priority]; undefined will be returned if there's no values available
	 * @return {Array*}
	 */
	static peek_min = function() {
		return self.__length ? self.__values[0] : undefined;
	};
	
	/** Fetch the value of lowest priority value from the heap without removing it
	 * @return {Any*}
	 */
	static peek_min_value = function() {
		return self.__length ? self.__values[0][0] : undefined;
	};
	
	/** Fetch the lowest priority value from the heap without removing it
	 * @return {Real*}
	 */
	static peek_min_priority = function() {
		return self.__length ? self.__values[0][1] : undefined;
	};
	
	/** Clears the heap, resetting it to blank */
	static clear = function() {
		self.__values = [];
		self.__length = 0;
	};
	
	/** Internal function for managing the heap. Removes the lowest priority value from the heap
	 * @ignore
	 */
	static __remove_min = function() {
		self.__length -= 1;
		self.__values[0] = self.__values[self.__length];
		array_resize(self.__values, self.__length);
		self.__shift_down(0);
	};
		
	/** Internal function for managing the heap. Shift all the priority values down
	 * @ignore
	 */
	static __shift_down = function(_idx) {
		var _max_idx = _idx;
		
		var _left = self.__left_child(_idx);
		
		if (_left < self.__length && self.__values[_left][1] < self.__values[_max_idx][1]) {
			_max_idx = _left;	
		}
		
		var _right = self.__right_child(_idx);
		if (_right < self.__length && self.__values[_right][1] < self.__values[_max_idx][1]) {
			_max_idx = _right;	
		}
		
		if (_idx != _max_idx) {
			self.__swap(_idx, _max_idx);
			self.__shift_down(_max_idx);
		}
	};
		
	/** Internal function for managing the heap. Shift all the values up
	 * @ignore
	 */
	static __shift_up = function(_idx) {
		while(_idx > 0) {
			var _parent_idx = self.__parent(_idx);
			if (self.__values[_parent_idx][1] <= self.__values[_idx][1]) {
				break;
			}
			self.__swap(_parent_idx, _idx);
			_idx = _parent_idx;
		}
	};
	
	/** Internal function for managing the heap. Get the parent index in the heap index system
	 * @param {Real} _idx the index to get the parent of
	 * @return {Real}
	 * @pure
	 * @ignore
	 */
	static __parent = function(_idx) {
		return (_idx - 1) div 2;
	};
	
	/** Internal function for managing the heap. Get the left child index in the heap index system
	 * @param {Real} _idx the index to get the left child of
	 * @return {Real}
	 * @pure
	 * @ignore
	 */
	static __left_child = function(_idx) {
		return (2*_idx) + 1;	
	};
		
	/** Internal function for managing the heap. Get the right child index in the heap index system
	 * @param {Real} _idx the index to get the right child of
	 * @return {Real}
	 * @pure
	 * @ignore
	 */
	static __right_child = function(_idx) {
		return (2*_idx) + 2;	
	};
	
	/** Internal function for managing the heap. Swaps two indexes
	 * @param {Real} _left_idx one of the indices to swap
	 * @param {Real} _right_idx the other index to swap
	 * @ignore
	 */
	static __swap = function(_left_idx, _right_idx) {
		var _temp = self.__values[_left_idx];
		self.__values[_left_idx] = self.__values[_right_idx];
		self.__values[_right_idx] = _temp;
	};
}