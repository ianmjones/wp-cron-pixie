<?php

class Cron_Pixie {

	/**
	 * The key used for saving settings in the database.
	 *
	 * @var string
	 */
	const SETTINGS_KEY = 'cron_pixie_settings';

	/**
	 * Often used plugin info.
	 *
	 * @var array
	 */
	private $plugin_meta;

	/**
	 * Cron_Pixie constructor.
	 *
	 * Registers all action and filter hooks if user can use widget.
	 *
	 * @param array $plugin_meta
	 */
	public function __construct( $plugin_meta = array() ) {
		if ( empty( $plugin_meta ) ) {
			return;
		}

		$this->plugin_meta = $plugin_meta;

		// Usage of the plugin is restricted to Administrators.
		if ( ! current_user_can( 'manage_options' ) ) {
			return;
		}

		// Add the widget during dashboard set up.
		add_action( 'wp_dashboard_setup', array( $this, 'add_dashboard_widget' ) );

		// Enqueue the CSS & JS scripts.
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_scripts' ) );

		// AJAX handlers.
		add_action( 'wp_ajax_cron_pixie_schedules', array( $this, 'ajax_schedules' ) );
		add_action( 'wp_ajax_cron_pixie_events', array( $this, 'ajax_events' ) );
		add_action( 'wp_ajax_cron_pixie_example_events', array( $this, 'ajax_example_events' ) );
		add_action( 'wp_ajax_cron_pixie_auto_refresh', array( $this, 'ajax_auto_refresh' ) );

		if ( $this->_get_setting( 'example_events' ) ) {
			// Add a schedule of our own for testing.
			add_filter( 'cron_schedules', array( $this, 'filter_cron_schedules' ) );

			// Add events to our test schedule.
			$this->_create_test_events();
		} else {
			// Remove events from our test schedule.
			$this->_remove_test_events();
		}
	}

	/**
	 * Registers the widget and content callback.
	 */
	public function add_dashboard_widget() {

		wp_add_dashboard_widget(
			$this->plugin_meta['slug'],
			$this->plugin_meta['name'],
			array( $this, 'dashboard_widget_content' )
		);
	}

	/**
	 * Provides the initial content for the widget.
	 */
	public function dashboard_widget_content() {
		?>
		<!-- Main content -->
		<div id="cron-pixie-main"></div>
		<?php
	}

	/**
	 * Enqueues the JS scripts when the main dashboard page is loading.
	 *
	 * @param string $hook_page
	 */
	public function enqueue_scripts( $hook_page ) {
		if ( 'index.php' !== $hook_page ) {
			return;
		}

		$script_handle = $this->plugin_meta['slug'] . '-main';

		wp_enqueue_style(
			$script_handle,
			plugin_dir_url( $this->plugin_meta['file'] ) . 'css/main.css',
			array(),
			$this->plugin_meta['version']
		);

		wp_enqueue_script(
			$script_handle,
			plugin_dir_url( $this->plugin_meta['file'] ) . 'js/main.js',
			array(),
			$this->plugin_meta['version'],
			true // Load JS in footer so that templates in DOM can be referenced.
		);

		wp_enqueue_script(
			$script_handle . '-build',
			plugin_dir_url( $this->plugin_meta['file'] ) . 'js/CronPixie.js',
			array(),
			$this->plugin_meta['version'],
			true // Load JS in footer so that templates in DOM can be referenced.
		);

		// Add initial data to CronPixie JS object so it can be rendered without fetch.
		// Also add translatable strings for JS as well as reference settings.
		$data = array(
			'strings'        => array(
				'no_events'              => _x( '(none)', 'no event to show', 'wp-cron-pixie' ),
				'due'                    => _x( 'due', 'label for when cron event date', 'wp-cron-pixie' ),
				'now'                    => _x( 'now', 'cron event is due now', 'wp-cron-pixie' ),
				'passed'                 => _x( 'passed', 'cron event is over due', 'wp-cron-pixie' ),
				'weeks_abrv'             => _x( 'w', 'displayed in interval', 'wp-cron-pixie' ),
				'days_abrv'              => _x( 'd', 'displayed in interval', 'wp-cron-pixie' ),
				'hours_abrv'             => _x( 'h', 'displayed in interval', 'wp-cron-pixie' ),
				'minutes_abrv'           => _x( 'm', 'displayed in interval', 'wp-cron-pixie' ),
				'seconds_abrv'           => _x( 's', 'displayed in interval', 'wp-cron-pixie' ),
				'run_now'                => _x( 'Run event now.', 'Tooltip for run now icon', 'wp-cron-pixie' ),
				'refresh'                => _x( 'Refresh Now', 'Tooltip for refresh now icon', 'wp-cron-pixie' ),
				'schedules'              => _x( 'Schedules', 'Title for list of schedules', 'wp-cron-pixie' ),
				'example_events'         => _x( 'Example Events', 'Label for Example Events checkbox', 'wp-cron-pixie' ),
				'example_events_tooltip' => _x( 'Include some example events in the cron schedule', 'Tooltip for Example Events checkbox', 'wp-cron-pixie' ),
				'auto_refresh'           => _x( 'Auto Refresh', 'Label for Auto Refresh checkbox', 'wp-cron-pixie' ),
				'auto_refresh_tooltip'   => _x( 'Refresh the display of cron events every 5 seconds', 'Tooltip for Auto Refresh checkbox', 'wp-cron-pixie' ),
			),
			'admin_url'      => untrailingslashit( admin_url() ),
			'nonce'          => wp_create_nonce( 'cron-pixie' ),
			'timer_period'   => 5, // How often should display be updated, in seconds.
			'data'           => array(
				'schedules' => $this->_get_schedules(),
			),
			'example_events' => (bool) $this->_get_setting( 'example_events' ),
			'auto_refresh'   => (bool) $this->_get_setting( 'auto_refresh' ),
		);
		wp_localize_script( $script_handle, 'CronPixie', $data );
	}

	/**
	 * Returns list of cron schedules.
	 *
	 * @return array
	 */
	private function _get_schedules() {
		// Get list of schedules.
		$schedules = wp_get_schedules();

		// Append a "Once Only" schedule.
		$schedules['once'] = array(
			'display' => __( 'Once Only', 'wp-cron-pixie' ),
		);

		// Get list of jobs assigned to schedules.
		// Using "private" function is really naughty, but it's the best option compared to querying db/options.
		$cron_array = _get_cron_array();

		// Consistent timestamp for seconds until due.
		$now = time();

		// Add child cron events to schedules.
		foreach ( $cron_array as $timestamp => $jobs ) {
			foreach ( $jobs as $hook => $events ) {
				foreach ( $events as $key => $event ) {
					$event['hook']        = $hook;
					$event['timestamp']   = $timestamp;
					$event['seconds_due'] = $timestamp - $now;

					// The cron array also includes events without a recurring schedule.
					$scheduled = empty( $event['schedule'] ) ? 'once' : $event['schedule'];

					$schedules[ $scheduled ]['events'][] = $event;
				}
			}
		}

		// We need to change the associative array (map) into an indexed one (set) for easier use in collection.
		$set = array();
		foreach ( $schedules as $name => $schedule ) {
			$schedule['name'] = $name;
			$set[]            = $schedule;
		}

		return $set;
	}

	/**
	 * Send a response to ajax request, as JSON.
	 *
	 * @param mixed $response
	 */
	private function _ajax_return( $response = true ) {
		echo json_encode( $response );
		exit;
	}

	/**
	 * Displays a JSON encoded list of cron schedules.
	 *
	 * @return mixed|string|void
	 */
	public function ajax_schedules() {
		$this->_ajax_return( $this->_get_schedules() );
	}

	/**
	 * Run a cron event now rather than later.
	 */
	public function ajax_events() {
		// TODO: Sanitize inputs!
		$event         = json_decode( stripcslashes( $_POST['model'] ), true );
		$event['args'] = empty( $event['args'] ) ? array() : $event['args'];

		$now       = time();
		$schedule  = wp_get_schedule( $event['hook'], $event['args'] );
		$timestamp = wp_next_scheduled( $event['hook'], $event['args'] );

		// If not expecting a schedule, but cron says it's on one, do nothing.
		if ( 'false' === $event['schedule'] && ! empty( $schedule ) ) {
			$this->_ajax_return( new WP_Error( 'cron-pixie-scheduled-single', __( 'The single event is also in a schedule.', 'wp-cron-pixie' ) ) );
		}

		// If expecting a schedule, but cron says it's not on one, do nothing.
		if ( 'false' !== $event['schedule'] && empty( $schedule ) ) {
			$this->_ajax_return( new WP_Error( 'cron-pixie-schedule-missing', __( 'The scheduled event is not scheduled.', 'wp-cron-pixie' ) ) );
		}

		// We only want to reschedule an event if it already exists and is in the future.
		if ( false !== $timestamp && $now < $timestamp ) {
			wp_unschedule_event( $timestamp, $event['hook'], $event['args'] );

			if ( 'false' === $event['schedule'] ) {
				wp_schedule_single_event( $event['timestamp'], $event['hook'], $event['args'] );
			} else {
				wp_schedule_event( $event['timestamp'], $event['schedule'], $event['hook'], $event['args'] );
			}
		}

		// Tell cron system to have a go at running due events.
		spawn_cron();

		$this->_ajax_return();
	}

	/**
	 * Update the setting for whether example events should be included in the cron.
	 */
	public function ajax_example_events() {
		// TODO: Sanitize inputs!
		if ( isset( $_POST['example_events'] ) ) {
			$value = empty( $_POST['example_events'] ) ? false : true;

			$settings = get_site_option( self::SETTINGS_KEY );

			if ( is_array( $settings ) ) {
				$settings['example_events'] = $value;
			} else {
				$settings = array( 'example_events' => $value );
			}

			if ( ! update_site_option( self::SETTINGS_KEY, $settings ) ) {
				$this->_ajax_return( new WP_Error( 'cron-pixie-example-events-update-settings', __( 'Could not update settings.', 'wp-cron-pixie' ) ) );
			}
		} else {
			$this->_ajax_return( new WP_Error( 'cron-pixie-example-events-missing-value', __( 'No value given for whether Example Events should be included in cron.', 'wp-cron-pixie' ) ) );
		}

		$this->_ajax_return( $value );
	}

	/**
	 * Update the setting for whether the display should auto refresh.
	 */
	public function ajax_auto_refresh() {
		// TODO: Sanitize inputs!
		if ( isset( $_POST['auto_refresh'] ) ) {
			$value = empty( $_POST['auto_refresh'] ) ? false : true;

			$settings = get_site_option( self::SETTINGS_KEY );

			if ( is_array( $settings ) ) {
				$settings['auto_refresh'] = $value;
			} else {
				$settings = array( 'auto_refresh' => $value );
			}

			if ( ! update_site_option( self::SETTINGS_KEY, $settings ) ) {
				$this->_ajax_return( new WP_Error( 'cron-pixie-auto-refresh-update-settings', __( 'Could not update settings.', 'wp-cron-pixie' ) ) );
			}
		} else {
			$this->_ajax_return( new WP_Error( 'cron-pixie-auto-refresh-missing-value', __( 'No value given for whether the display should auto refresh.', 'wp-cron-pixie' ) ) );
		}

		$this->_ajax_return( $value );
	}

	/**
	 * Adds an "every_minute" schedule to the Schedules list.
	 *
	 * @param array $schedules
	 *
	 * @return array
	 */
	public function filter_cron_schedules( $schedules = array() ) {
		$schedules['every_minute'] = array(
			'interval' => 60,
			'display'  => __( 'Every Minute', 'wp-cron-pixie' ),
		);

		return $schedules;
	}

	/**
	 * Creates test cron events in the cron schedule if they do not already exist.
	 */
	private function _create_test_events() {
		$args = array( 'wibble' => 'wobble' );

		// Create an event that has already been missed (2 minutes over due).
		if ( ! wp_next_scheduled( 'cron_pixie_passed_event', $args ) ) {
			wp_schedule_event( time() - 120, 'every_minute', 'cron_pixie_passed_event', $args );
		}

		// Create an event that is just coming up (initially 30 seconds until due).
		if ( ! wp_next_scheduled( 'cron_pixie_future_event', $args ) ) {
			wp_schedule_event( time() + 30, 'every_minute', 'cron_pixie_future_event', $args );
		}

		// Create a single event that is in the future (initially 5 minutes until due).
		if ( ! wp_next_scheduled( 'cron_pixie_single_event', $args ) ) {
			wp_schedule_single_event( time() + 300, 'cron_pixie_single_event', $args );
		}
	}

	/**
	 * Remove test cron events from the cron schedule if they already exist.
	 */
	private function _remove_test_events() {
		$args = array( 'wibble' => 'wobble' );

		// Create an event that has already been missed (2 minutes over due).
		if ( wp_next_scheduled( 'cron_pixie_passed_event', $args ) ) {
			wp_clear_scheduled_hook( 'cron_pixie_passed_event', $args );
		}

		// Create an event that is just coming up (initially 30 seconds until due).
		if ( ! wp_next_scheduled( 'cron_pixie_future_event', $args ) ) {
			wp_clear_scheduled_hook( 'cron_pixie_future_event', $args );
		}

		// Create a single event that is in the future (initially 5 minutes until due).
		if ( ! wp_next_scheduled( 'cron_pixie_single_event', $args ) ) {
			wp_clear_scheduled_hook( 'cron_pixie_single_event', $args );
		}
	}

	/**
	 * Get a single setting based on its key name.
	 *
	 * @param string $key
	 *
	 * @return mixed defaults to false if not found
	 */
	private function _get_setting( $key ) {
		$value = false;

		$settings = get_site_option( self::SETTINGS_KEY );

		if ( ! empty( $settings ) ) {
			if ( isset( $settings[ $key ] ) ) {
				$value = $settings[ $key ];
			}
		}

		return $value;
	}
}
