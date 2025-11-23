import gleam/float
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

pub const two_pi = 6.283185307179586 