document.addEventListener('DOMContentLoaded', () => {
	import('./ui.js?ver=' + CronPixie.version).then((CronPixieUI) => {
		CronPixieUI.main(5);
	});

	/*
	var $mountPoint = document.getElementById( 'cron-pixie-main' );
	var app = Elm.CronPixie.init( {
		node: $mountPoint,
		flags: {
			strings: CronPixie.strings,
			admin_url: CronPixie.admin_url,
			nonce: CronPixie.nonce,
			timer_period: CronPixie.timer_period,
			schedules: CronPixie.data.schedules,
			example_events: CronPixie.example_events,
			auto_refresh: CronPixie.auto_refresh
		}
	} );
	*/
});
