/** Compute the ISO3309 CRC, which is different to gamemaker's buffer_crc32 function
* @param {Id.Buffer} _buffer The buffer to compress
* @param {Real} _offset the offset in buffer to start compressing
* @param {Real} _size the number of bytes to compress
* @return {Real}
*/
function buffer_crc32_iso3309(_buffer, _offset, _size) {
	// Pre-calculated CRC table
	static _crc_table = undefined;
	if (is_undefined(_crc_table)) {
		_crc_table = array_create(256);

		for (var _i=0; _i<256; _i++) {
			var _c = _i;
			repeat(8) {
				if (_c & 0x1) {
					_c = 0xedb88320 ^ (_c >> 1);
				}
				else {
					_c = _c >> 1;
				}
			}
			_crc_table[_i] = _c;
		}
	}
	
	// Calculate CRC of buffer
	var _old_seek = buffer_tell(_buffer);
	var _crc = 0xffffffff;
	buffer_seek(_buffer, buffer_seek_start, _offset);
	repeat(_size) {
		var _byte = buffer_read(_buffer, buffer_u8);
		_crc = _crc_table[(_crc ^ _byte) & 0xff] ^ (_crc >> 8);
	}
	_crc = (_crc ^ 0xffffffff) & 0xffffffff;
	// put buffer pointer back where it was before
	buffer_seek(_buffer, buffer_seek_start, _old_seek);
	return _crc;
}
