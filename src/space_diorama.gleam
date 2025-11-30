import canvas.{type Context, type Event, Tick}
import console
import gleam/json
import gleam/list
import gleam_community/maths
import lustre/attribute
import lustre/element.{type Element}
import space
import space_data
import theme
import util
import vec/vec2.{type Vec2, Vec2}
import vec/vec2f
import vec/vec3.{type Vec3, Vec3}

pub const component = "space-diorama"

const starting_scale = 8.0

const font = "14px 'G2 Erika', sans-serif"

const font_bold = "700 " <> font

const font_light = "300 " <> font

const star_min_size = 2.0

const tether_line_width = 1.0

const rings = [10.0, 20.0, 30.0, 40.0, 50.0]

const ring_line_width = 1.0

const player_cross_line_width = 1.0

const player_cross_size = 5.0

const max_star_name_distance = 100.0

pub fn create() -> Result(Nil, Nil) {
  canvas.register_component(component, init, update, render, [
    #("player", fn(data: String, model: Model) {
      case json.parse(data, util.vec3_decoder()) {
        Ok(position) -> {
          Model(..model, player: space.Object(..model.player, position:))
        }
        Error(e) -> {
          console.error("Failed to parse 'player' attribute JSON")
          console.error(data)
          console.error(e)
          model
        }
      }
    }),
  ])
}

pub fn element(player player_position: Vec3(Float)) -> Element(msg) {
  element.element(
    component,
    [
      attribute.attribute(
        "player",
        util.vec3_to_json(player_position) |> json.to_string,
      ),
    ],
    [],
  )
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
    mouse: Vec2(Float),
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
    scale: starting_scale,
    is_dragging: False,
    mouse: Vec2(0.0, 0.0),
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
    canvas.MouseMoved(x, y) -> {
      Model(..model, mouse: Vec2(x, y))
    }
    _ -> model
  }
}

fn render(model: Model, ctx: Context, width: Float, height: Float) -> Nil {
  // Clear background
  canvas.set_fill_style(ctx, theme.background)
  canvas.fill_rect(ctx, 0.0, 0.0, width, height)

  draw_rings(ctx, model, width, height)
  draw_stars(ctx, model, width, height)
  draw_lucy(ctx, model, width, height)
  draw_sol(ctx, model, width, height)
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
    // Center horizontally on the riught two-thirds of the canvas
    x: { rotated.x *. model.scale } +. { width *. 0.66 },
    y: { height /. 2.0 } -. { rotated.y *. model.scale },
  )
}

fn draw_rings(ctx: Context, model: Model, width: Float, height: Float) {
  canvas.set_fill_style(ctx, "none")
  canvas.set_stroke_style(ctx, theme.diorama_ring)
  canvas.set_line_width(ctx, ring_line_width)

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
  let mouse_dist_squared = vec2f.distance_squared(projected, model.mouse)

  // Draw vertical line to horizontal plane
  // TODO: dashed lines from bottom, full lines from top?
  canvas.set_stroke_style(ctx, theme.diorama_star_tether)
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

  // console.log(model.mouse)

  case mouse_dist_squared <=. max_star_name_distance {
    True -> {
      // Draw star name
      canvas.set_font(ctx, font_light)
      canvas.set_text_align(ctx, "start")
      canvas.set_fill_style(ctx, theme.diorama_star_text)
      canvas.fill_text(ctx, star.name, projected.x +. 5.0, projected.y -. 5.0)
    }
    _ -> Nil
  }
}

fn draw_lucy(
  ctx: Context,
  model: Model,
  canvas_width: Float,
  canvas_height: Float,
) {
  let projected =
    project(model.lucy.position, model, canvas_width, canvas_height)

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
  canvas.set_font(ctx, font_bold)
  canvas.set_text_align(ctx, "start")
  canvas.set_fill_style(ctx, theme.diorama_lucy)
  canvas.fill_text(ctx, "Lucy", projected.x +. 5.0, projected.y -. 5.0)
}

fn draw_player(
  ctx: Context,
  model: Model,
  canvas_width: Float,
  canvas_height: Float,
) {
  let projected =
    project(model.player.position, model, canvas_width, canvas_height)

  // Indicator cross
  canvas.set_stroke_style(ctx, theme.diorama_player)
  canvas.set_line_width(ctx, player_cross_line_width)
  canvas.begin_path(ctx)
  canvas.move_to(ctx, projected.x, projected.y -. player_cross_size)
  canvas.line_to(ctx, projected.x, projected.y +. player_cross_size)
  canvas.move_to(ctx, projected.x -. player_cross_size, projected.y)
  canvas.line_to(ctx, projected.x +. player_cross_size, projected.y)
  canvas.stroke(ctx)

  // Label
  canvas.set_font(ctx, font_bold)
  canvas.set_text_align(ctx, "start")
  canvas.set_fill_style(ctx, theme.diorama_player)
  canvas.fill_text(ctx, "You", projected.x +. 5.0, projected.y -. 5.0)
}

fn draw_sol(
  ctx: Context,
  model: Model,
  canvas_width: Float,
  canvas_height: Float,
) {
  case model.player.position.z <. -4.5 {
    True -> {
      let projected =
        project(Vec3(0.0, 0.0, 0.0), model, canvas_width, canvas_height)

      // Icon
      canvas.set_text_align(ctx, "center")
      canvas.set_font(ctx, font_bold)
      canvas.set_fill_style(ctx, theme.diorama_player)
      canvas.fill_text(ctx, "☼", projected.x, projected.y +. 5.0)

      // Label
      canvas.set_text_align(ctx, "start")
      canvas.set_font(ctx, font_bold)
      canvas.set_fill_style(ctx, theme.diorama_player)
      canvas.fill_text(ctx, "Sol", projected.x +. 5.0, projected.y -. 5.0)
    }
    False -> Nil
  }
}
