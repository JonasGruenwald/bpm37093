import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
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

// pub fn format_distance_long(light_years: Float) -> String {
//   let whole = float.round(light_years)
//   let assert Ok(remainder) = float.modulo(light_years, 1.0)
//   let remainder_km = { lightyear_in_km *. remainder } |> float.round
//   case whole {
//     0 -> int.to_string(remainder_km) <> " kilometres"
//     _ -> {
//       int.to_string(whole)
//       <> " light years and "
//       <> int.to_string(remainder_km)
//       <> " kilometres"
//     }
//   }
// }

const lightyear_precision = 5

pub fn format_distance_long(light_years: Float) -> String {
   case light_years {
    _ if light_years <. 1.0 -> {
      { light_years *. lightyear_in_km } |> float.round |> int.to_string()
      <> " kilometres"
    }
    _ -> {
      float.to_precision(light_years, lightyear_precision) |> float.to_string()
      <> " light years "
    }
  }
}

pub fn format_speed_long(light_years: Float) -> String {
  case light_years {
    _ if light_years <. 1.0 -> {
      { light_years *. lightyear_in_km } |> float.round |> int.to_string()
      <> " km/h"
    }
    _ -> {
      float.to_precision(light_years, lightyear_precision) |> float.to_string()
      <> " ly/h"
    }
  }
}
