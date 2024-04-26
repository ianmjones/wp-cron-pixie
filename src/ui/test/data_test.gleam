import gleam/dynamic.{DecodeError, from}
import gleam/json
import gleeunit
import gleeunit/should
import internal/data.{Flags, decode_flags, int_string_to_bool}

pub fn main() {
  gleeunit.main()
}

pub fn decode_flags_test() {
  decode_flags("")
  |> should.equal(Error(json.UnexpectedEndOfInput))

  decode_flags("{}")
  |> should.equal(
    Error(
      json.UnexpectedFormat([
        DecodeError(expected: "field", found: "nothing", path: [
          "example_events",
        ]),
        DecodeError(expected: "field", found: "nothing", path: ["auto_refresh"]),
      ]),
    ),
  )

  decode_flags("{\"auto_refresh\": \"\"}")
  |> should.equal(
    Error(
      json.UnexpectedFormat([
        DecodeError(expected: "field", found: "nothing", path: [
          "example_events",
        ]),
      ]),
    ),
  )

  decode_flags("{\"auto_refresh\": \"1\"}")
  |> should.equal(
    Error(
      json.UnexpectedFormat([
        DecodeError(expected: "field", found: "nothing", path: [
          "example_events",
        ]),
      ]),
    ),
  )

  decode_flags("{\"example_events\": 1, \"auto_refresh\": \"wibble\"}")
  |> should.equal(Ok(Flags(example_events: False, auto_refresh: False)))

  decode_flags("{\"example_events\": \"\", \"auto_refresh\": \"\"}")
  |> should.equal(Ok(Flags(example_events: False, auto_refresh: False)))

  decode_flags("{\"example_events\": \"1\", \"auto_refresh\": \"\"}")
  |> should.equal(Ok(Flags(example_events: True, auto_refresh: False)))

  decode_flags("{\"example_events\": \"\", \"auto_refresh\": \"1\"}")
  |> should.equal(Ok(Flags(example_events: False, auto_refresh: True)))

  decode_flags("{\"example_events\": \"1\", \"auto_refresh\": \"1\"}")
  |> should.equal(Ok(Flags(example_events: True, auto_refresh: True)))
}

pub fn int_string_to_bool_test() {
  int_string_to_bool(from(""))
  |> should.equal(Ok(False))

  int_string_to_bool(from("wibble"))
  |> should.equal(Ok(False))

  int_string_to_bool(from(1))
  |> should.equal(Ok(False))

  int_string_to_bool(from("1"))
  |> should.equal(Ok(True))
}
