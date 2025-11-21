// IMPORTS ---------------------------------------------------------------------

import gleam/int
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model =
  Int

/// Shorthand for setting the model state without any effects.
fn set_state(model: Model) -> #(Model, effect.Effect(a)) {
  #(model, effect.none())
}

fn init(_) -> #(Model, effect.Effect(a)) {
  set_state(0)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(a)) {
  case msg {
    UserClickedIncrement -> set_state(model + 1)
    UserClickedDecrement -> set_state(model - 1)
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    // Labelled view functions give a similar experience to props in other
    // frameworks, while still just being functions!
    view_button(on_click: UserClickedDecrement, label: "-"),
    view_count(model),
    view_button(on_click: UserClickedIncrement, label: "+"),
  ])
}

/// Re-usable ui elements in Lustre most often take the form of "view functions".
/// Because these are just Gleam functions, they can take any number of arguments
/// and often include messages or event handlers.
///
fn view_button(on_click handle_click: msg, label text: String) -> Element(msg) {
  html.button([event.on_click(handle_click)], [html.text(text)])
}

/// It's common practice for view functions that never produce events to return
/// `Element(msg)` instead of `Element(Nil)`. This allows you to use these view
/// functions in other contexts, while also communicating that these cannot
/// possibly produce events: there's no way to create a `msg` from nothing!
///
fn view_count(count: Int) -> Element(msg) {
  html.p(
    [
      attribute.class(case count > 10 {
        True -> "text-red-500 font-bold"
        False -> ""
      }),
    ],
    [html.text("Count: "), html.text(int.to_string(count))],
  )
}
