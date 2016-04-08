var CronPixie = CronPixie || {};

(function( $, CronPixie ) {
	'use strict';

	/**
	 * A mixin for collections/models.
	 * Based on http://taylorlovett.com/2014/09/28/syncing-backbone-models-and-collections-to-admin-ajax-php/
	 */
	var AdminAjaxSyncableMixin = {
		url: ajaxurl,
		action: 'cron_pixie_request',

		sync: function( method, object, options ) {
			if ( typeof options.data === 'undefined' ) {
				options.data = {};
			}

			options.data.nonce = CronPixie.nonce; // From localized script.
			options.data.action_type = method;

			// If no action defined, set default.
			if ( undefined === options.data.action && undefined !== this.action ) {
				options.data.action = this.action;
			}

			// Reads work just fine.
			if ( 'read' === method ) {
				return Backbone.sync( method, object, options );
			}

			var json = this.toJSON();
			var formattedJSON = {};

			if ( json instanceof Array ) {
				formattedJSON.models = json;
			} else {
				formattedJSON.model = json;
			}

			_.extend( options.data, formattedJSON );

			// Need to use "application/x-www-form-urlencoded" MIME type.
			options.emulateJSON = true;

			// Force a POST with "create" method if not a read, otherwise admin-ajax.php does nothing.
			return Backbone.sync.call( this, 'create', object, options );
		}
	};

	/**
	 * A model for all your syncable models to extend.
	 * Based on http://taylorlovett.com/2014/09/28/syncing-backbone-models-and-collections-to-admin-ajax-php/
	 */
	var BaseModel = Backbone.Model.extend( _.defaults( {
		// parse: function( response ) {
		// Implement me depending on your response from admin-ajax.php!
		// return response;
		// }
	}, AdminAjaxSyncableMixin ) );

	/**
	 * A collection for all your syncable collections to extend.
	 * Based on http://taylorlovett.com/2014/09/28/syncing-backbone-models-and-collections-to-admin-ajax-php/
	 */
	var BaseCollection = Backbone.Collection.extend( _.defaults( {
		// parse: function( response ) {
		// 	Implement me depending on your response from admin-ajax.php!
		// return response;
		// }
	}, AdminAjaxSyncableMixin ) );


	/**
	 * Single cron event.
	 */
	CronPixie.EventModel = BaseModel.extend( {
		action: 'cron_pixie_events',
		defaults: {
			schedule: null,
			interval: null,
			hook: null,
			args: null,
			timestamp: null,
			seconds_due: null
		}
	} );

	/**
	 * Collection of cron events.
	 */
	CronPixie.EventsCollection = BaseCollection.extend( {
		action: 'cron_pixie_events',
		model: CronPixie.EventModel
	} );

	/**
	 * Single cron schedule with nested cron events.
	 */
	CronPixie.ScheduleModel = BaseModel.extend( {
		action: 'cron_pixie_schedules',
		defaults: {
			name: null,
			interval: null,
			display: null,
			events: new CronPixie.EventsCollection
		}
	} );

	/**
	 * Collection of cron schedules.
	 */
	CronPixie.SchedulesCollection = BaseCollection.extend( {
		action: 'cron_pixie_schedules',
		model: CronPixie.ScheduleModel
	} );

	/**
	 * The main view for listing cron schedules.
	 */
	CronPixie.SchedulesListView = Backbone.View.extend( {
		el: '#cron-pixie-main',

		initialize: function() {
			this.listenTo( this.collection, 'sync', this.render );
		},

		render: function() {
			var $list = this.$( 'ul.cron-pixie-schedules' ).empty();

			this.collection.each( function( model ) {
				var item = new CronPixie.SchedulesListItemView( { model: model } );
				$list.append( item.render().$el );
			}, this );

			return this;
		}
	} );

	/**
	 * A single cron schedule's view.
	 */
	CronPixie.SchedulesListItemView = Backbone.View.extend( {
		tagName: 'li',
		className: 'cron-pixie-schedule',
		template: _.template( $( '#cron-pixie-schedule-item-tmpl' ).html() ),

		initialize: function() {
			this.listenTo( this.model, 'change', this.render );
			this.listenTo( this.model, 'destroy', this.remove );
		},

		render: function() {
			var html = this.template( this.model.toJSON() );
			this.$el.html( html );

			// Need to render the cron schedule's events.
			var $list = this.$( 'ul.cron-pixie-events' ).empty();

			var events = new CronPixie.EventsCollection( this.model.get( 'events' ) );

			events.each( function( model ) {
				var item = new CronPixie.EventsListItemView( { model: model } );
				$list.append( item.render().$el );
			}, this );

			return this;
		}
	} );

	/**
	 * A single cron event's view.
	 */
	CronPixie.EventsListItemView = Backbone.View.extend( {
		tagName: 'li',
		className: 'cron-pixie-event',
		template: _.template( $( '#cron-pixie-event-item-tmpl' ).html() ),

		initialize: function() {
			this.listenTo( this.model, 'change', this.render );
			this.listenTo( this.model, 'destroy', this.remove );
		},

		events: {
			'click .cron-pixie-event-run': 'runNow'
		},

		render: function() {
			var html = this.template( this.model.toJSON() );
			this.$el.html( html );

			return this;
		},

		runNow: function() {
			CronPixie.pauseTimer();

			// Only bother to run update if not due before next refresh.
			var seconds_due = this.model.get( 'seconds_due' );

			if ( seconds_due > CronPixie.timer_period ) {
				var timestamp = this.model.get( 'timestamp' ) - seconds_due;
				this.model.save(
					{ timestamp: timestamp, seconds_due: 0 },
					{
						success: function( model, response, options ) {
							/*
							 console.log( options );
							 console.log( response );
							 */
							CronPixie.runTimer();
						},
						error: function( model, response, options ) {
							/*
							 console.log( options );
							 console.log( response );
							 */
							CronPixie.runTimer();
						}
					}
				);
			}
		}
	} );

	/**
	 * Display an interval as weeks, days, hours, minutes and seconds.
	 *
	 * @param seconds
	 * @returns string
	 */
	CronPixie.displayInterval = function( seconds ) {
		// Cron runs max every 60 seconds.
		if ( 0 > (seconds + 60) ) {
			return CronPixie.strings.passed;
		}

		// If due now or in next refresh period, show "now".
		if ( 0 > (seconds - CronPixie.timer_period) ) {
			return CronPixie.strings.now;
		}

		var intervals = [
			{ name: CronPixie.strings.weeks_abrv, val: 604800000 },
			{ name: CronPixie.strings.days_abrv, val: 86400000 },
			{ name: CronPixie.strings.hours_abrv, val: 3600000 },
			{ name: CronPixie.strings.minutes_abrv, val: 60000 },
			{ name: CronPixie.strings.seconds_abrv, val: 1000 }
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
	};


	/**
	 * Retrieves new data from server.
	 */
	CronPixie.refreshData = function() {
		CronPixie.schedules.fetch();
	};

	/**
	 * Start the recurring display updates if not already running.
	 */
	CronPixie.runTimer = function() {
		if ( undefined == CronPixie.timer ) {
			CronPixie.timer = setInterval( CronPixie.refreshData, CronPixie.timer_period * 1000 );
		}
	};

	/**
	 * Stop the recurring display updates if running.
	 */
	CronPixie.pauseTimer = function() {
		if ( undefined !== CronPixie.timer ) {
			clearInterval( CronPixie.timer );
			delete CronPixie.timer;
		}
	};

	/**
	 * Toggle recurring display updates on or off.
	 */
	CronPixie.toggleTimer = function() {
		if ( undefined !== CronPixie.timer ) {
			CronPixie.pauseTimer();
		} else {
			CronPixie.runTimer();
		}
	};

	/**
	 * Set initial data into view and start recurring display updates.
	 */
	CronPixie.init = function() {
		// Instantiate the base data and view.
		CronPixie.schedules = new CronPixie.SchedulesCollection();
		CronPixie.schedules.reset( CronPixie.data.schedules );
		CronPixie.schedulesList = new CronPixie.SchedulesListView( { collection: CronPixie.schedules } );
		CronPixie.schedulesList.render();

		// Start a timer for updating the data.
		CronPixie.runTimer();
	};

	$( document ).ready( function() {
		CronPixie.init();
	} );

})( jQuery, CronPixie );
