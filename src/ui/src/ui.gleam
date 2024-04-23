import internal/data
import lustre
import lustre/effect
import lustre/element.{text}
import lustre/element/html.{div, p}

// TODO: Use JSON object for flags.
pub fn main(flags: String) {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#cron-pixie-main", flags)

  Nil
}

// TODO: Use JSON object for flags.
fn init(flags: String) -> #(data.Model, effect.Effect(Msg)) {
  #(data.decode_flags(flags), effect.none())
}

type Msg

fn update(model: data.Model, _msg: Msg) -> #(data.Model, effect.Effect(Msg)) {
  #(model, effect.none())
}

fn view(_model: data.Model) -> element.Element(Msg) {
  div([], [p([], [text("Wibble")])])
}
