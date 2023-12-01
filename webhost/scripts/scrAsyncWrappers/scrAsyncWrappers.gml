function add_async_http_callback(_callback) {
	static async_http_wrapper = noone;
	
	if (!instance_exists(async_http_wrapper)) {
		async_http_wrapper = instance_create_depth(0, 0, 0, oAsyncHttpWrapper);
	}
	async_http_wrapper.add_callback(_callback);
}

function add_async_networking_callback(_callback) {
	var _async_networking_wrapper = instance_create_depth(0, 0, 0, oAsyncNetworkingWrapper);
	_async_networking_wrapper.set_callback(_callback);
}