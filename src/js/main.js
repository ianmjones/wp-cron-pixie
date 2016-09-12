var Elm = require( './CronPixie' );
var $mountPoint = document.getElementById( 'cron-pixie-main' );
var app = Elm.CronPixie.embed(
  $mountPoint,
  {
    strings: CronPixie.strings,
    nonce: CronPixie.nonce,
    timer_period: CronPixie.timer_period,
    schedules: CronPixie.data.schedules
  }
);
