import internal/data.{Model, decode_flags}
import lustre
import lustre/effect
import lustre/element.{text}
import lustre/element/html.{div, p}

pub fn main(flags: String) {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#cron-pixie-main", flags)

  Nil
}

fn init(flags: String) -> #(data.Model, effect.Effect(Msg)) {
  let model = case decode_flags(flags) {
    Ok(f) ->
      Model(
        example_events: f.example_events,
        auto_refresh: f.auto_refresh,
        refreshing: False,
      )
    _ -> Model(example_events: False, auto_refresh: False, refreshing: False)
  }
  #(model, effect.none())
}

type Msg

fn update(model: data.Model, _msg: Msg) -> #(data.Model, effect.Effect(Msg)) {
  #(model, effect.none())
}

fn view(_model: data.Model) -> element.Element(Msg) {
  div([], [p([], [text("Wibble")])])
}
