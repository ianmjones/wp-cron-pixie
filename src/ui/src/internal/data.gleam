import gleam/dynamic.{type DecodeError, type Dynamic, decode2, field, string}
import gleam/json
import gleam/option.{type Option}

// TODO: Create more complex Model.
pub type Model {
  Model(
    //strings: Strings,
    //admin_url: String,
    //nonce: String,
    //timer_period: Float,
    //schedules: List(Schedule),
    example_events: Bool,
    auto_refresh: Bool,
    refreshing: Bool,
  )
}

pub type Strings {
  Strings(
    no_events: String,
    due: String,
    now: String,
    passed: String,
    weeks_abrv: String,
    days_abrv: String,
    hours_abrv: String,
    minutes_abrv: String,
    seconds_abrv: String,
    run_now: String,
    refresh: String,
    schedules: String,
    example_events: String,
    example_events_tooltip: String,
    auto_refresh: String,
    auto_refresh_tooltip: String,
  )
}

pub type Schedule {
  Schedule(
    name: String,
    display: String,
    interval: Option(Int),
    events: Option(List(Event)),
  )
}

// TODO: args may need to be a list of tuples or maps.
pub type Event {
  Event(
    schedule: String,
    interval: Option(Int),
    hook: String,
    args: List(String),
    timestamp: Int,
    seconds_due: Int,
  )
}

pub type Divider {
  Divider(name: String, val: Int)
}

pub type Flags {
  Flags(
    //strings: Strings,
    //admin_url: String,
    //nonce: String,
    //timer_period: Float,
    //schedules: List(Schedule),
    example_events: Bool,
    auto_refresh: Bool,
  )
}

// TODO: Decode JSON string to Flags.
pub fn decode_flags(flags: String) -> Result(Flags, json.DecodeError) {
  let decoder =
    decode2(
      Flags,
      field("example_events", of: int_string_to_bool),
      field("auto_refresh", of: int_string_to_bool),
    )
  json.decode(from: flags, using: decoder)
}

/// Decode a JSON string field to bool.
pub fn int_string_to_bool(val: Dynamic) -> Result(Bool, List(DecodeError)) {
  let ok = string(val)

  case ok {
    Ok("1") -> Ok(True)
    _ -> Ok(False)
  }
}
