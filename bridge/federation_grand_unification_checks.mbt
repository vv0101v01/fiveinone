///|
/// Canonical aggregate checks for the five post-v1 grand
/// unification construction items (GU-001 … GU-005).
///
/// Each function is the one bridge-level example suite for its
/// theorem family.  The individual reports remain the reusable
/// mathematical APIs; these checks only fix small cross-member
/// witnesses and the boundary cases that keep the reports honest.

///|
pub fn check_valued_initial_unification_bridge() -> Bool {
  let x = @exactalg.poly_var(0)
  let y = @exactalg.poly_var(1)
  let two = @exactalg.poly_int(2)
  let f = @exactalg.poly_add(two, @exactalg.poly_add(x, y))
  let centre = valued_initial_form_report(f, 2, [0, 0])
  guard centre.valid &&
    centre.initial_term_count == 2 &&
    !centre.is_monomial &&
    centre.bivariate_argmin_ok &&
    centre.bivariate_newton_supported else {
    return false
  }
  let excluded = valued_initial_form_report(f, 2, [1, 0])
  guard excluded.valid && excluded.is_monomial else { return false }
  let g = @exactalg.poly_add(
    @exactalg.poly_int(1),
    @exactalg.poly_add(@exactalg.poly_scale(@exactalg.rat_int(2), x), y),
  )
  let g_centre = valued_initial_form_report(g, 2, [0, 0])
  guard g_centre.valid && g_centre.initial_term_count == 2 else { return false }
  let h = @exactalg.poly_mul(
    @exactalg.poly_sub(x, @exactalg.poly_int(2)),
    @exactalg.poly_sub(x, @exactalg.poly_int(4)),
  )
  let h_root = valued_initial_form_report(h, 2, [1])
  let h_monomial = valued_initial_form_report(h, 2, [0])
  guard h_root.valid &&
    h_root.univariate_corner_ok &&
    h_root.initial_term_count == 2 &&
    h_monomial.valid &&
    h_monomial.is_monomial else {
    return false
  }
  let grid = valued_initial_ideal_grid_report([f], 2, 2, -1, 1)
  grid.valid &&
  grid.principal_exact &&
  tropical_point_in([0, 0], grid.candidate_weights) &&
  tropical_point_in([1, 0], grid.excluded_weights)
}

///|
pub fn check_relation_quantale_unification_bridge() -> Bool {
  let path : Array[Array[Bool]] = [
    [false, true, false],
    [false, false, true],
    [false, false, false],
  ]
  let step : Array[Array[Bool]] = [
    [true, false, false],
    [false, true, true],
    [false, false, true],
  ]
  let target : Array[Array[Bool]] = [
    [true, true, true],
    [false, true, true],
    [false, false, true],
  ]
  let triple = finite_relation_quantale_report(path, step, target)
  guard triple.valid && bool_matrices_equal(triple.star_relation, target) else {
    return false
  }
  let exhaustive = finite_relation_quantale_report(
    [[false, true], [false, false]],
    [[true, false], [false, true]],
    [[true, true], [true, true]],
  )
  guard exhaustive.valid && exhaustive.exhaustive_supported else {
    return false
  }
  let chain = @catmath.make_top(3, [
    [true, true, true],
    [false, true, true],
    [false, false, true],
  ])
  let preorder = finite_relation_quantale_report(
    chain.le,
    [[true, false, false], [false, true, false], [false, false, true]],
    chain.le,
  )
  guard preorder.valid && bool_matrices_equal(preorder.star_relation, chain.le) else {
    return false
  }
  let inf = @semialg.trop_inf
  let tropical = finite_tropical_matrix_quantale_report(
    [[0, 2], [inf, 1]],
    [[1, inf], [0, 2]],
    [[2, 2], [1, 2]],
    2,
  )
  guard tropical.valid && tropical.exhaustive_supported else { return false }
  let tropical_path = finite_tropical_matrix_quantale_report(
    [[0, 2, inf], [inf, 0, 1], [inf, inf, 0]],
    [[0, inf, inf], [inf, 0, inf], [inf, inf, 0]],
    [[0, 2, 2], [inf, 0, 1], [inf, inf, 0]],
    2,
  )
  tropical_path.valid && tropical_path.star_matrix[0][2] == 3
}

///|
pub fn check_presheaf_sieve_unification_bridge() -> Bool {
  let arrow = finite_presheaf_sieve_report(@sym.cat_arrow(), 1)
  guard arrow.valid && arrow.sieve_count == 3 && !arrow.is_Boolean else {
    return false
  }
  let cospan = finite_presheaf_sieve_report(@sym.cat_cospan(), 2)
  guard cospan.valid && cospan.sieve_count == 5 else { return false }
  let parallel = finite_presheaf_sieve_report(@sym.cat_parallel(), 1)
  guard parallel.valid && parallel.sieve_count == 5 else { return false }
  let chain = @catmath.make_top(3, [
    [true, true, true],
    [false, true, true],
    [false, false, true],
  ])
  let alexandrov = finite_presheaf_alexandrov_report(chain)
  alexandrov.valid && alexandrov.open_count == 4
}

///|
pub fn check_blueprint_unification_bridge() -> Bool {
  let free = match
    finite_blueprint_free_monoid(3, 0, 1, [[0, 0, 0], [0, 1, 2], [0, 2, 2]]) {
    Some(value) => value
    None => return false
  }
  let free_report = finite_blueprint_report(free)
  guard free_report.valid &&
    !free_report.complete_pair_sums &&
    finite_blueprint_sum_element(free, [2, 2]) == None &&
    finite_blueprint_sum_element(free, [0, 2]) == Some(2) else {
    return false
  }
  let f2 = match finite_field_blueprint(2) {
    Some(value) => value
    None => return false
  }
  guard finite_blueprint_report(f2).valid &&
    finite_blueprint_add(f2, 1, 1) == Some(0) else {
    return false
  }
  let bool_bp = bool_semiring_blueprint()
  let mut bool_matches_semiring = finite_blueprint_report(bool_bp).valid
  for a in 0..<2 {
    for b in 0..<2 {
      let left = @semialg.BoolSr::of(a == 1)
      let right = @semialg.BoolSr::of(b == 1)
      let plus_index = if @semialg.BoolSr::plus(left, right).b { 1 } else { 0 }
      let times_index = if @semialg.BoolSr::times(left, right).b {
        1
      } else {
        0
      }
      if finite_blueprint_add(bool_bp, a, b) != Some(plus_index) ||
        finite_blueprint_mul(bool_bp, a, b) != Some(times_index) {
        bool_matches_semiring = false
      }
    }
  }
  guard bool_matches_semiring && finite_blueprint_add(bool_bp, 1, 1) == Some(1) else {
    return false
  }
  let tropical = match bounded_tropical_blueprint(3) {
    Some(value) => value
    None => return false
  }
  let mut tropical_matches_semiring = finite_blueprint_report(tropical).valid
  for a in 0..<tropical.n {
    for b in 0..<tropical.n {
      let left = if a == 0 {
        @semialg.Trop::inf()
      } else {
        @semialg.Trop::new(a - 1)
      }
      let right = if b == 0 {
        @semialg.Trop::inf()
      } else {
        @semialg.Trop::new(b - 1)
      }
      let plus = @semialg.Trop::plus(left, right)
      let plus_index = if plus.is_inf() { 0 } else { plus.value() + 1 }
      let times = @semialg.Trop::times(left, right)
      let times_index = if times.is_inf() {
        0
      } else {
        let capped = if times.value() > 3 { 3 } else { times.value() }
        capped + 1
      }
      if finite_blueprint_add(tropical, a, b) != Some(plus_index) ||
        finite_blueprint_mul(tropical, a, b) != Some(times_index) {
        tropical_matches_semiring = false
      }
    }
  }
  guard tropical_matches_semiring else { return false }
  let f4 = @ffinite.FinAlg::univariate_quotient(2, [1, 1, 1])
  let f4_blueprint = match finite_blueprint_of_finalg_alg(f4) {
    Some(value) => value
    None => return false
  }
  guard f4_blueprint.n == 4 && finite_blueprint_report(f4_blueprint).valid else {
    return false
  }
  let chain = @catmath.make_top(3, [
    [true, true, true],
    [false, true, true],
    [false, false, true],
  ])
  let chain_blueprint = match finite_topology_open_blueprint(chain) {
    Some(value) => value
    None => return false
  }
  guard chain_blueprint.n == 4 && finite_blueprint_report(chain_blueprint).valid else {
    return false
  }
  let split_f2 = @ffinite.FinAlg::univariate_quotient(2, [0, 1, 1])
  let ideal_blueprint = match finite_ideal_lattice_blueprint(split_f2) {
    Some(value) => value
    None => return false
  }
  guard ideal_blueprint.n == 4 && finite_blueprint_report(ideal_blueprint).valid else {
    return false
  }
  let split_alg = @ffinite.FinAlg::univariate_quotient(5, [3, 4, 1])
  let spectrum_top = finalg_spec_to_catmath_fintop(@fscheme.spec(split_alg))
  let spectrum_blueprint = match finite_topology_open_blueprint(spectrum_top) {
    Some(value) => value
    None => return false
  }
  finite_blueprint_report(spectrum_blueprint).valid
}

///|
pub fn check_theory_mode_unification_bridge() -> Bool {
  check_finite_theory_morphisms() &&
  check_finite_group_federation(@catmath.cyclic_group(4), 16)
}

///|
/// All five GU construction families, counted once each.  The
/// certificate-envelope check is deliberately separate: envelopes
/// recompute `bridge_certificates`, so including them here would
/// make this aggregate recursive.
pub fn check_federation_grand_unification_construction() -> Bool {
  check_valued_initial_unification_bridge() &&
  check_relation_quantale_unification_bridge() &&
  check_presheaf_sieve_unification_bridge() &&
  check_blueprint_unification_bridge() &&
  check_theory_mode_unification_bridge()
}
