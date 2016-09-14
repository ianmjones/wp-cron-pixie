<?php

class Cron_Pixie {

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

		// Add a schedule of our own for testing.
		add_filter( 'cron_schedules', array( $this, 'filter_cron_schedules' ) );

		// Add an event to our test schedule.
		$this->_create_test_event();
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
			plugin_dir_url( $this->plugin_meta['file'] ) . 'js/build.js',
			array(),
			$this->plugin_meta['version'],
			true // Load JS in footer so that templates in DOM can be referenced.
		);

		// Add initial data to CronPixie JS object so it can be rendered without fetch.
		// Also add translatable strings for JS as well as reference settings.
		$data = array(
			'strings'      => array(
				'no_events'    => _x( '(none)', 'no event to show', 'wp-cron-pixie' ),
				'due'          => _x( 'due', 'label for when cron event date', 'wp-cron-pixie' ),
				'now'          => _x( 'now', 'cron event is due now', 'wp-cron-pixie' ),
				'passed'       => _x( 'passed', 'cron event is over due', 'wp-cron-pixie' ),
				'weeks_abrv'   => _x( 'w', 'displayed in interval', 'wp-cron-pixie' ),
				'days_abrv'    => _x( 'd', 'displayed in interval', 'wp-cron-pixie' ),
				'hours_abrv'   => _x( 'h', 'displayed in interval', 'wp-cron-pixie' ),
				'minutes_abrv' => _x( 'm', 'displayed in interval', 'wp-cron-pixie' ),
				'seconds_abrv' => _x( 's', 'displayed in interval', 'wp-cron-pixie' ),
				'run_now'      => _x( 'Run event now.', 'Title for run now icon', 'wp-cron-pixie' ),
			),
			'nonce'        => wp_create_nonce( 'cron-pixie' ),
			'timer_period' => 5, // How often should display be updated, in seconds.
			'data'         => array(
				'schedules' => $this->_get_schedules(),
			),
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
		$event = json_decode( stripcslashes( $_POST['model'] ), true );
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
	private function _create_test_event() {
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
}
