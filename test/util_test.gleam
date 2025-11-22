import util
import vec/vec3.{Vec3}
import vec/vec3f.{loosely_equals}

pub fn move_towards_test() {
  let result = util.move_towards(Vec3(0.0, 0.0, 0.0), Vec3(1.0, 0.0, 0.0), 0.5)
  let expected_result = Vec3(0.5, 0.0, 0.0)
  assert result == expected_result
}

pub fn move_towards_negative_direction_test() {
  let result = util.move_towards(Vec3(5.0, 0.0, 0.0), Vec3(0.0, 0.0, 0.0), 2.0)
  let expected_result = Vec3(3.0, 0.0, 0.0)
  assert result == expected_result
}

pub fn move_towards_3d_diagonal_test() {
  let result = util.move_towards(Vec3(0.0, 0.0, 0.0), Vec3(3.0, 4.0, 0.0), 2.5)
  let expected_result = Vec3(1.5, 2.0, 0.0)
  assert loosely_equals(result, expected_result, 0.001)
}

pub fn move_towards_zero_distance_test() {
  let start = Vec3(1.0, 2.0, 3.0)
  let result = util.move_towards(start, Vec3(5.0, 6.0, 7.0), 0.0)
  assert result == start
}

pub fn move_towards_same_position_test() {
  let pos = Vec3(1.0, 2.0, 3.0)
  let result = util.move_towards(pos, pos, 5.0)
  assert result == pos
}

pub fn move_towards_overshoot_test() {
  // Moving further than the distance to target
  let result = util.move_towards(Vec3(0.0, 0.0, 0.0), Vec3(1.0, 0.0, 0.0), 5.0)
  let expected_result = Vec3(5.0, 0.0, 0.0)
  assert result == expected_result
}
