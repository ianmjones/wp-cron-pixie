<template>
	<ul class="cron-pixie-events">
		<span v-if="empty" class="cron-pixie-event-empty">{{ strings.no_events }}</span>
		<li v-else v-for="event in events">
			<cron-pixie-event :event="event"></cron-pixie-event>
		</li>
	</ul>
</template>

<script>
	var CronPixieEvent = require( './event.vue' );

	export default {
		props: {
			events: {
				default: function() {
					return [];
				}
			}
		},
		computed: {
			empty: function() {
				return this.events.length === 0;
			}
		},
		components: {
			CronPixieEvent
		}
	}
</script>

<style>
	.cron-pixie-events {
		padding-left: 1em;
	}
	.cron-pixie-event-empty {
		color: grey;
	}
</style>
