/** A Code block used for code documentation
 * @param {String} _code The code, as a string
 */
function HtmlCode(_code, _language="gml"): HtmlComponent() constructor {
	var _clean = string_trim_end(convert_backticks(sanitize_tags(_code)));
	self.code = $"<pre><code class='language-{_language}'>{_clean}</code></pre>";

	static render = function(_context) {
		return self.code;
	}
}