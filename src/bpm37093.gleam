//// Game Loop

// IMPORTS ---------------------------------------------------------------------

import gleam/json
import space
import gleam/list
import gleam/float
import gleam/int
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import space_data.{lucy, sol, stars}
import theme
import console
import space_diorama
import util
import vec/vec3.{type Vec3}

// CONSTANTS -------------------------------------------------------------------

const seconds_in_an_hour = 3600

const hours_in_a_year = 8760

fn get_starting_speed() -> Float {
  // 25% the speed of light (in lightyears per hour)
  { 1.0 /. int.to_float(hours_in_a_year) } *. 0.25
}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  console.info("Let's go!")
  let assert Ok(_) = space_diorama.create()
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "body", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Action(msg) {
  Action(
    label: String,
    description: String,
    perform: fn(Model) -> #(Model, effect.Effect(Msg)),
  )
}

type Model {
  Model(
    // Day of progression, starting at 1
    day: Int,
    // Hour of the day, 0-23
    hour: Int,
    // Speed of the craft, in lightyears per tick (game hour)
    speed: Float,
    // Current 3D position in space
    position: Vec3(Float),
    // Actions available to the user
    actions: List(Action(Msg)),
  )
}

fn new_pilot_ship_action() -> Action(Msg) {
  Action(
    label: "Pilot Ship",
    description: "Manually pilot the ship towards the destination for one hour.",
    perform: fn(model: Model) -> #(Model, effect.Effect(Msg)) {
      Model(..simulate(model, 1), actions: [
        new_pilot_ship_action(),
      ])
      |> set_state
    },
  )
}

fn create_debug_hyperdrive_action() -> Action(Msg) {
  Action(
    label: "DEBUG Hyperdrive ",
    description: "Gotta go fast!",
    perform: fn(model: Model) -> #(Model, effect.Effect(Msg)) {
      set_state(
        Model(
          ..model,
          speed: 1.0
        )
      )
    },
  )
}

/// Shorthand for setting the model state without any effects.
fn set_state(model: Model) -> #(Model, effect.Effect(a)) {
  #(model, effect.none())
}

fn init(_) -> #(Model, effect.Effect(a)) {
  set_state(
    Model(
      day: 1,
      hour: 0,
      speed: get_starting_speed(),
      position: sol.position,
      actions: [new_pilot_ship_action(), create_debug_hyperdrive_action()],
    ),
  )
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserClickedActionButton(action: Action(Msg))
}

fn simulate(model: Model, hours: Int) -> Model {
  // Time progression
  let #(new_day, new_hour) = {
    let total_hours = model.hour + hours
    let additional_days = total_hours / 24
    let remaining_hours = total_hours % 24
    #(model.day + additional_days, remaining_hours)
  }

  Model(
    ..model,
    day: new_day,
    hour: new_hour,
    position: util.move_towards(
      model.position,
      lucy.position,
      model.speed *. int.to_float(hours),
    ),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserClickedActionButton(action) -> {
      console.info("User clicked action button: " <> action.label)
      action.perform(model)
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.id("root"),
      attribute.style("--background", theme.background),
      attribute.style("--text", theme.text),
    ],
    [
      html.div([attribute.class("game-panel")], [
        html.div(
          [attribute.class("actions-container")],
          list.map(model.actions, fn(action) -> Element(Msg) {
            view_button(UserClickedActionButton(action), action.label)
          }),
        ),
        view_int("Day", model.day),
        view_int("Hour", model.hour),
        view_float("Speed (ly/hour)", model.speed),
        view_float("Position X (ly)", model.position.x),
        view_float("Position Y (ly)", model.position.y),
        view_float("Position Z (ly)", model.position.z),
      ]),

      html.div([
        attribute.class("space-diorama-container"),
        ], [
        space_diorama.element(
          player: model.position,
        ),
      ]),
    ],
  )
}

fn view_button(on_click handle_click: msg, label text: String) -> Element(msg) {
  html.button([event.on_click(handle_click)], [html.text(text)])
}

fn view_int(label: String, count: Int) -> Element(msg) {
  html.p(
    [
      attribute.class(case count > 10 {
        True -> "text-red-500 font-bold"
        False -> ""
      }),
    ],
    [html.text(label <> ": "), html.text(int.to_string(count))],
  )
}

fn view_float(label: String, value: Float) -> Element(msg) {
  html.p([], [html.text(label <> ": "), html.text(float.to_string(value))])
}
