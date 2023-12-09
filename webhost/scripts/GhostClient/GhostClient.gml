// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function GhostClient(): HttpClient(GHOST_CONTENT_API_URL, "GhostClient") constructor {
	self.set_headers({
		"Accept-Version": "v5.0"
	})
	
	static __get_with_key = function(_url) {
		return self.get($"{_url}?key={GHOST_CONTENT_API_KEY}");
	};
	
	static get_page = function(_slug) {
		return self.__get_with_key($"/pages/slug/{_slug}");	
	};
}