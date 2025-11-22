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
