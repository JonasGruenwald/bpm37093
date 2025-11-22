import vec/vec3f
import vec/vec3.{type Vec3}

pub fn move_towards(
  from: Vec3(Float),
  to: Vec3(Float),
  distance: Float
){
  let direction = vec3f.subtract(to, from)
  let length = vec3f.length(direction)

  case length{
    0.0 -> from
    _ -> {
      let unit_direction = vec3f.scale(direction, 1.0 /. length)
      let movement = vec3f.scale(unit_direction, distance)
      vec3f.add(from, movement)
    }
  }
}