/** Initialize all globals */
function init_globals() {
	// The current config. While this _starts_ as the return value of os_get_config()
	// this could also be overwritten at some point during initialization to allow
	// better run-time control of the config, and not just changed from the IDE
	#macro OS_CONFIG global.os_config
	OS_CONFIG = os_get_config();
	
	// The root logger
	#macro LOGGER global.logger
	LOGGER = new Logger()
	
	// Sentry
	#macro SENTRY global.sentry
	SENTRY = new Sentry("https://54ef46466c580b483e07e7371b2d2ae2@o4506390902079488.ingest.sentry.io/4506390919315456");
	LOGGER.use_sentry(SENTRY);
	
	// The global game manager
	#macro GAME global.game
	GAME = undefined; // to be set later
	
	// The webserver
	#macro SERVER global.server
	SERVER = new HttpServer(5000, LOGGER);
}