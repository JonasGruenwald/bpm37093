import util
import gleam/json
import gleam/dynamic/decode
import vec/vec3.{ type Vec3}

/// A celestial object
pub type Object {
  Object(
    name: String,
    short_name: String,
    // Cartesian xyz coordinates in light years from earth
    position: Vec3(Float),
    // Distance from earth in light years
    earth_distance: Float,
  )
}

pub fn object_to_json(object: Object) -> json.Json {
  let Object(name:, short_name:, position:, earth_distance:) = object
  json.object([
    #("name", json.string(name)),
    #("short_name", json.string(short_name)),
    #("position", util.vec3_to_json(position)),
    #("earth_distance", json.float(earth_distance)),
  ])
}

pub fn object_decoder() -> decode.Decoder(Object) {
  use name <- decode.field("name", decode.string)
  use short_name <- decode.field("short_name", decode.string)
  use position <- decode.field("position", util.vec3_decoder())
  use earth_distance <- decode.field("earth_distance", decode.float)
  decode.success(Object(name:, short_name:, position:, earth_distance:))
}
