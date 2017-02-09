<?php
chdir( $root_dir );
system( 'npm run build-elm' );
system( 'npm run build-js' );
chdir( $src_dir );
