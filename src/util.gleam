import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/string
import gleam_community/maths
import vec/vec3.{type Vec3, Vec3}
import vec/vec3f

pub fn move_towards(from: Vec3(Float), to: Vec3(Float), distance: Float) {
  let direction = vec3f.subtract(to, from)
  let length = vec3f.length(direction)

  case length {
    0.0 -> from
    _ -> {
      let unit_direction = vec3f.scale(direction, 1.0 /. length)
      let movement = vec3f.scale(unit_direction, distance)
      vec3f.add(from, movement)
    }
  }
}

pub fn rotate_x(point: Vec3(Float), angle: Float) -> Vec3(Float) {
  let cos_angle = maths.cos(angle)
  let sin_angle = maths.sin(angle)

  Vec3(
    x: point.x,
    y: point.y *. cos_angle -. point.z *. sin_angle,
    z: point.y *. sin_angle +. point.z *. cos_angle,
  )
}

pub fn rotate_y(point: Vec3(Float), angle: Float) -> Vec3(Float) {
  let cos_angle = maths.cos(angle)
  let sin_angle = maths.sin(angle)

  Vec3(
    x: point.x *. cos_angle +. point.z *. sin_angle,
    y: point.y,
    z: float.negate(point.x) *. sin_angle +. point.z *. cos_angle,
  )
}

pub fn rotate_z(point: Vec3(Float), angle: Float) -> Vec3(Float) {
  let cos_angle = maths.cos(angle)
  let sin_angle = maths.sin(angle)

  Vec3(
    x: point.x *. cos_angle -. point.y *. sin_angle,
    y: point.x *. sin_angle +. point.y *. cos_angle,
    z: point.z,
  )
}

pub fn vec3_to_json(vector: Vec3(Float)) -> json.Json {
  let Vec3(x:, y:, z:) = vector
  json.object([
    #("x", json.float(x)),
    #("y", json.float(y)),
    #("z", json.float(z)),
  ])
}

pub fn vec3_decoder() -> decode.Decoder(Vec3(Float)) {
  use x <- decode.field("x", decode.float)
  use y <- decode.field("y", decode.float)
  use z <- decode.field("z", decode.float)
  decode.success(Vec3(x:, y:, z:))
}

pub const two_pi = 6.283185307179586

pub const lightyear_in_km = 9_460_730_472_580.8

pub const hours_in_a_year = 8760

/// Light speed represented in light years per hour
pub const light_speed = 0.00011415525114155251

const lightyear_precision = 5

pub fn format_distance_long(light_years: Float) -> String {
  case light_years {
    _ if light_years <. 1.0 -> {
      { light_years *. lightyear_in_km } |> float.round |> int.to_string()
      <> " kilometres"
    }
    _ -> {
      format_to_precision(light_years, lightyear_precision) <> " light years "
    }
  }
}

fn format_to_precision(input: Float, precision: Int) {
  let base_string = float.to_precision(input, precision) |> float.to_string()
  let assert [before_point, after_point] = string.split(base_string, ".")
  before_point <> "." <> string.pad_end(after_point, precision, "0")
}

pub fn format_speed_long(light_years: Float) -> String {
  let relative_lightspeed = light_years /. light_speed
  let formatted_relative_lightspeed = case relative_lightspeed {
    _ if relative_lightspeed <. 1.0 ->
      relative_lightspeed |> float.to_precision(2) |> float.to_string()
    _ -> relative_lightspeed |> float.round() |> int.to_string()
  }

  { light_years *. lightyear_in_km } |> float.round |> int.to_string()
  <> " km/h ("
  <> formatted_relative_lightspeed
  <> "× light speed)"
}

@external(javascript, "./util_ffi.mjs", "setTimeout")
pub fn set_timeout(callback: fn() -> anything, delay: Int) -> Int

@external(javascript, "./util_ffi.mjs", "clearTimeout")
pub fn clear_timeout(id: Int) -> Nil
