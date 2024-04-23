import gleam/dynamic
import gleam/json
import gleam/option.{type Option}
import gleam/result

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

// TODO: Decode JSON object flags to Model.
pub fn decode_flags(flags: String) -> Model {
  Model(
    example_events: decode_json_string_field_to_bool(flags, "example_events"),
    auto_refresh: decode_json_string_field_to_bool(flags, "auto_refresh"),
    refreshing: False,
  )
}

/// Decode a JSON string field to bool.
pub fn decode_json_string_field_to_bool(
  json_string: String,
  field_name: String,
) -> Bool {
  let decoder =
    dynamic.decode1(Ok, dynamic.field(field_name, of: dynamic.string))
  let val = json.decode(from: json_string, using: decoder)

  case result.flatten(val) {
    Ok("1") -> True
    _ -> False
  }
}
