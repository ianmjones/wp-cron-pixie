<?php

/**
 * @link              https://github.com/ianmjones/wp-cron-pixie
 * @package           Cron_Pixie
 *
 * @wordpress-plugin
 * Plugin Name:       WP Cron Pixie
 * Plugin URI:        https://github.com/ianmjones/wp-cron-pixie
 * Description:       A little dashboard widget to manage the WordPress cron.
 * Version:           1.5.0-dev
 * Author:            Ian M. Jones
 * Author URI:        https://ianmjones.com/
 * License:           GPL-2.0+
 * License URI:       http://www.gnu.org/licenses/gpl-2.0.txt
 * Text Domain:       wp-cron-pixie
 * Domain Path:       /languages
 * Network:           False
 */

// If this file is called directly, abort.
if (!defined('WPINC')) {
	die;
}

/**
 * Returns info about the plugin.
 *
 * @return array
 */
function cron_pixie_meta()
{
	return array(
		'slug'    => 'wp-cron-pixie',
		'name'    => 'WP Cron Pixie',
		'file'    => __FILE__,
		'version' => '1.5.0-dev',
	);
}

// Where the magic happens...
require plugin_dir_path(__FILE__) . 'includes/class-cron-pixie.php';

/**
 * Initialize the plugin's functionality once the correct hook fires.
 */
function cron_pixie_admin_init()
{
	$cron_pixie = new Cron_Pixie(cron_pixie_meta());
}

add_action('admin_init', 'cron_pixie_admin_init');
