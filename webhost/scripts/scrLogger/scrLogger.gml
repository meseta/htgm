// Log severity levels. These match the sentry level macros. so are interchangeable
#macro LOG_FATAL "fatal"
#macro LOG_ERROR "error"
#macro LOG_WARNING "warning"
#macro LOG_INFO "info"
#macro LOG_DEBUG "debug"

// Log types. These match the sentry breadcrumb types
#macro LOG_TYPE_DEFAULT "default"
#macro LOG_TYPE_ERROR "error"
#macro LOG_TYPE_INFO "info"
#macro LOG_TYPE_DEBUG "debug"
#macro LOG_TYPE_NAVIGATION "navigation"
#macro LOG_TYPE_HTTP "http"
#macro LOG_TYPE_QUERY "query"
#macro LOG_TYPE_TRANSACTION "transaction"
#macro LOG_TYPE_UI "ui"
#macro LOG_TYPE_USER "user"

// Setting this to True globally disables logging, causing the logger to do nothing when called
// NOTE: this includes not sending sentry reports, or adding values to the sentry breadcrumbs.
// If you want to turn off log outputs, but still send sentry reports, use set_levels() with
// no arguments
#macro LOGGING_DISABLED false

// Width of the padding used in the output
#macro LOGGING_PAD_WIDTH 48

/**
 * @desc A quick debugging function that is an alias for the root logger's debug() output
 * @param {Any} _message The message or data to send
 * @param {Struct} _extras Optional extra data to send
 *
 */
function trace(_message, _extras=undefined) {
	LOGGER.debug(_message, _extras);
}