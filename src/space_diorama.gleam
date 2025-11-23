import canvas.{type Context, type Event, Tick}
import space
import space_data
import lustre/element.{type Element}

pub const component = "space-diorama"

pub fn create() -> Result(Nil, Nil) {
  canvas.register_component(component, init, update, render, [])
}

pub fn element() -> Element(msg) {
  element.element(component, [], [])
}


type Model {
  Model(
    stars: List(space.Object),
    player: space.Object,
    lucy: space.Object,
    sol: space.Object,
    angle_x: Float,
    angle_y: Float,
    angle_z: Float,
    zoom: Float,
    is_dragging: Bool,
    last_x: Float,
    last_y: Float,
  )
}

fn init() -> Model {
  Model(
    stars: space_data.stars,
    lucy: space_data.lucy,
    sol: space_data.sol,
    player: space_data.sol,
    angle_x: 0.3,
    angle_y: 0.3,
    angle_z: 0.0,
    zoom: 300.0,
    is_dragging: False,
    last_x: 0.0,
    last_y: 0.0,
  )
}

fn update(model: Model, event: Event) -> Model {
  case event {
    Tick(_timestamp) -> {
      Model(
        ..model,
        // TODO: tie to time delta
          angle_y: model.angle_y +. 0.001,
      )
    }
    _ -> model
  }
}

fn render(
  _model: Model,
  ctx: Context,
  width: Float,
  height: Float,
) -> Nil {
  // Clear background
  canvas.clear_rect(ctx, 0.0, 0.0, width, height)
}
