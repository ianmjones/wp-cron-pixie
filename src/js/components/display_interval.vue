<template>
	{{ displayInterval }}
</template>

<script>
	export default {
		props: [ 'interval' ],
		computed: {
			displayInterval: function() {
				return this._displayInterval( this.interval );
			}
		},
		methods: {
			/**
			 * Display an interval as weeks, days, hours, minutes and seconds.
			 *
			 * @param seconds
			 * @returns string
			 */
			_displayInterval: function( seconds ) {
				// Cron runs max every 60 seconds.
				if ( 0 > (seconds + 60) ) {
					return this.strings.passed;
				}

				// If due now or in next refresh period, show "now".
				if ( 0 > (seconds - this.timer_period) ) {
					return this.strings.now;
				}

				var intervals = [
					{ name: this.strings.weeks_abrv, val: 604800000 },
					{ name: this.strings.days_abrv, val: 86400000 },
					{ name: this.strings.hours_abrv, val: 3600000 },
					{ name: this.strings.minutes_abrv, val: 60000 },
					{ name: this.strings.seconds_abrv, val: 1000 }
				];

				// Convert everything to milliseconds so we can handle seconds in map.
				var milliseconds = seconds * 1000;
				var results = intervals.map( function( divider ) {
					var count = Math.floor( milliseconds / divider.val );

					if ( 0 < count ) {
						milliseconds = milliseconds % divider.val;
						return count + divider.name;
					} else {
						return '';
					}
				} );

				return results.join( ' ' ).trim();
			}
		}
	}
</script>

<style>
</style>
