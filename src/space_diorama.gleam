import gleam_community/maths
import gleam/list
import util
import canvas.{type Context, type Event, Tick}
import space
import vec/vec3.{type Vec3,Vec3}
import vec/vec2.{type Vec2,Vec2}
import space_data
import lustre/element.{type Element}
import theme

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
    scale: Float,
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
    scale: 1.0,
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
  model: Model,
  ctx: Context,
  width: Float,
  height: Float,
) -> Nil {
  // Clear background
  canvas.set_fill_style(ctx, theme.background)
  canvas.fill_rect(ctx, 0.0, 0.0, width, height)

  draw_rings(ctx, model, width, height)
}

fn project(
  point: Vec3(Float),
  model: Model,
  width: Float,
  height: Float,
) -> Vec2(Float){
  let rotated = point
    |> util.rotate_x(model.angle_x)
    |> util.rotate_y(model.angle_y)
    |> util.rotate_z(model.angle_z)

    Vec2(
      x: {rotated.x *. model.scale} +. {width /. 2.0},
      y: {rotated.y *. model.scale} +. {height /. 2.0},
    )
}

const rings = [100.0, 200.0, 300.0]

fn draw_rings(
  ctx: Context,
  model: Model,
  width: Float,
  height: Float,
) {
  canvas.set_fill_style(ctx, "none")
  canvas.set_stroke_style(ctx, theme.diorama_rings)

  let center = project(Vec3(x: 0.0, y: 0.0, z: 0.0), model, width, height)

  list.each(rings, fn(radius) {
    // Horizontal appearance is only affected by scale
    let radius_x = radius *. model.scale
    // Vertical appearance is affected by scale and camera angle
    let radius_y = radius *. model.scale *. maths.sin(model.angle_x)

    canvas.begin_path(ctx)
    canvas.ellipse(
      ctx,
      center.x,
      center.y,
      radius_x,
      radius_y,
      0.0,
      0.0,
      util.two_pi,
    )
    canvas.stroke(ctx)
  })
  
}