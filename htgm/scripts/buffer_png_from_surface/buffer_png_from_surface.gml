/** Creates a PNG inside a buffer from a surface
* @param {Id.Surface} _surface The surface to create PNG from
* @return {ID.Buffer}
*/
function buffer_png_from_surface(_surface) {
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
	buffer_write(_buffer, buffer_u32, self.__endian_swap(_width)); // width
	buffer_write(_buffer, buffer_u32, self.__endian_swap(_height)); // height
	buffer_write(_buffer, buffer_u32, 0x00000608); // bit depth, color type, compression method, filter method
	buffer_write(_buffer, buffer_u8, 0x00); // interlace method
	var _crc = buffer_crc32_iso3309(_buffer, buffer_tell(_buffer)-17, 17);
	buffer_write(_buffer, buffer_u32, self.__endian_swap(_crc)); // CRC
		
	buffer_write(_buffer, buffer_u32, self.__endian_swap(_compressed_buffer_size)); // IDAT length
	buffer_write(_buffer, buffer_u32, 0x54414449); // IDAT
	buffer_copy(_compressed_buffer, 0, _compressed_buffer_size, _buffer, buffer_tell(_buffer));
	buffer_seek(_buffer, buffer_seek_relative, _compressed_buffer_size);
	var _crc = buffer_crc32_iso3309(_buffer, buffer_tell(_buffer)-(_compressed_buffer_size+4), _compressed_buffer_size+4);
	buffer_write(_buffer, buffer_u32, self.__endian_swap(_crc)); // CRC
		
	buffer_write(_buffer, buffer_u32, 0x00000000); // IEND length
	buffer_write(_buffer, buffer_u32, 0x444e4549); // IEND
	buffer_write(_buffer, buffer_u32, 0x826042ae); // precalculated CRC
		
	buffer_delete(_compressed_buffer);
	
	return _buffer;
}
