var Vue = require( 'vue' );
var Schedules = require( './components/schedules.vue' );

// Use and configure vue-resource.
Vue.use( require( 'vue-resource' ) );
Vue.http.options.emulateJSON = true;
Vue.http.options.emulateHTTP = true;

// Create a global mixin to expose strings, global config, and single backend resource.
Vue.mixin( {
	computed: {
		strings: function() {
			return CronPixie.strings;
		},
		nonce: function() {
			return CronPixie.nonce;
		},
		timer_period: function() {
			return CronPixie.timer_period;
		},
		resource: function() {
			return this.$resource( '/wp-admin/admin-ajax.php' );
		}
	}
} );

// Main Vue instance that bootstraps the frontend.
new Vue( {
	el: '#cron-pixie-main',
	data: CronPixie.data,
	components: {
		CronPixieSchedules: Schedules
	},
	methods: {
		/**
		 * Retrieves new data from server.
		 */
		refreshData: function() {
			this.resource.get( {
				action: 'cron_pixie_schedules',
				nonce: this.nonce
			} ).then( function( response ) {
				this.schedules = response.data;
			}, function( response ) {
				// Log error.
				console.log( response );
			} );
		},

		/**
		 * Start the recurring display updates if not already running.
		 */
		runTimer: function() {
			if ( undefined == CronPixie.timer ) {
				CronPixie.timer = setInterval( this.refreshData, CronPixie.timer_period * 1000 );
			}
		},

		/**
		 * Stop the recurring display updates if running.
		 */
		pauseTimer: function() {
			if ( undefined !== CronPixie.timer ) {
				clearInterval( CronPixie.timer );
				delete CronPixie.timer;
			}
		},

		/**
		 * Toggle recurring display updates on or off.
		 */
		toggleTimer: function() {
			if ( undefined !== CronPixie.timer ) {
				this.pauseTimer();
			} else {
				this.runTimer();
			}
		}
	},
	events: {
		'update-event': function( status ) {
			if ( 'begin' === status ) {
				this.pauseTimer();
			} else {
				this.runTimer();
			}
		}
	},
	ready: function() {
		// Start a timer for updating the data.
		this.runTimer();
	}
} );

