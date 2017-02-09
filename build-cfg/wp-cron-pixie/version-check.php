<?php
$version_checks = array(
	"$plugin_slug.php" => array( '@Version:\s+(.*)\n@' => 'header' ),
	"$plugin_slug.php" => array( "@'version'\\s+=>\\s+'(.*?)',@" => 'Plugin meta data' ),
);
