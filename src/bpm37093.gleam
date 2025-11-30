//// Game Loop

// IMPORTS ---------------------------------------------------------------------

import console
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import random
import space
import space_data.{lucy, sol, stars}
import space_diorama
import theme
import util
import vec/vec3.{type Vec3}
import vec/vec3f

// CONSTANTS -------------------------------------------------------------------

const scrap_bundle_size = 10

const autopilot_price = 190

const scrap_magnet_price = 500

const scrap_drone_price = 1000

const cryochambers_price = 10_000

const continue_glyph = "→"

const upgrade_base_cost = 200

const max_upgrades = 10

fn get_starting_speed() -> Float {
  // 25% the speed of light (in lightyears per hour)
  util.light_speed *. 0.25
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
  EnterCryosleepAction
  LeaveCryosleepAction
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

type Waystation {
  Waystation(name: String, scrap_price: Int)
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
    // Encounters & dialogue
    prompt: Option(Prompt),
    // Log of past messages from prompts IN REVERSE
    message_log: List(Message),
    // Station docking
    waystation: Option(Waystation),
    // Flags
    intro_completed: Bool,
    accepted_crew_help: Bool,
    // Upgrades
    autopilot_available: Bool,
    autopilot_enabled: Bool,
    autopilot_timeout_id: Int,
    scrap_magnet: Bool,
    scrap_drone: Bool,
    cryosleep_available: Bool,
    cryosleep_enabled: Bool,
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
    prompt: None,
    intro_completed: True,
    message_log: [],
    waystation: None,
    accepted_crew_help: False,
    autopilot_available: False,
    autopilot_enabled: False,
    autopilot_timeout_id: 0,
    scrap_magnet: False,
    scrap_drone: False,
    cryosleep_available: False,
    cryosleep_enabled: False,
    scrap: 0,
    credits: 0,
    speed_upgrades: 0,
    last_scrap_discovery_at: 0.0,
    last_waystation_at: 0.0,
  ) |> trigger_intro(),
  )
}

fn trigger_intro(model) -> Model {
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
        "Machinist: Need make ship faster.",
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

  let intro_prompt =
    linear_dialogue(intro_chain, [
      PromptResponse(label: "There is no error.", prompt: continuation),
      PromptResponse(label: "What's the matter?", prompt: continuation),
    ])

  Model(..model, prompt: Some(intro_prompt), intro_completed: False)
}

fn disable_autopilot(model: Model) -> Model {
  // This should really be an effect but I'm lazy
  util.clear_timeout(model.autopilot_timeout_id)
  Model(
    ..model,
    autopilot_enabled: False,
    cryosleep_enabled: False,
    autopilot_timeout_id: 0,
  )
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserClickedActionButton(action: Action)
  UserClickedResponseButton(prompt: Prompt, response: Response)
  UserClickedSellScrapAction(price: Int)
  UserClickedSellAllScrapAction(price: Int)
  UserClickedBuyAutopilotAction
  UserClickedBuyMagnetAction
  UserClickedBuyDroneAction
  UserClickedBuyCryochambersAction
  UserClickedBuySpeedUpgradeAction
  UserClickedLeaveStationAction
  AutopilotTimeoutScheduled(id: Int)
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
    UserClickedSellScrapAction(price) -> {
      Model(
        ..model,
        scrap: model.scrap - scrap_bundle_size,
        credits: model.credits + price,
      )
      |> set_state
    }
    UserClickedSellAllScrapAction(price) -> {
      let bundles = model.scrap / scrap_bundle_size
      let scrap_sold = bundles * scrap_bundle_size
      let credits_received = bundles * price
      Model(
        ..model,
        scrap: model.scrap - scrap_sold,
        credits: model.credits + credits_received,
      )
      |> set_state()
    }
    UserClickedBuyAutopilotAction -> {
      Model(
        ..model,
        credits: model.credits - autopilot_price,
        autopilot_available: True,
      )
      |> set_state
    }
    UserClickedBuyMagnetAction -> {
      Model(
        ..model,
        credits: model.credits - scrap_magnet_price,
        scrap_magnet: True,
      )
      |> set_state
    }
    UserClickedBuyCryochambersAction -> {
      Model(
        ..model,
        credits: model.credits - cryochambers_price,
        cryosleep_available: True,
      )
      |> set_state
    }
    UserClickedBuyDroneAction -> {
      Model(
        ..model,
        credits: model.credits - scrap_drone_price,
        scrap_drone: True,
      )
      |> set_state
    }
    UserClickedBuySpeedUpgradeAction -> {
      Model(
        ..model,
        credits: model.credits - speed_upgrade_cost(model),
        speed: model.speed *. 2.0,
        speed_upgrades: model.speed_upgrades + 1,
      )
      |> set_state()
    }
    UserClickedLeaveStationAction -> {
      Model(..model, waystation: None)
      |> set_state()
    }
    AutopilotTimeoutScheduled(id) -> {
      set_state(Model(..model, autopilot_timeout_id: id))
    }
    AutopilotTick -> {
      case model.autopilot_enabled {
        True -> {
          let ticks = case model.cryosleep_enabled {
            True -> 24
            False -> 1
          }
          #(simulate(model, ticks), trigger_autopilot_effect())
        }
        _ -> set_state(model)
      }
    }
  }
}

fn handle_action(action: Action, model: Model) -> #(Model, effect.Effect(Msg)) {
  case action {
    PilotShipAction -> simulate(model, 1) |> set_state()
    DisableAutoPilotAction -> {
      disable_autopilot(model)
      |> set_state()
    }
    EnableAutoPilotAction -> #(
      Model(..model, autopilot_enabled: True),
      trigger_autopilot_effect(),
    )
    EnterCryosleepAction -> #(
      Model(..model, cryosleep_enabled: True),
      effect.none(),
    )
    LeaveCryosleepAction -> {
      #(Model(..model, cryosleep_enabled: False), effect.none())
    }
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

fn pass_time(model: Model, hours: Int) {
  let total_hours = model.hour + hours
  let additional_days = total_hours / 24
  let remaining_hours = total_hours % 24
  #(model.day + additional_days, remaining_hours)
}

fn simulate(model: Model, hours: Int) -> Model {
  // Time progression
  let #(day, hour) = pass_time(model, hours)
  // Movement
  let distance_to_move = model.speed *. int.to_float(hours)
  // TODO fix overshoot!
  let position =
    util.move_towards(model.position, lucy.position, distance_to_move)
  let distance_traveled = model.distance_traveled +. distance_to_move
  let distance_to_lucy = vec3f.distance(position, lucy.position)
  // Ambient scrap collection
  let scrap = case model.scrap_magnet {
    True -> model.scrap + hours
    False -> model.scrap
  }

  let new_model =
    Model(
      ..model,
      day:,
      hour:,
      position:,
      distance_traveled:,
      distance_to_lucy:,
      scrap:,
    )
    |> evaluate_encounters()
  console.log_3("[Simulation]", hours, model)
  new_model
}

const scrap_base_steps = 20.0

const station_base_steps = 60.0

fn evaluate_encounters(model: Model) -> Model {
  let steps_since_last_waystation =
    { model.distance_traveled -. model.last_waystation_at } /. model.speed
  let steps_since_last_scrap =
    { model.distance_traveled -. model.last_scrap_discovery_at } /. model.speed

  let percentage_roll = int.random(100)

  case steps_since_last_waystation >=. station_base_steps {
    True if percentage_roll > 90 -> {
      trigger_waystation_encounter(model)
    }
    _ -> {
      case steps_since_last_scrap >=. scrap_base_steps {
        True if percentage_roll > 50 -> {
          trigger_scrap_encounter(model)
        }
        _ -> model
      }
    }
  }
}

fn trigger_waystation_encounter(model: Model) -> Model {
  let station_name = random.waystation_name()
  let scrap_price = int.random(5) + 5

  let prompt =
    Prompt(
      message: "You are passing by the waystation "
        <> station_name
        <> ".\n\n"
        <> "This station will buy scrap in bundles of "
        <> int.to_string(scrap_bundle_size)
        <> " for "
        <> int.to_string(scrap_price)
        <> " credits.\n"
        <> "You can purchase devices or upgrade your ship here.",
      responses: [
        ActionResponse(label: "Dock at waystation", perform: fn(model) {
          Model(
            ..model,
            message_log: [],
            prompt: None,
            waystation: Some(Waystation(
              name: station_name,
              scrap_price: scrap_price,
            )),
          )
          |> set_state
        }),
        EndResponse("Ignore Station"),
      ],
    )

  case model.cryosleep_enabled {
    True -> {
      Model(..model, last_waystation_at: model.distance_traveled, message_log: [
        "Recenly passed the "
        <> station_name
        <> " waystation while in cryosleep",
      ])
    }
    False -> {
      Model(
        ..model,
        prompt: Some(prompt),
        last_waystation_at: model.distance_traveled,
      )
      |> disable_autopilot()
    }
  }
}

fn trigger_scrap_encounter(model: Model) -> Model {
  let ship_name = random.ship_name()
  let duration = int.random(12) + 2
  let yield = int.random(150) + 1
  let age = int.random(100 + 2) |> int.to_string()

  let prompt =
    Prompt(
      message: "Alerts blare in the control room, the scanners have detected the nearby wreck of a space craft.\n\n"
        <> "The ruined hull of the "
        <> ship_name
        <> " has been drifting through space for "
        <> age
        <> " years. It is eligible for scrap collection by galactic law.\n"
        <> "Recovering scrap from this vessel would take around "
        <> int.to_string(duration)
        <> " hours.",
      responses: [
        ActionResponse(label: "Collect Scrap", perform: fn(model) {
          let #(day, hour) = pass_time(model, duration)
          Model(
            ..model,
            day:,
            hour:,
            scrap: model.scrap + yield,
            prompt: Some(
              Prompt(
                message: "After "
                  <> int.to_string(duration)
                  <> " hours of work, you have recovered a total of "
                  <> int.to_string(yield)
                  <> " pieces of scrap.",
                responses: [EndResponse(label: continue_glyph)],
              ),
            ),
          )
          |> set_state()
        }),
        EndResponse(label: "Ignore Wreck"),
      ],
    )

  case model.scrap_drone, model.cryosleep_enabled {
    True, _ -> {
      Model(
        ..model,
        last_scrap_discovery_at: model.distance_traveled,
        scrap: model.scrap + yield,
        message_log: [
          "Scrap harvester drone recently collected "
          <> int.to_string(yield)
          <> " scrap from the wreck of "
          <> ship_name
          <> ".",
        ],
      )
    }
    False, False -> {
      Model(
        ..model,
        last_scrap_discovery_at: model.distance_traveled,
        prompt: Some(prompt),
      )
      |> disable_autopilot()
    }
    False, True -> {
      Model(
        ..model,
        last_scrap_discovery_at: model.distance_traveled,
        message_log: [
          "Recently passed the wreck of " <> ship_name <> " while in cryosleep.",
        ],
      )
    }
  }
}

fn speed_upgrade_cost(model: Model) {
  let exponent = int.to_float(model.speed_upgrades)
  let multiplier = float.power(2.0, exponent) |> result.unwrap(1.0)
  float.round(multiplier *. int.to_float(upgrade_base_cost))
}

/// These actions are always available to the player, when there is no active prompt
fn available_actions(model: Model) -> List(Action) {
  []
  |> add_action_if(LeaveCryosleepAction, model.cryosleep_enabled)
  |> add_action_if(
    EnterCryosleepAction,
    model.autopilot_enabled
      && model.cryosleep_available
      && !model.cryosleep_enabled,
  )
  |> add_action_if(
    EnableAutoPilotAction,
    model.autopilot_available && !model.autopilot_enabled,
  )
  |> add_action_if(
    DisableAutoPilotAction,
    model.autopilot_enabled && !model.cryosleep_enabled,
  )
  |> add_action_if(PilotShipAction, !model.autopilot_enabled)
  |> list.reverse()
}

fn add_action_if(actions: List(Action), action: Action, predicate: Bool) {
  case predicate {
    True -> [action, ..actions]
    False -> actions
  }
}

fn view_status(model: Model) {
  html.div([], [
    case model {
      Model(autopilot_enabled: True, ..) -> {
        html.text("The autopilot system is engaged.")
      }
      _ -> {
        html.text("You have the controls, all systems are running normally. ")
      }
    },
    case model.cryosleep_enabled {
      True -> {
        html.text(" You are in cryosleep.")
      }
      False -> {
        element.none()
      }
    },
  ])
}

fn trigger_autopilot_effect() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let id = util.set_timeout(fn() { dispatch(AutopilotTick) }, 1000)
    dispatch(AutopilotTimeoutScheduled(id))
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
            case model {
              Model(prompt: Some(prompt), ..) -> view_prompt(prompt)
              Model(waystation: Some(station), ..) ->
                view_station(model, station)
              _ -> view_actions(model)
            }
          },
        ]),
        html.div([attribute.class("data-box"), hidden_for_intro_class], [
          view_data_point("Scrap", model.scrap),
          view_data_point("Credits", model.credits),
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

fn view_station(model: Model, station: Waystation) {
  html.div([attribute.class("prompt")], [
    html.div([attribute.class("prompt-content")], [
      view_message(
        "You are docked at the "
        <> station.name
        <> " station.\n\n"
        <> "At this station, you can sell "
        <> int.to_string(scrap_bundle_size)
        <> " pieces of scrap for "
        <> int.to_string(station.scrap_price)
        <> " credits.\n"
        <> "",
      ),
    ]),
    html.div([attribute.class("actions-container")], [
      view_sell_button(
        "Sell " <> int.to_string(scrap_bundle_size) <> " scrap",
        model.scrap,
        UserClickedSellScrapAction(station.scrap_price),
      ),
      view_sell_button(
        "Sell all scrap",
        model.scrap,
        UserClickedSellAllScrapAction(station.scrap_price),
      ),
      view_buy_button(
        "Autopilot System",
        UserClickedBuyAutopilotAction,
        model.autopilot_available,
        autopilot_price,
        model.credits,
        "Allows the vessel to fly on its own without the need for a pilot on the controls",
      ),
      view_buy_button(
        "Scrap Collection Magnet",
        UserClickedBuyMagnetAction,
        model.scrap_magnet,
        scrap_magnet_price,
        model.credits,
        "Automatically collects small pieces of scrap during flight",
      ),
      view_buy_button(
        "Scrap Harvester Drone",
        UserClickedBuyDroneAction,
        model.scrap_drone,
        scrap_drone_price,
        model.credits,
        "Automatically harvests the scrap of nearby shipwrecks",
      ),
      view_buy_button(
        "Cryochambers",
        UserClickedBuyCryochambersAction,
        model.cryosleep_available,
        cryochambers_price,
        model.credits,
        "Allows you to pass time significantly faster when using the autopilot system",
      ),
      view_buy_button(
        "Engine Upgrade",
        UserClickedBuySpeedUpgradeAction,
        model.speed_upgrades >= max_upgrades,
        speed_upgrade_cost(model),
        model.credits,
        "Allows you to pass time significantly faster when using the autopilot system",
      ),
      view_button(UserClickedLeaveStationAction, "Leave Station"),
    ]),
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
    EnterCryosleepAction ->
      view_action_button(
        a,
        "Enter Cryosleep",
        "Hibernate in your cryochamber - the days will start to feel like hours",
      )
    LeaveCryosleepAction ->
      view_action_button(
        a,
        "Leave Cryosleep",
        "Return to normal ship operation",
      )
  }
}

fn view_message(message: Message) {
  html.div([attribute.class("message")], [html.text(message)])
}

fn view_data_point(label: String, value: Int) {
  case value > 0 {
    True ->
      html.div([attribute.class("data-point")], [
        html.span([], [html.text(label <> ": ")]),
        html.span([], [html.text(int.to_string(value))]),
      ])
    False -> element.none()
  }
}

fn view_action_button(action: Action, title: String, tooltip: String) {
  html.button(
    [event.on_click(UserClickedActionButton(action)), attribute.title(tooltip)],
    [
      html.text(title),
    ],
  )
}

fn view_buy_button(
  title: String,
  message: Msg,
  already_bought: Bool,
  price: Int,
  available_credits: Int,
  tooltip: String,
) -> Element(Msg) {
  case already_bought {
    True -> element.none()
    False -> {
      let content = [
        html.span([], [html.text("Buy " <> title)]),
        html.span([], [html.text(int.to_string(price) <> " Credits")]),
      ]
      case available_credits >= price {
        True -> {
          html.button(
            [
              event.on_click(message),
              attribute.title(tooltip),
              attribute.class("buy"),
            ],
            content,
          )
        }
        False -> {
          html.button(
            [
              attribute.disabled(True),
              attribute.title(tooltip),
              attribute.class("buy"),
            ],
            content,
          )
        }
      }
    }
  }
}

fn view_sell_button(
  title: String,
  available_scrap: Int,
  message: Msg,
) -> Element(Msg) {
  html.button(
    [
      event.on_click(message),
      attribute.disabled(available_scrap < scrap_bundle_size),
      attribute.class("sell"),
    ],
    [html.text(title)],
  )
}

fn view_button(on_click handle_click: msg, label text: String) -> Element(msg) {
  html.button([event.on_click(handle_click)], [html.text(text)])
}
