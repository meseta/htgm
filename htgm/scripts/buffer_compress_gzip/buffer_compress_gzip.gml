/** Compresses a buffer using gzip (deflate)
* @param {Id.Buffer} _buffer The buffer to compress
* @param {Real} _offset the offset in buffer to start compressing
* @param {Real} _size the number of bytes to compress
* @return {ID.Buffer}
*/
function buffer_compress_gzip(_buffer, _offset, _size) {
	var _crc = buffer_crc32_iso3309(_buffer, _offset, _size);

	// compress using normal deflate
	var _deflate_buffer = buffer_compress(_buffer, _offset, _size);
	var _deflate_buffer_size = buffer_get_size(_deflate_buffer);
	var _gzip_buffer_size = _deflate_buffer_size+12;
	_buffer = buffer_create(_gzip_buffer_size, buffer_fixed, 1);
	// header
	buffer_write(_buffer, buffer_u32, 0x00088b1f); // gzip magic, compression method, header flags
	buffer_write(_buffer, buffer_u32, 0x00000000); // gzip timestamp (we're not using it)
	buffer_write(_buffer, buffer_u16, 0x0b00); // gzip compresion flags
	// payload
	buffer_copy(_deflate_buffer, 2, _deflate_buffer_size-6, _buffer, 10);
	buffer_delete(_deflate_buffer);
	// CRC
	buffer_seek(_buffer, buffer_seek_end, 8);
	buffer_write(_buffer, buffer_u32, _crc);
	// length
	buffer_write(_buffer, buffer_u32, _size);
	return _buffer;
}
