/** De-indent a string, automatically detecting the indentation of the first line, and subtracting the same indent from subsequent lines if they exist
 * @param {String} _string String to de-dent
 * @param {String} _insert String to insert at the start of every line
 * @return {String}
 */
function dedent(_string, _insert=""){
	var _lines = string_split_ext(_string, ["\r\n", "\r", "\n"]);
	var _lines_len = array_length(_lines);
	
	// find indent of first non-empty line
	var _space_string = "";
	var _space_len = 0;
	var _empty_lines = 0;
	for (var _i=0; _i<_lines_len; _i++) {
		var _line = _lines[_i];
		var _line_len = string_length(_line);
		
		for (var _j=0; _j<_line_len; _j++) {
			var _char = string_char_at(_line, _j+1);
			if (_char != " " && _char != "\t") {
				if (_j > 0) {
					_space_string = string_copy(_line, 1, _j);
					_space_len = _j;
				}
				break;
			}
		}
		
		if (_space_string == "") {
			_empty_lines += 1;
		}
		else {
			break;
		}
	}
	
	array_delete(_lines, 0, _empty_lines);
	
	if (_space_len > 0) {
		array_foreach(_lines, method({lines: _lines, space_string: _space_string, space_len: _space_len, insert: _insert}, function(_line, _idx) {
			if (string_pos(space_string, _line) == 1) {
				lines[_idx] = insert+string_delete(_line, 1, space_len);
			}
		}));
	}
	return string_join_ext("\n", _lines); 
}
