/** A Code block used for code documentation
 * @param {String} _code The code, as a string
 */
function HtmlCode(_code, _language="gml"): HtmlComponent() constructor {
	
	_code = string_replace_all(_code, "<", "&lt;");
	_code = string_replace_all(_code, ">", "&gt;");
	_code = string_trim_end(quote_fix(_code));
	self.code = $"<pre><code class='language-{_language}'>{_code}</code></pre>";

	static render = function(_context) {
		return self.code;
	}
}