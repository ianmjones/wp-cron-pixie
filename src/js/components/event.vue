<template>
	<span @click="runNow" class="cron-pixie-event-run dashicons dashicons-controls-forward" title="{{ strings.run_now }}"></span>
	<span class="cron-pixie-event-hook">{{ event.hook }}</span>
	<div class="cron-pixie-event-timestamp dashicons-before dashicons-clock">
		<span class="cron-pixie-event-due">{{ strings.due }}:&nbsp;{{ due }}</span>
		&nbsp;
		<span class="cron-pixie-event-seconds-due">(<cron-pixie-display-interval :interval="event.seconds_due"></cron-pixie-display-interval>)</span>
	</div>
</template>

<script>
	var CronPixieDisplayInterval = require( './display_interval.vue' );

	export default {
		props: {
			event: {
				default: function() {
					return {
						schedule: '',
						interval: 0,
						hook: 'the_hook',
						args: [],
						timestamp: 0,
						seconds_due: 0
					};
				}
			}
		},
		computed: {
			due: function() {
				return new Date( this.event.timestamp * 1000 ).toLocaleString();
			}
		},
		components: {
			CronPixieDisplayInterval
		},
		methods: {
			runNow: function() {
				// Only bother to run update if not due before next refresh.
				if ( this.event.seconds_due > this.timer_period ) {
					// Tell the rest of the app that we're about to update an event.
					this.$dispatch( 'update-event', 'begin' );

					this.event.timestamp = this.event.timestamp - this.event.seconds_due;
					this.event.seconds_due = 0;

					// Send the request to update the event record.
					this.resource.update( {
						action: 'cron_pixie_events',
						nonce: this.nonce,
						model: this.event
					} ).then( function( response ) {
						// Tell the rest of the app that we've finished updating an event.
						this.$dispatch( 'update-event', 'end' );

						// Log success.
						//console.log( response );
					}, function( response ) {
						// Tell the rest of the app that we've finished updating an event.
						this.$dispatch( 'update-event', 'end' );

						// Log error.
						//console.log( response );
					} );
				}
			}
		}
	}
</script>

<style>
	.cron-pixie-event-run:hover {
		color: darkgreen;
		cursor: pointer;
	}
	.cron-pixie-event-timestamp {
		clear: both;
		margin-left: 1em;
		color: grey;
	}
</style>
