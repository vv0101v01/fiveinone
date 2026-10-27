///|
/// Bounded tropical corner loci for the direct federation.
///
/// Tropical geometry supplies the geometric unification axis:
/// a classical polynomial over a valued field is read through
/// the valuations of its coefficients, and its tropical
/// hypersurface is the corner locus where the minimum of
/// `val(c_alpha) + alpha·w` is attained at least twice.  The
/// univariate report below is that exact p-adic construction on
/// a bounded integer sample.
///
/// The multivariate finalg report is intentionally weaker and
/// is named accordingly.  A finite-field coefficient has only
/// the trivial valuation in this bridge (nonzero coefficients
/// map to 0), and a single lex Gröbner basis need not be a
/// tropical basis.  We therefore compute and compare two
/// explicitly labelled bounded *corner-locus samples*: one from
/// the given generators and one refined by all polynomials in
/// finalg's Gröbner basis.  Their inclusion is a theorem of the
/// definitions, because every basis element lies in the same
/// ideal and hence can only add necessary corner conditions.
/// Neither sample is silently promoted to a full polyhedral
/// tropical variety or to a tropical scheme.

///|
fn tropical_abs_i32(x : Int32) -> Int32 {
  if x < 0 {
    -x
  } else {
    x
  }
}

///|
fn tropical_finalg_poly_shape_ok(p : @finalg.Poly) -> Bool {
  guard p.nvars >= 0 && p.modulus >= 2 else { return false }
  for term in p.terms {
    guard term.exp.length() == p.nvars else { return false }
    guard term.coeff.val != 0 && term.coeff.modulus == p.modulus else {
      return false
    }
    for exponent in term.exp {
      guard exponent >= 0 && exponent <= 10000 else { return false }
    }
  }
  true
}

///|
fn tropical_point_shape_ok(point : Array[Int32]) -> Bool {
  for coordinate in point {
    guard tropical_abs_i32(coordinate) <= 10000 else { return false }
  }
  true
}

///|
fn tropical_term_value(term : @finalg.Term, point : Array[Int32]) -> Int64 {
  let mut value = 0L
  for i in 0..<term.exp.length() {
    value = value + term.exp[i].to_int64() * point[i].to_int64()
  }
  value
}

///|
/// Whether the trivial-valuation tropicalization of one finalg
/// polynomial has a corner at `point`: its minimum monomial
/// weight is attained at least twice.  The zero polynomial is
/// vacuous.  Invalid shapes return `false`.
pub fn finalg_poly_tropical_corner_at(
  p : @finalg.Poly,
  point : Array[Int32],
) -> Bool {
  guard tropical_finalg_poly_shape_ok(p) &&
    point.length() == p.nvars &&
    tropical_point_shape_ok(point) else {
    return false
  }
  if p.terms.length() == 0 {
    return true
  }
  let mut best = tropical_term_value(p.terms[0], point)
  let mut multiplicity = 1
  for i in 1..<p.terms.length() {
    let value = tropical_term_value(p.terms[i], point)
    if value < best {
      best = value
      multiplicity = 1
    } else if value == best {
      multiplicity = multiplicity + 1
    }
  }
  multiplicity >= 2
}

///|
fn tropical_grid_count(nvars : Int32, lo : Int32, hi : Int32) -> Int32? {
  guard nvars >= 0 && nvars <= 8 else { return None }
  guard lo >= -10000 && hi <= 10000 && lo <= hi else { return None }
  let side = hi - lo + 1
  let mut count = 1
  for _i in 0..<nvars {
    guard count <= 4096 / side else { return None }
    count = count * side
  }
  Some(count)
}

///|
fn tropical_grid_point(
  nvars : Int32,
  lo : Int32,
  side : Int32,
  index0 : Int32,
) -> Array[Int32] {
  let mut index = index0
  let point = Array::make(nvars, lo)
  for coordinate in 0..<nvars {
    point[coordinate] = lo + index % side
    index = index / side
  }
  point
}

///|
fn tropical_corner_locus_on_grid(
  polys : Array[@finalg.Poly],
  nvars : Int32,
  lo : Int32,
  hi : Int32,
) -> Array[Array[Int32]]? {
  let count = match tropical_grid_count(nvars, lo, hi) {
    Some(count) => count
    None => return None
  }
  let side = hi - lo + 1
  let points : Array[Array[Int32]] = []
  for index in 0..<count {
    let point = tropical_grid_point(nvars, lo, side, index)
    let mut all_corner = true
    for poly in polys {
      if !finalg_poly_tropical_corner_at(poly, point) {
        all_corner = false
      }
    }
    if all_corner {
      points.push(point)
    }
  }
  Some(points)
}

///|
fn tropical_polys_ambient(polys : Array[@finalg.Poly]) -> (Int32, Int32)? {
  guard polys.length() > 0 else { return None }
  let nvars = polys[0].nvars
  let modulus = polys[0].modulus
  guard nvars <= 8 else { return None }
  for poly in polys {
    guard poly.nvars == nvars &&
      poly.modulus == modulus &&
      tropical_finalg_poly_shape_ok(poly) else {
      return None
    }
  }
  Some((nvars, modulus))
}

///|
/// Bounded integer-grid corner locus of a finite list of
/// finalg polynomials under the trivial coefficient valuation.
/// The grid is capped at 4096 points.
pub fn finalg_tropical_corner_locus_sample(
  polys : Array[@finalg.Poly],
  lo : Int32,
  hi : Int32,
) -> Array[Array[Int32]]? {
  let (nvars, _) = match tropical_polys_ambient(polys) {
    Some(ambient) => ambient
    None => return None
  }
  tropical_corner_locus_on_grid(polys, nvars, lo, hi)
}

///|
/// The bivariate support of a finalg polynomial as a semiring
/// tropical polynomial with every nonzero coefficient sent to
/// tropical coefficient 0.  This is only the trivial-valuation
/// bivariate shadow used for Newton-subdivision checks.
pub fn finalg_poly_to_tropical_bpoly(p : @finalg.Poly) -> @strop.BPoly? {
  guard p.nvars == 2 && tropical_finalg_poly_shape_ok(p) else { return None }
  let terms : Array[@strop.BTerm] = []
  for term in p.terms {
    terms.push(@strop.BTerm::new(0, term.exp[0], term.exp[1]))
  }
  Some(@strop.BPoly::new(terms))
}

///|
fn tropical_point_in(
  point : Array[Int32],
  points : Array[Array[Int32]],
) -> Bool {
  for candidate in points {
    if int_arrays_equal(point, candidate) {
      return true
    }
  }
  false
}

///|
fn tropical_points_subset(
  subset : Array[Array[Int32]],
  superset : Array[Array[Int32]],
) -> Bool {
  for point in subset {
    guard tropical_point_in(point, superset) else { return false }
  }
  true
}

///|
fn tropical_bpoly_checks(
  polys : Array[@finalg.Poly],
) -> (Bool, Bool, Bool, Bool, Bool) {
  // Aggregate every eligible bivariate generator.  Returning
  // after the first one would make the report's bivariate
  // fields claim more than was actually checked.
  let mut supported = false
  let mut all_duality_ok = true
  let mut all_balancing_ok = true
  let mut all_ties_ok = true
  let mut all_area_ok = true
  for poly in polys {
    let bpoly = match finalg_poly_to_tropical_bpoly(poly) {
      Some(bpoly) => bpoly
      None => continue
    }
    guard bpoly.terms.length() >= 3 && bpoly.newton_area2() > 0L else {
      continue
    }
    supported = true
    let faces = bpoly.subdivision()
    if faces.length() == 0 {
      all_duality_ok = false
      all_balancing_ok = false
      all_ties_ok = false
      all_area_ok = false
      continue
    }
    let (dual_ok_count, dual_bad_count) = bpoly.check_duality(faces)
    all_duality_ok = all_duality_ok &&
      dual_bad_count == 0 &&
      dual_ok_count == faces.length()
    let edges = bpoly.dual_curve(faces)
    let residuals = @strop.balancing_residuals(edges, faces.length())
    let mut balancing_ok = residuals.length() == faces.length()
    for (_, residual_x, residual_y) in residuals {
      if residual_x != 0L || residual_y != 0L {
        balancing_ok = false
      }
    }
    all_balancing_ok = all_balancing_ok && balancing_ok
    let (_, _, unexplained) = bpoly.check_ties_on_faces(faces, 256, 7717UL)
    all_ties_ok = all_ties_ok && unexplained == 0
    all_area_ok = all_area_ok &&
      bpoly.subdivision_area2(faces) == bpoly.newton_area2()
  }
  if supported {
    (true, all_duality_ok, all_balancing_ok, all_ties_ok, all_area_ok)
  } else {
    (false, false, false, false, false)
  }
}

///|
/// Report for bounded multivariate tropical corner samples of
/// a finalg ideal presented by generators.
///
/// `grobner_refines_generators_on_sample` is an inclusion, not
/// a claim that the lex basis is a tropical basis.  Membership
/// in both directions separately verifies that the computed
/// basis presents the same classical ideal.
pub(all) struct TropicalCornerSampleReport {
  valid : Bool
  supported : Bool
  nvars : Int32
  modulus : Int32
  generator_count : Int32
  groebner_count : Int32
  lower_bound : Int32
  upper_bound : Int32
  sample_point_count : Int32
  generator_points : Array[Array[Int32]]
  groebner_points : Array[Array[Int32]]
  generator_point_count : Int32
  groebner_point_count : Int32
  groebner_refines_generators_on_sample : Bool
  samples_equal : Bool
  ideal_membership_ok : Bool
  bivariate_supported : Bool
  bivariate_duality_ok : Bool
  bivariate_balancing_ok : Bool
  bivariate_ties_ok : Bool
  bivariate_area_ok : Bool
}

///|
fn invalid_tropical_corner_sample_report() -> TropicalCornerSampleReport {
  {
    valid: false,
    supported: false,
    nvars: 0,
    modulus: 0,
    generator_count: 0,
    groebner_count: 0,
    lower_bound: 0,
    upper_bound: 0,
    sample_point_count: 0,
    generator_points: [],
    groebner_points: [],
    generator_point_count: 0,
    groebner_point_count: 0,
    groebner_refines_generators_on_sample: false,
    samples_equal: false,
    ideal_membership_ok: false,
    bivariate_supported: false,
    bivariate_duality_ok: false,
    bivariate_balancing_ok: false,
    bivariate_ties_ok: false,
    bivariate_area_ok: false,
  }
}

///|
/// Build the bounded multivariate tropical corner report.
pub fn tropical_corner_sample_report(
  generators : Array[@finalg.Poly],
  lo : Int32,
  hi : Int32,
) -> TropicalCornerSampleReport {
  let (nvars, modulus) = match tropical_polys_ambient(generators) {
    Some(ambient) => ambient
    None => return invalid_tropical_corner_sample_report()
  }
  guard @fnum.is_prime(modulus) else {
    return invalid_tropical_corner_sample_report()
  }
  let sample_point_count = match tropical_grid_count(nvars, lo, hi) {
    Some(count) => count
    None => return invalid_tropical_corner_sample_report()
  }
  let basis = @finalg.groebner_basis(generators)
  for poly in basis {
    guard poly.nvars == nvars &&
      poly.modulus == modulus &&
      tropical_finalg_poly_shape_ok(poly) else {
      return invalid_tropical_corner_sample_report()
    }
  }
  let generator_points = match
    tropical_corner_locus_on_grid(generators, nvars, lo, hi) {
    Some(points) => points
    None => return invalid_tropical_corner_sample_report()
  }
  let groebner_points = match
    tropical_corner_locus_on_grid(basis, nvars, lo, hi) {
    Some(points) => points
    None => return invalid_tropical_corner_sample_report()
  }
  let mut ideal_membership_ok = true
  for element in basis {
    if !@finalg.ideal_membership(element, generators) {
      ideal_membership_ok = false
    }
  }
  for generator in generators {
    if !@finalg.ideal_membership(generator, basis) {
      ideal_membership_ok = false
    }
  }
  let refines = tropical_points_subset(groebner_points, generator_points)
  let samples_equal = int_rows_equal(groebner_points, generator_points)
  let (
    bivariate_supported,
    bivariate_duality_ok,
    bivariate_balancing_ok,
    bivariate_ties_ok,
    bivariate_area_ok,
  ) = if nvars == 2 {
    tropical_bpoly_checks(generators)
  } else {
    (false, false, false, false, false)
  }
  let valid = refines &&
    ideal_membership_ok &&
    (
      !bivariate_supported ||
      (
        bivariate_duality_ok &&
        bivariate_balancing_ok &&
        bivariate_ties_ok &&
        bivariate_area_ok
      )
    )
  {
    valid,
    supported: true,
    nvars,
    modulus,
    generator_count: generators.length(),
    groebner_count: basis.length(),
    lower_bound: lo,
    upper_bound: hi,
    sample_point_count,
    generator_points,
    groebner_points,
    generator_point_count: generator_points.length(),
    groebner_point_count: groebner_points.length(),
    groebner_refines_generators_on_sample: refines,
    samples_equal,
    ideal_membership_ok,
    bivariate_supported,
    bivariate_duality_ok,
    bivariate_balancing_ok,
    bivariate_ties_ok,
    bivariate_area_ok,
  }
}

///|
/// Whether the bounded multivariate tropical corner report is
/// internally and cross-member consistent.
pub fn check_tropical_corner_sample(
  generators : Array[@finalg.Poly],
  lo : Int32,
  hi : Int32,
) -> Bool {
  tropical_corner_sample_report(generators, lo, hi).valid
}

///|
/// Report for the exact integer points of a p-adic univariate
/// tropical hypersurface in a bounded interval.
pub(all) struct PadicTropicalHypersurfaceReport {
  valid : Bool
  supported : Bool
  prime : Int32
  lower_bound : Int32
  upper_bound : Int32
  tropical_roots : Array[(Int64, Int64)]
  integer_corner_points : Array[Int32]
  integer_roots_in_range : Array[Int32]
  integer_corners_ok : Bool
}

///|
fn invalid_padic_tropical_report(
  prime : Int32,
  lo : Int32,
  hi : Int32,
) -> PadicTropicalHypersurfaceReport {
  {
    valid: false,
    supported: false,
    prime,
    lower_bound: lo,
    upper_bound: hi,
    tropical_roots: [],
    integer_corner_points: [],
    integer_roots_in_range: [],
    integer_corners_ok: false,
  }
}

///|
/// Compare the p-adic tropicalization's exact rational roots
/// with a direct integer-grid corner computation.  The zero
/// polynomial is vacuous on the whole sample interval.
pub fn padic_tropical_hypersurface_report(
  poly : @exactalg.QPoly,
  prime : Int32,
  lo : Int32,
  hi : Int32,
) -> PadicTropicalHypersurfaceReport {
  guard @fnum.is_prime(prime) && lo <= hi && lo >= -100000 && hi <= 100000 else {
    return invalid_padic_tropical_report(prime, lo, hi)
  }
  let tropical = qpoly_tropicalize_padic(poly, prime)
  let roots = federation_tropical_root_pairs(tropical)
  let is_zero = @exactalg.qpoly_degree(poly) < 0
  let corners : Array[Int32] = []
  for x in lo..<=hi {
    if is_zero || tropical.argmin_at(@strop.Rat::of_int(x)).length() >= 2 {
      corners.push(x)
    }
  }
  let integer_roots : Array[Int32] = []
  if is_zero {
    for x in lo..<=hi {
      integer_roots.push(x)
    }
  } else {
    for (numerator, denominator) in roots {
      if denominator == 1L &&
        numerator >= lo.to_int64() &&
        numerator <= hi.to_int64() {
        let value = numerator.to_int()
        if integer_roots.length() == 0 ||
          integer_roots[integer_roots.length() - 1] != value {
          integer_roots.push(value)
        }
      }
    }
  }
  let integer_corners_ok = int_arrays_equal(corners, integer_roots)
  {
    valid: integer_corners_ok,
    supported: true,
    prime,
    lower_bound: lo,
    upper_bound: hi,
    tropical_roots: roots,
    integer_corner_points: corners,
    integer_roots_in_range: integer_roots,
    integer_corners_ok,
  }
}

///|
/// Whether direct p-adic corner sampling agrees with the
/// tropical polynomial's exact root list on this interval.
pub fn check_padic_tropical_hypersurface(
  poly : @exactalg.QPoly,
  prime : Int32,
  lo : Int32,
  hi : Int32,
) -> Bool {
  padic_tropical_hypersurface_report(poly, prime, lo, hi).valid
}
