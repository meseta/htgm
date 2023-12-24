/** A file that was uploaded as part of the request
 * @param {Id.Buffer} _buffer Buffer that contains file data
 * @param {Real} _size size of buffer
 * @param {String*} _content_type known content type
 * @param {String*} _filename known filename
 */
function HttpRequestFile(_buffer, _size, _content_type=undefined, _filename=undefined) constructor {
	self.buffer = _buffer;
	self.size = _size;
	self.content_type = _content_type;
	self.filename = _filename;
		
	static cleanup = function() {
		if (buffer_exists(self.buffer)) {
			buffer_delete(self.buffer);	
		}
	};
}