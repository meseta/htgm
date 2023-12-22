/** Replaces the ` character with ' and `` with ", as quote characters are problematic for gamemaker multi-line string
 * so we use ` and `` as stand-in replacements when defining string literals
 * @param {String} _string String to fix quotes on
 * @return {String}
 */
function quote_fix(_string) {
	_string = string_replace_all(_string, "``", @'"');
	_string = string_replace_all(_string, "`", "'");
	return _string;
}