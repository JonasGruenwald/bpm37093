import canvas.{type Context, type Event, Tick}
import gleam/list
import gleam_community/maths
import lustre/element.{type Element}
import space
import space_data
import theme
import util
import vec/vec2.{type Vec2, Vec2}
import vec/vec3.{type Vec3, Vec3}

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
    scale: 9.0,
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
          angle_y: model.angle_y +. 0.0005,
      )
    }
    _ -> model
  }
}

fn render(model: Model, ctx: Context, width: Float, height: Float) -> Nil {
  // Clear background
  canvas.set_fill_style(ctx, theme.background)
  canvas.fill_rect(ctx, 0.0, 0.0, width, height)

  canvas.set_font(ctx, "12px 'G2 Erika', sans-serif")

  draw_rings(ctx, model, width, height)  
  draw_stars(ctx, model, width, height)
  draw_lucy(ctx, model, width, height)
  draw_player(ctx, model, width, height)

}

fn project(
  point: Vec3(Float),
  model: Model,
  width: Float,
  height: Float,
) -> Vec2(Float) {
  let rotated =
    point
    |> util.rotate_y(model.angle_y)
    |> util.rotate_x(model.angle_x)
    |> util.rotate_z(model.angle_z)

  Vec2(
    x: { rotated.x *. model.scale } +. { width /. 2.0 },
    y: { height /. 2.0 } -. { rotated.y *. model.scale },
  )
}

const rings = [10.0, 20.0, 30.0, 40.0, 50.0]

fn draw_rings(ctx: Context, model: Model, width: Float, height: Float) {
  canvas.set_fill_style(ctx, "none")
  canvas.set_stroke_style(ctx, theme.diorama_ring)

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

const star_min_size = 2.0

const tether_line_width = 1.0

fn draw_stars(
  ctx: Context,
  model: Model,
  canvas_width: Float,
  canvas_height: Float,
) {
  list.each(model.stars, fn(star) {
    draw_star(ctx, model, star, canvas_width, canvas_height)
  })
}

fn draw_star(
  ctx: Context,
  model: Model,
  star: space.Object,
  canvas_width: Float,
  canvas_height: Float,
) {
  let projected = project(star.position, model, canvas_width, canvas_height)

  // Draw vertical line to horizontal plane
  // TODO: dashed lines from bottom, full lines from top?
  canvas.set_stroke_style(ctx, theme.diorama_tether)
  canvas.set_line_width(ctx, tether_line_width)
  let ground_point =
    project(
      Vec3(x: star.position.x, y: 0.0, z: star.position.z),
      model,
      canvas_width,
      canvas_height,
    )
  canvas.begin_path(ctx)
  canvas.move_to(ctx, projected.x, projected.y)
  canvas.line_to(ctx, ground_point.x, ground_point.y)
  canvas.stroke(ctx)

  // Draw the star
  canvas.set_fill_style(ctx, theme.diorama_star)
  canvas.begin_path(ctx)
  canvas.arc(ctx, projected.x, projected.y, star_min_size, 0.0, util.two_pi)
  canvas.fill(ctx)

  // Draw star name
  canvas.set_fill_style(ctx, theme.diorama_star_text)
  canvas.fill_text(ctx, star.name, projected.x +. 5.0, projected.y -. 5.0)
}

fn draw_lucy(
  ctx: Context,
  model: Model,
  canvas_width: Float,
  canvas_height: Float,
) {
  let projected = project(model.lucy.position, model, canvas_width, canvas_height)

  // Vertical tether line
  canvas.set_stroke_style(ctx, theme.diorama_lucy_tether)
  canvas.set_line_width(ctx, tether_line_width)
  let ground_point =
    project(
      Vec3(x: model.lucy.position.x, y: 0.0, z: model.lucy.position.z),
      model,
      canvas_width,
      canvas_height,
    )
  canvas.begin_path(ctx)
  canvas.move_to(ctx, projected.x, projected.y)
  canvas.line_to(ctx, ground_point.x, ground_point.y)
  canvas.stroke(ctx)

  // Indicator
  canvas.set_fill_style(ctx, theme.diorama_lucy)
  canvas.begin_path(ctx)
  canvas.arc(ctx, projected.x, projected.y, star_min_size, 0.0, util.two_pi)
  canvas.fill(ctx)

  // Label
  canvas.set_fill_style(ctx, theme.diorama_lucy)
  canvas.fill_text(ctx, "Lucy", projected.x +. 5.0, projected.y -. 5.0)
}

fn draw_player(
  ctx: Context,
  model: Model,
  canvas_width: Float,
  canvas_height: Float,
) {
  let projected = project(model.player.position, model, canvas_width, canvas_height)

  // Vertical tether line
  canvas.set_stroke_style(ctx, theme.diorama_tether)
  canvas.set_line_width(ctx, tether_line_width)
  let ground_point =
    project(
      Vec3(x: model.player.position.x, y: 0.0, z: model.player.position.z),
      model,
      canvas_width,
      canvas_height,
    )
  canvas.begin_path(ctx)
  canvas.move_to(ctx, projected.x, projected.y)
  canvas.line_to(ctx, ground_point.x, ground_point.y)
  canvas.stroke(ctx)

  // Indicator
  canvas.set_fill_style(ctx, theme.diorama_player)
  canvas.begin_path(ctx)
  canvas.arc(ctx, projected.x, projected.y, star_min_size, 0.0, util.two_pi)
  canvas.fill(ctx)

  // Label
  canvas.set_fill_style(ctx, theme.diorama_player)
  canvas.fill_text(ctx, "You", projected.x +. 5.0, projected.y -. 5.0)
}