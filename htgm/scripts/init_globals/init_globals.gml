function init_globals() {
	// The root logger
	#macro LOGGER global.logger
	LOGGER = new Logger();
	
	// Sentry
	#macro SENTRY global.sentry
	SENTRY = new Sentry("https://54ef46466c580b483e07e7371b2d2ae2@o4506390902079488.ingest.sentry.io/4506390919315456");
	LOGGER.use_sentry(SENTRY);

	// The webserver
	#macro SERVER global.server
}