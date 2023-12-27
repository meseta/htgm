/** Replaces the ` character with ', as quote characters are problematic for gamemaker multi-line string
 * so we use ` as stand-in replacements when defining string literals
 * @param {String} _string
 * @return {String}
 */
function convert_backticks(_string) {
	return string_replace_all(_string, "`", "'");;
}

/** Replaces the " and ' with HTML entities
 * @param {String} _string
 * @return {String}
 */
function sanitize_quotes(_string) {
	return string_replace_all(string_replace_all(_string, "'", "&apos;"), @'"', "&quot;");
}

/** Removes the " and '
 * @param {String} _string
 * @return {String}
 */
function strip_quotes(_string) {
	return string_replace_all(string_replace_all(_string, "'", ""), @'"', "");
}


/** Replaces the < adn > with HTML entities
 * @param {String} _string
 * @return {String}
 */
function sanitize_tags(_string) {
	return string_replace_all(string_replace_all(_string, "<", "&lt;"), ">", "&gt;");
}
