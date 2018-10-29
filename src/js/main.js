var CronPixieApp = require( './CronPixie' );
document.addEventListener( 'DOMContentLoaded', () => {
	var $mountPoint = document.getElementById( 'cron-pixie-main' );
	var app = CronPixieApp.Elm.CronPixie.init( {
		node: $mountPoint,
		flags: {
			strings: CronPixie.strings,
			nonce: CronPixie.nonce,
			timer_period: CronPixie.timer_period,
			schedules: CronPixie.data.schedules,
			example_events: CronPixie.example_events,
			auto_refresh: CronPixie.auto_refresh
		}
	} );
} );
