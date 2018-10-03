<?php
chdir( $root_dir );
system( 'npm run build-prod' );
chdir( $src_dir );
