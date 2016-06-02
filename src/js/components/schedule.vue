<template>
	<span class="cron-pixie-schedule-display" title="{{ schedule.name }}">{{ schedule.display }}</span>
	<cron-pixie-events :events="schedule.events"></cron-pixie-events>
</template>

<script>
	var CronPixieEvents = require( './events.vue' );

	export default {
		props: {
			schedule: {
				default: function() {
					return {
						name: 'the_schedule',
						display: 'The Schedule',
						events: []
					};
				}
			}
		},
		components: {
			CronPixieEvents
		}
	}
</script>

<style>
	.cron-pixie-schedule-display {
		font-weight: bold;
	}
</style>
