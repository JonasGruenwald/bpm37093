
/// A celestial object
pub type Object {
  Object(
    name: String,
    short_name: String,
    // Cartesian xyz coordinates in light years from earth
    x: Float,
    y: Float,
    z: Float,
    // Distance from earth in light years
    earth_distance: Float,
  )
}
