<?php
chdir( $root_dir );
system( 'npm run build' );
chdir( $src_dir );
