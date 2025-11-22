//// Game Loop

const seconds_in_a_year = 31_556_926

// IMPORTS ---------------------------------------------------------------------

import gleam/int
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import space_data.{lucy, sol, stars}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model{
  Model(
    /// Day of progression, starting at 1
    day: Int,
    /// Hour of the day, 0-23
    hour: Int,
    /// Speed of the craft, relative to the speed of light
    speed: Float
  )
}

/// Shorthand for setting the model state without any effects.
fn set_state(model: Model) -> #(Model, effect.Effect(a)) {
  #(model, effect.none())
}

fn init(_) -> #(Model, effect.Effect(a)) {
  set_state(Model(
    day: 1,
    hour: 0,
    // Traveling at 25% the speed of light to start
    speed: 0.25
  ))
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserClickedTickButton
}

fn simulate(model: Model, hours: Int) -> Model {
  // Time progression
  let #(new_day, new_hour) = {
    let total_hours = model.hour + hours
    let additional_days = total_hours / 24
    let remaining_hours = total_hours % 24
    #(model.day + additional_days, remaining_hours)
  }
  // TODO: Movement
  Model(
    day: new_day,
    hour: new_hour,
    speed: model.speed
  )
} 

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(a)) {
  case msg {
    UserClickedTickButton -> simulate(model, 1) |> set_state
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    // Labelled view functions give a similar experience to props in other
    // frameworks, while still just being functions!
    view_button(on_click: UserClickedTickButton, label: "Tick"),
    view_count("Day", model.day),
    view_count("Hour", model.hour),
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
fn view_count(label: String,count: Int) -> Element(msg) {
  html.p(
    [
      attribute.class(case count > 10 {
        True -> "text-red-500 font-bold"
        False -> ""
      }),
    ],
    [html.text(label<>": "), html.text(int.to_string(count))],
  )
}
