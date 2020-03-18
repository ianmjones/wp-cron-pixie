=== Plugin Name ===
Contributors: ianmjones
Donate link: https://www.ianmjones.com/
Tags: cron, wp-cron, dashboard, admin, widget
Requires at least: 4.9
Tested up to: 5.4
Stable tag: trunk
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

A little dashboard widget to view the WordPress cron.

== Description ==

A little dashboard widget to view the WordPress cron, and run an event now rather than later.

This plugin was built for the [Building Reactive WordPress Plugins](https://deliciousbrains.com/building-reactive-wordpress-plugins/) series of articles on the [Delicious Brains Blog](https://deliciousbrains.com/blog/).

1. [Building Reactive WordPress Plugins – Part 1 – Backbone.js](https://deliciousbrains.com/building-reactive-wordpress-plugins-part-1-backbone-js/)
1. [Building Reactive WordPress Plugins – Part 2 – Vue.js](https://deliciousbrains.com/building-reactive-wordpress-plugins-part-2-vue-js/)
1. [Building Reactive WordPress Plugins – Part 3 – Elm](https://deliciousbrains.com/building-reactive-wordpress-plugins-part-3-elm/)

== Installation ==

= From your WordPress dashboard =
1. Visit 'Plugins > Add New'
1. Search for 'WP Cron Pixie'
1. Activate WP Cron Pixie from your Plugins page.

= From WordPress.org =
1. Download WP Cron Pixie.
1. Upload the 'wp-cron-pixie' directory to your '/wp-content/plugins/' directory, using your favorite method (ftp, sftp, scp, etc...)
1. Activate WP Cron Pixie from your Plugins page.

== Frequently Asked Questions ==

= What is the answer to life, the universe and everything? =

42

== Screenshots ==

1. WP Cron Pixie widget.

== Changelog ==

= 1.4.1 =
* Fixed wrong data refreshing into non-primary subsite of directory multisite
* Minor updates to framework and build tools.
* Tested with WP 5.4

= 1.4 =
* Added checkbox to control whether example cron events should be added to cron.
* Added checkbox to control whether the display should auto refresh.
* Added "Refresh" icon for manual refresh of data.
* Fixed not all strings in UI being translatable.
* Elm 0.19 frontend.

= 1.3.1 =
* Minor updates to framework and build tools.
* Tested with WP 4.9.8.

= 1.3 =
* Elm 0.18 frontend.

= 1.2 =
* Elm frontend.

= 1.1 =
* Vue.js frontend.

= 1.0 =
* Initial release.
* Backbone.js frontend.
