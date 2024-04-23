import gleeunit
import gleeunit/should
import internal/data

pub fn main() {
  gleeunit.main()
}

pub fn decode_flags_test() {
  data.decode_flags("")
  |> should.equal(data.Model(
    example_events: False,
    auto_refresh: False,
    refreshing: False,
  ))

  data.decode_flags("{}")
  |> should.equal(data.Model(
    example_events: False,
    auto_refresh: False,
    refreshing: False,
  ))

  data.decode_flags("{\"auto_refresh\": \"\"}")
  |> should.equal(data.Model(
    example_events: False,
    auto_refresh: False,
    refreshing: False,
  ))

  data.decode_flags("{\"auto_refresh\": \"1\"}")
  |> should.equal(data.Model(
    example_events: False,
    auto_refresh: True,
    refreshing: False,
  ))

  data.decode_flags("{\"example_events\": \"\", \"auto_refresh\": \"1\"}")
  |> should.equal(data.Model(
    example_events: False,
    auto_refresh: True,
    refreshing: False,
  ))

  data.decode_flags("{\"example_events\": \"1\", \"auto_refresh\": \"1\"}")
  |> should.equal(data.Model(
    example_events: True,
    auto_refresh: True,
    refreshing: False,
  ))
}

pub fn decode_json_string_field_to_bool_test() {
  data.decode_json_string_field_to_bool("", "the_field")
  |> should.equal(False)

  data.decode_json_string_field_to_bool("{}", "the_field")
  |> should.equal(False)

  data.decode_json_string_field_to_bool("{\"the_field\": \"\"}", "the_field")
  |> should.equal(False)

  data.decode_json_string_field_to_bool("{\"the_field\": \"1\"}", "the_field")
  |> should.equal(True)
}
