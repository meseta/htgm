/** A Code block used for code documentation
 * @param {String} _code The code, as a string
 */
function HtmlCode(_code, _language="gml"): HtmlComponent() constructor {
	
	_code = string_replace_all(_code, "<", "&lt;");
	_code = string_replace_all(_code, ">", "&gt;");
	
	// by adding a space at the start of the line, we can prevent it from being further dedented by accident
	// if this code block is included in a parent component that also dedents
	_code = dedent(_code, " "); 
	_code = string_trim_end(quote_fix(_code));
	self.code = $"<pre><code class='language-{_language}'>{_code}</code></pre>";

	static render = function(_context) {
		return self.code;
	}
}