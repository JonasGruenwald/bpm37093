//// Game Loop

// IMPORTS ---------------------------------------------------------------------

import console
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import space
import space_data.{lucy, sol, stars}
import space_diorama
import theme
import util
import vec/vec3.{type Vec3}
import vec/vec3f

// CONSTANTS -------------------------------------------------------------------

const seconds_in_an_hour = 3600

const hours_in_a_year = 8760

const continue_glyph = "→"

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

type Message =
  String

/// Actions that may be available to the player
/// they depend on the model and are decided upon at render timee
type Action {
  PilotShipAction
  DisableAutoPilotAction
  EnableAutoPilotAction
}

/// Used to represent encounters and dialogue
type Prompt {
  Prompt(message: Message, responses: List(Response))
}

/// A prompt response is a kind of dynamic action the user can take,
/// which can affect the overall game state
type Response {
  // A response which is another prompt, for forming dialogue trees
  // the label will be written to the log
  PromptResponse(label: String, prompt: Prompt)
  // A response which allows the user to perform an action on the model
  ActionResponse(
    label: String,
    perform: fn(Model) -> #(Model, effect.Effect(Msg)),
  )
  // Response which just proceeds to the next prompt
  // like PromptResponse, but the label won't be written to the log
  ContinueResponse(label: String, prompt: Prompt)
  EndResponse(label: String)
}

type Model {
  Model(
    // Day of progression, starting at 1
    day: Int,
    // Hour of the day, 0-23
    hour: Int,
    // Speed of the craft, in lightyears per tick (game hour)
    speed: Float,
    // Position in space in cartesian lightyear coordinates
    position: Vec3(Float),
    // Distance traveled in lightyears
    distance_traveled: Float,
    distance_to_lucy: Float,
    prompt: Option(Prompt),
    // Log of past messages from prompts IN REVERSE
    message_log: List(Message),
    // Flags
    autopilot_available: Bool,
    autopilot_enabled: Bool,
    intro_completed: Bool,
    accepted_crew_help: Bool,
    // Resources
    scrap: Int,
    credits: Int,
    speed_upgrades: Int,
    // Checkpoints (at points of distance_traveled)
    last_waystation_at: Float,
    last_scrap_discovery_at: Float,
  )
}

/// Shorthand for setting the model state without any effects.
fn set_state(model: Model) -> #(Model, effect.Effect(a)) {
  #(model, effect.none())
}

/// Shorthand for setting a prompt in the model state.
fn set_prompt(model: Model, prompt: Prompt) -> #(Model, effect.Effect(a)) {
  set_state(Model(..model, prompt: Some(prompt)))
}

fn log_message(model: Model, message: Message) {
  Model(..model, message_log: [message, ..model.message_log], prompt: None)
}

/// Build list of linear dialogue options into a prompt tree
fn linear_dialogue(
  messages: List(Message),
  final_responses: List(Response),
) -> Prompt {
  case messages {
    [last_message] -> Prompt(message: last_message, responses: final_responses)
    [current_message, ..rest_messages] -> {
      Prompt(message: current_message, responses: [
        ContinueResponse(
          label: continue_glyph,
          prompt: linear_dialogue(rest_messages, final_responses),
        ),
      ])
    }
    [] -> {
      // Can never be reached
      Prompt(message: "", responses: [])
    }
  }
}

fn init(_) -> #(Model, effect.Effect(a)) {
  set_state(Model(
    day: 1,
    hour: 0,
    speed: get_starting_speed(),
    position: sol.position,
    distance_traveled: 0.0,
    distance_to_lucy: vec3f.distance(sol.position, lucy.position),
    prompt: Some(create_initro_dialogue()),
    message_log: [],
    autopilot_available: True,
    autopilot_enabled: False,
    intro_completed: False,
    accepted_crew_help: False,
    scrap: 0,
    credits: 0,
    speed_upgrades: 0,
    last_scrap_discovery_at: 0.0,
    last_waystation_at: 0.0,
  ))
}

fn create_initro_dialogue() -> Prompt {
  let intro_chain = [
    "You are standing on the bridge of the craft.
The room is illuminated only by the blue hue of the control panels.",
    "With a quiet hiss, the door opens.
The machinist and the navigator step in.",
    "The navigator looks concerned, the machinist's face is unreadable.",
    "Navigator: I think there must be some kind of error with the coordinates you gave us?",
  ]

  let continuation_chain = [
    "Navigator: 12 hours 38 minutes 49.78112 seconds right ascension, -49 degrees 48 minutes 0.2195 seconds declination? That's almost fifty light years from sol!",
    "Machinist: This scrap collection vessel. Not equipped for FTL travel. Won't even reach light speed with current config. Die of old age before we arrive.",
  ]

  let accept_crew_guidance = fn(model: Model) {
    let prompt =
      [
        "Navigator: No way we'll get this far without a working autopilot system!",
        "Machinist: Have to think.",
      ]
      |> linear_dialogue([EndResponse(label: continue_glyph)])
    #(
      Model(..model, accepted_crew_help: True, prompt: Some(prompt)),
      effect.none(),
    )
  }

  let final_decisions = [
    ActionResponse(label: "We'll get there.", perform: accept_crew_guidance),
    ActionResponse(
      label: "Then we better think of some way to get there quicker.",
      perform: accept_crew_guidance,
    ),
    EndResponse(label: "None of your concern, you are dismissed."),
    ActionResponse(
      label: "I need your help with this.",
      perform: accept_crew_guidance,
    ),
  ]

  let continuation = linear_dialogue(continuation_chain, final_decisions)

  linear_dialogue(intro_chain, [
    PromptResponse(label: "There is no error.", prompt: continuation),
    PromptResponse(label: "What's the matter?", prompt: continuation),
  ])
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserClickedActionButton(action: Action)
  UserClickedResponseButton(prompt: Prompt, response: Response)
  AutopilotTick
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserClickedActionButton(action) -> {
      handle_action(action, model)
    }
    UserClickedResponseButton(prompt, response) -> {
      handle_response(prompt, response, model)
    }
    AutopilotTick -> {
      case model.autopilot_enabled {
        True -> #(simulate(model, 1), trigger_autopilot_effect())
        _ -> set_state(model)
      }
    }
  }
}

fn handle_action(action: Action, model: Model) -> #(Model, effect.Effect(Msg)) {
  case action {
    PilotShipAction -> simulate(model, 1) |> set_state()
    DisableAutoPilotAction ->
      set_state(Model(..model, autopilot_enabled: False))
    EnableAutoPilotAction -> #(
      Model(..model, autopilot_enabled: True),
      trigger_autopilot_effect(),
    )
  }
}

fn handle_response(
  prompt: Prompt,
  response: Response,
  model: Model,
) -> #(Model, effect.Effect(Msg)) {
  // Shift processed prompt to log
  let model = log_message(model, prompt.message)
  // handle selected response
  case response {
    ActionResponse(label: label, perform:) ->
      Model(..model, message_log: ["«" <> label <> "»", ..model.message_log])
      |> perform()
    EndResponse(label: _) ->
      set_state(Model(..model, message_log: [], intro_completed: True))
    ContinueResponse(label: _, prompt:) ->
      set_state(Model(..model, prompt: Some(prompt)))
    PromptResponse(label:, prompt:) ->
      set_state(
        Model(
          ..model,
          message_log: ["«" <> label <> "»", ..model.message_log],
          prompt: Some(prompt),
        ),
      )
  }
}

fn simulate(model: Model, hours: Int) -> Model {
  // Time progression
  let #(day, hour) = {
    let total_hours = model.hour + hours
    let additional_days = total_hours / 24
    let remaining_hours = total_hours % 24
    #(model.day + additional_days, remaining_hours)
  }
  // Movement
  let distance_to_move = model.speed *. int.to_float(hours)
  let position =
    util.move_towards(model.position, lucy.position, distance_to_move)
  let distance_traveled = model.distance_traveled +. distance_to_move
  let distance_to_lucy = vec3f.distance(position, lucy.position)

  Model(..model, day:, hour:, position:, distance_traveled:, distance_to_lucy:)
}

/// These actions are always available to the player, when there is no active prompt
fn available_actions(model: Model) -> List(Action) {
  [
    case model.autopilot_enabled {
      True -> Some(DisableAutoPilotAction)
      False -> Some(PilotShipAction)
    },
    case model.autopilot_available && !model.autopilot_enabled {
      True -> Some(EnableAutoPilotAction)
      False -> None
    },
  ]
  |> option.values()
}

fn view_status(model: Model) {
  case model {
    Model(autopilot_enabled: True, ..) -> {
      html.text("The autopilot system is engaged.")
    }
    _ -> {
      html.text("You have the controls, all systems are running normally.")
    }
  }
}

fn trigger_autopilot_effect() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    util.set_timeout(fn() { dispatch(AutopilotTick) }, 1000)
    Nil
  })
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let hidden_for_intro_class = case model.intro_completed {
    True -> attribute.class("hidden-for-intro")
    False -> attribute.class("hidden-for-intro hidden")
  }
  html.div(
    [
      attribute.id("root"),
      attribute.style("--background", theme.background),
      attribute.style("--text", theme.text),
    ],
    [
      html.div([attribute.class("top-bar"), hidden_for_intro_class], [
        html.div([attribute.class("speed-indicator")], [
          html.text("Ship Speed: " <> util.format_speed_long(model.speed)),
        ]),
        html.div([attribute.class("distance-indicator")], [
          html.text(
            "Distance to Lucy: "
            <> util.format_distance_long(model.distance_to_lucy),
          ),
        ]),
        html.div([attribute.class("calendar")], [
          html.text(
            "Day: "
            <> int.to_string(model.day)
            <> " — "
            <> model.hour |> int.to_string |> string.pad_start(2, "0")
            <> ":00",
          ),
        ]),
      ]),
      html.div([attribute.class("game-panel")], [
        html.div([attribute.class("interaction-box")], [
          html.div(
            [attribute.class("message-log")],
            list.reverse(model.message_log)
              |> list.map(view_message),
          ),
          {
            case model.prompt {
              Some(prompt) -> view_prompt(prompt)
              None -> view_actions(model)
            }
          },
        ]),
        html.div([attribute.class("data-box"), hidden_for_intro_class], [
          // TODO
        // html.text("TODO: Data goes here"),
        ]),
      ]),

      html.div(
        [
          attribute.class("space-diorama-container"),
        ],
        [
          space_diorama.element(player: model.position),
        ],
      ),
    ],
  )
}

fn view_prompt(prompt: Prompt) {
  html.div([attribute.class("prompt")], [
    html.div([attribute.class("prompt-content")], [view_message(prompt.message)]),
    html.div(
      [attribute.class("actions-container")],
      list.map(prompt.responses, fn(response) -> Element(Msg) {
        view_button(
          on_click: UserClickedResponseButton(prompt, response),
          label: response.label,
        )
      }),
    ),
  ])
}

fn view_actions(model: Model) {
  let actions = available_actions(model)
  html.div([attribute.class("prompt")], [
    html.div([attribute.class("prompt-content")], [view_status(model)]),
    html.div(
      [attribute.class("actions-container")],
      list.map(actions, fn(action) -> Element(Msg) { view_action(action) }),
    ),
  ])
}

fn view_action(a: Action) {
  case a {
    PilotShipAction ->
      view_action_button(
        a,
        "Pilot Ship",
        "Pilot the ship towards the destination for one hour",
      )
    DisableAutoPilotAction ->
      view_action_button(
        a,
        "Disable Autopilot",
        "Disengage the autopilot system (The ship will stop moving by itself)",
      )
    EnableAutoPilotAction ->
      view_action_button(
        a,
        "Enable Autopilot",
        "Engage the autopilot system (The ship will start moving by itself)",
      )
  }
}

fn view_message(message: Message) {
  html.div([attribute.class("message")], [html.text(message)])
}

fn view_action_button(action: Action, title: String, _tooltip: String) {
  view_button(UserClickedActionButton(action), title)
}

fn view_button(on_click handle_click: msg, label text: String) -> Element(msg) {
  html.button([event.on_click(handle_click)], [html.text(text)])
}
