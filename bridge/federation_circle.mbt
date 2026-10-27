///|
/// One-dimensional winding-number bridges.
///
/// Three pillars independently model the integers as the loop space
/// of a circle:
///
/// * cubical root: `SphereLoopExpr` with an integer degree;
/// * finalg/hott: the HIT path representation is already its winding;
/// * catmath: `S1Path` with encode/decode functions.
///
/// These adapters align only that shared integer invariant; they do
/// not identify the three ambient type theories.

///|
/// Winding number of a cubical sphere-loop expression.
pub fn winding_of_cubical_loop(expr : @cub.SphereLoopExpr) -> Int32 {
  @cub.sphere_loop_expr_degree(expr)
}

///|
/// Cubical sphere-loop expression of a prescribed winding number.
pub fn cubical_loop_of_winding(n : Int32) -> @cub.SphereLoopExpr {
  @cub.sphere_loop_expr_of_integer(n)
}

///|
/// Winding number of a catmath circle path.
pub fn winding_of_catmath_path(path : @catmath.S1Path) -> Int32 {
  @catmath.encode_s1(path)
}

///|
/// catmath circle path of a prescribed winding number.
pub fn catmath_path_of_winding(n : Int32) -> @catmath.S1Path {
  @catmath.decode_s1(n)
}

///|
/// finalg/hott circle loop of a prescribed winding number.  finalg's
/// computational representation of this loop is the integer itself.
pub fn finalg_loop_of_winding(n : Int32) -> Int32 {
  @fhott.s1_loop(n)
}

///|
/// Check that all three winding-number round trips and the finalg
/// groupoid laws agree on a finite list of integers.  Pairwise finalg
/// laws use consecutive samples when at least three are supplied.
pub fn circle_winding_cross_check(samples : Array[Int32]) -> Bool {
  for n in samples {
    guard winding_of_cubical_loop(cubical_loop_of_winding(n)) == n else {
      return false
    }
    guard winding_of_catmath_path(catmath_path_of_winding(n)) == n else {
      return false
    }
    guard finalg_loop_of_winding(n) == n else { return false }
  }
  if samples.length() >= 3 {
    for i in 0..<(samples.length() - 2) {
      guard @fhott.s1_groupoid_laws(samples[i], samples[i + 1], samples[i + 2]) else {
        return false
      }
    }
  }
  true
}
