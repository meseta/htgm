function HttpBufferUtils() constructor {
	/** Compresses a buffer using gzip (deflate)
	* @param {Id.Buffer} _buffer The buffer to compress
	* @param {Real} _offset the offset in buffer to start compressing
	* @param {Real} _size the number of bytes to compress
	* @return {ID.Buffer}
	*/
	static compress_gzip = function(_buffer, _offset, _size) {
		var _crc = self.crc32_iso3309(_buffer, _offset, _size);

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
	
	/** Creates a PNG inside a buffer from a surface
	* @param {Id.Surface} _surface The surface to create PNG from
	* @return {ID.Buffer}
	*/
	static png_from_surface = function(_surface) {
		var _width = surface_get_width(_surface);
		var _height = surface_get_height(_surface);
	
		var _surface_buffer_size = _width * _height * 4;
		var _surface_buffer = buffer_create(_surface_buffer_size, buffer_fixed, 1);
		buffer_get_surface(_surface_buffer, _surface, 0);
		
		// add scanlines
		var _scanline_buffer_size = _surface_buffer_size+_height;
		var _scanline_buffer = buffer_create(_scanline_buffer_size, buffer_fixed, 1);
		var _line_length = _width*4;
		for (var _i=0; _i<_height; _i++) {
			buffer_write(_scanline_buffer, buffer_u8, 0x00); // scanline filter
			buffer_copy(_surface_buffer, _i*_line_length, _line_length, _scanline_buffer, buffer_tell(_scanline_buffer));
			buffer_seek(_scanline_buffer, buffer_seek_relative, _line_length);
		}
		
		// compress
		var _compressed_buffer = buffer_compress(_scanline_buffer, 0, _scanline_buffer_size);
		buffer_delete(_scanline_buffer);
		buffer_delete(_surface_buffer);
		var _compressed_buffer_size = buffer_get_size(_compressed_buffer);
		
		// create PNG buffer
		var _buffer_size = _compressed_buffer_size + 12 + 8 + 25 + 12; // 8 header, 25 IHDR, 12 IEND, 12 extra bytes for IDAT
		var _buffer = buffer_create(_buffer_size, buffer_fixed, 1);
		buffer_write(_buffer, buffer_u32, 0x474e5089); // header 1
		buffer_write(_buffer, buffer_u32, 0x0a1a0a0d); // header 2
		buffer_write(_buffer, buffer_u32, 0x0d000000); // IHDR length
		buffer_write(_buffer, buffer_u32, 0x52444849); // IHDR
		buffer_write(_buffer, buffer_u32, self.endian_swap(_width)); // width
		buffer_write(_buffer, buffer_u32, self.endian_swap(_height)); // height
		buffer_write(_buffer, buffer_u32, 0x00000608); // bit depth, color type, compression method, filter method
		buffer_write(_buffer, buffer_u8, 0x00); // interlace method
		var _crc = self.crc32_iso3309(_buffer, buffer_tell(_buffer)-17, 17);
		buffer_write(_buffer, buffer_u32, self.endian_swap(_crc)); // CRC
		
		buffer_write(_buffer, buffer_u32, self.endian_swap(_compressed_buffer_size)); // IDAT length
		buffer_write(_buffer, buffer_u32, 0x54414449); // IDAT
		buffer_copy(_compressed_buffer, 0, _compressed_buffer_size, _buffer, buffer_tell(_buffer));
		buffer_seek(_buffer, buffer_seek_relative, _compressed_buffer_size);
		_crc = self.crc32_iso3309(_buffer, buffer_tell(_buffer)-(_compressed_buffer_size+4), _compressed_buffer_size+4);
		buffer_write(_buffer, buffer_u32, self.endian_swap(_crc)); // CRC
		
		buffer_write(_buffer, buffer_u32, 0x00000000); // IEND length
		buffer_write(_buffer, buffer_u32, 0x444e4549); // IEND
		buffer_write(_buffer, buffer_u32, 0x826042ae); // precalculated CRC
		
		buffer_delete(_compressed_buffer);
	
		return _buffer;
	}

	
	/** Compute the ISO3309 CRC, which is different to gamemaker's buffer_crc32 function
	* @param {Id.Buffer} _buffer The buffer to compress
	* @param {Real} _offset the offset in buffer to start compressing
	* @param {Real} _size the number of bytes to compress
	* @return {Real}
	*/
	function crc32_iso3309(_buffer, _offset, _size) {
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
	
	static endian_swap = function(_value) {
		return ((_value & 0xff) << 24 ) |
				((_value & 0xff00) << 8) |
				((_value & 0xff0000) >> 8) |
				((_value & 0xff000000) >> 24);
	}
}

// instantiate statics
new HttpBufferUtils();