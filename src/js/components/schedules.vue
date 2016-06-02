<template>
	<h3>Schedules</h3>
	<ul class="cron-pixie-schedules">
		<li v-for="schedule in schedules">
			<cron-pixie-schedule :schedule="schedule"></cron-pixie-schedule>
		</li>
	</ul>
</template>

<script>
	var CronPixieSchedule = require( './schedule.vue' );

	export default {
		props: {
			schedules: {
				default: function() {
					return [];
				}
			}
		},
		components: {
			CronPixieSchedule
		}
	}
</script>

<style>
</style>
