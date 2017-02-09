<?php
if ( empty( $publish ) ) {
	return;
}

echo 'Publish to WP.org? (Y/n) ';
if ( 'Y' == trim( fgets( STDIN ) ) ) {
	system( 'svn co -q http://svn.wp-plugins.org/wp-cron-pixie svn' );
	system( 'rm -R svn/trunk' );
	system( 'mkdir svn/trunk' );
	system( 'mkdir svn/tags/$version' );
	system( "rsync -r $plugin_slug/* svn/trunk/" );
	system( "rsync -r $plugin_slug/* svn/tags/$version" );
	system( 'svn stat svn/ | grep \'^\?\' | awk \'{print $2}\' | xargs -I x svn add x@' );
	system( 'svn stat svn/ | grep \'^\!\' | awk \'{print $2}\' | xargs -I x svn rm --force x@' );
	system( 'svn stat svn/' );

	echo 'Commit to WP.org? (Y/n)? ';
	if ( 'Y' == trim( fgets( STDIN ) ) ) {
		system( "svn ci --username ianmjones svn/ -m 'Deploy version $version'" );
	}
}

echo 'Publish to Github? (Y/n) ';
if ( 'Y' == trim( fgets( STDIN ) ) ) {
	system( 'git clone git@github.com:ianmjones/wp-cron-pixie.git github1' );
	system( 'mkdir github' );
	system( 'mv github1/.git* github/' );
	system( 'rm -R github1/' );
	system( "rsync -r $plugin_slug/* github/" );
	chdir( 'github' );
	system( 'git add -A .' );
	system( 'git status' );

	echo 'Commit and push to Github? (Y/n)? ';
	if ( 'Y' == trim( fgets( STDIN ) ) ) {
		system( "git commit -m 'Deploying version $version'" );
		system( 'git push origin master' );
		system( "git tag $version" );
		system( 'git push origin --tags' );
	}

	chdir( $tmp_dir );
}
