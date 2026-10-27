///|
/// Valued multivariate initial forms over `Q` with a `p`-adic
/// valuation.
///
/// For an exact multivariate polynomial
/// `f = Σ c_α x^α` and an integer weight vector `w`, the valued
/// weight of a term is `v_p(c_α) + α·w`.  The initial form is the
/// sum of the terms attaining the minimum.  This file computes:
///
/// - the exact initial form over `Q`;
/// - its residue form over `F_p`, by removing the `p`-part of each
///   selected coefficient and reducing the remaining unit;
/// - whether the initial form is a monomial.
///
/// For one polynomial this monomial test is exact: `w` lies in
/// the tropical hypersurface exactly when the initial form is not
/// a monomial (with the zero polynomial vacuous).  For a list of
/// generators, if one generator has monomial initial form then
/// the initial ideal contains that monomial, so `w` is certainly
/// excluded.  If no displayed generator excludes `w`, this file
/// calls the point only a *candidate*: another element of the
/// ideal could still exclude it.  That distinction is the honest
/// finite core.  It is not a general Chan–Maclagan valued
/// Gröbner-basis implementation and does not rename finalg's
/// finite-field lex basis as one.
///
/// Differential oracles are included where the federation already
/// has native machinery:
///
/// - in one variable, semiring's p-adic tropical root/corner
///   report;
/// - in two variables, semiring's `BPoly` argmin and, when the
///   Newton polygon has positive area, its regular subdivision,
///   balancing, tie and area checks.

///|
priv struct ValuedInitialData {
  exponents : Array[Array[Int32]]
  valuations : Array[Int32]
  residues : Array[Int32]
  term_weights : Array[Int64]
  minimum_weight : Int64
  initial_indices : Array[Int32]
}

///|
fn valued_unit_residue(coeff : @exactalg.Rat, prime : Int32) -> Int32? {
  guard @fnum.is_prime(prime) && !@exactalg.rat_is_zero(coeff) else {
    return None
  }
  guard coeff.den > 0N else { return None }
  let bp = BigInt::from_int(prime)
  let mut numerator = coeff.num
  while numerator % bp == 0N {
    numerator = numerator / bp
  }
  let mut denominator = coeff.den
  while denominator % bp == 0N {
    denominator = denominator / bp
  }
  let numerator_mod = bigint_mod_pos(numerator, prime)
  let denominator_mod = bigint_mod_pos(denominator, prime)
  let inverse = match @fnum.invmod(denominator_mod, prime) {
    Some(value) => value
    None => return None
  }
  Some(@fnum.mul_mod(numerator_mod, inverse, prime))
}

///|
fn valued_initial_data(
  poly : @exactalg.Poly,
  prime : Int32,
  weight : Array[Int32],
) -> ValuedInitialData? {
  guard @fnum.is_prime(prime) &&
    weight.length() >= 1 &&
    weight.length() <= 8 &&
    tropical_point_shape_ok(weight) &&
    poly.terms.length() <= 64 else {
    return None
  }
  let exponents : Array[Array[Int32]] = []
  let valuations : Array[Int32] = []
  let residues : Array[Int32] = []
  let term_weights : Array[Int64] = []
  let mut minimum_weight = 0L
  let mut first = true
  for term in poly.terms {
    guard !@exactalg.rat_is_zero(term.coeff) &&
      term.coeff.den > 0N &&
      term.exps.length() <= weight.length() else {
      return None
    }
    let padded = Array::make(weight.length(), 0)
    for i in 0..<term.exps.length() {
      guard term.exps[i] >= 0 && term.exps[i] <= 128 else { return None }
      padded[i] = term.exps[i]
    }
    let valuation = match rat_padic_valuation(term.coeff, prime) {
      Some(value) => value
      None => return None
    }
    let residue = match valued_unit_residue(term.coeff, prime) {
      Some(value) => value
      None => return None
    }
    let mut term_weight = valuation.to_int64()
    for i in 0..<weight.length() {
      term_weight = term_weight + padded[i].to_int64() * weight[i].to_int64()
    }
    if first || term_weight < minimum_weight {
      minimum_weight = term_weight
      first = false
    }
    exponents.push(padded)
    valuations.push(valuation)
    residues.push(residue)
    term_weights.push(term_weight)
  }
  let initial_indices : Array[Int32] = []
  for i in 0..<term_weights.length() {
    if term_weights[i] == minimum_weight {
      initial_indices.push(i)
    }
  }
  Some({
    exponents,
    valuations,
    residues,
    term_weights,
    minimum_weight,
    initial_indices,
  })
}

///|
fn valued_exact_initial_from_data(
  poly : @exactalg.Poly,
  data : ValuedInitialData,
) -> @exactalg.Poly {
  let mut out = @exactalg.poly_zero()
  for index in data.initial_indices {
    let term = poly.terms[index]
    let mut monomial = @exactalg.poly_const(term.coeff)
    for variable in 0..<data.exponents[index].length() {
      for _power in 0..<data.exponents[index][variable] {
        monomial = @exactalg.poly_mul(monomial, @exactalg.poly_var(variable))
      }
    }
    out = @exactalg.poly_add(out, monomial)
  }
  out
}

///|
fn valued_residue_initial_from_data(
  prime : Int32,
  nvars : Int32,
  data : ValuedInitialData,
) -> @finalg.Poly {
  let raw : Array[(Int32, Array[Int32])] = []
  for index in data.initial_indices {
    raw.push((data.residues[index], data.exponents[index].copy()))
  }
  @finalg.poly_of_terms(nvars, prime, raw)
}

///|
/// The exact `p`-adic valued initial form over `Q`.
pub fn valued_initial_form(
  poly : @exactalg.Poly,
  prime : Int32,
  weight : Array[Int32],
) -> @exactalg.Poly? {
  let data = match valued_initial_data(poly, prime, weight) {
    Some(value) => value
    None => return None
  }
  Some(valued_exact_initial_from_data(poly, data))
}

///|
/// The residue initial form over `F_p`: selected terms keep their
/// exponents and their coefficient unit parts are reduced mod `p`.
pub fn valued_initial_residue_form(
  poly : @exactalg.Poly,
  prime : Int32,
  weight : Array[Int32],
) -> @finalg.Poly? {
  let data = match valued_initial_data(poly, prime, weight) {
    Some(value) => value
    None => return None
  }
  Some(valued_residue_initial_from_data(prime, weight.length(), data))
}

///|
fn valued_padded_exponents(
  poly : @exactalg.Poly,
  nvars : Int32,
) -> Array[Array[Int32]]? {
  let out : Array[Array[Int32]] = []
  for term in poly.terms {
    guard term.exps.length() <= nvars else { return None }
    let padded = Array::make(nvars, 0)
    for i in 0..<term.exps.length() {
      padded[i] = term.exps[i]
    }
    out.push(padded)
  }
  Some(out)
}

///|
fn valued_exact_poly_to_qpoly(poly : @exactalg.Poly) -> @exactalg.QPoly? {
  let mut degree = -1
  for term in poly.terms {
    guard term.exps.length() <= 1 else { return None }
    let exponent = if term.exps.length() == 0 { 0 } else { term.exps[0] }
    guard exponent >= 0 && exponent <= 128 else { return None }
    if exponent > degree {
      degree = exponent
    }
  }
  if degree < 0 {
    return Some(@exactalg.qpoly_zero())
  }
  let coeffs = Array::make(degree + 1, @exactalg.rat_zero())
  let seen = Array::make(degree + 1, false)
  for term in poly.terms {
    let exponent = if term.exps.length() == 0 { 0 } else { term.exps[0] }
    guard !seen[exponent] else { return None }
    seen[exponent] = true
    coeffs[exponent] = term.coeff
  }
  Some(@exactalg.qpoly_normalize(coeffs))
}

///|
pub(all) struct ValuedInitialFormReport {
  valid : Bool
  supported : Bool
  prime : Int32
  nvars : Int32
  weight : Array[Int32]
  term_count : Int32
  term_weights : Array[Int64]
  minimum_weight : Int64
  initial_indices : Array[Int32]
  initial_exponents : Array[Array[Int32]]
  initial_residues : Array[Int32]
  initial_term_count : Int32
  is_zero : Bool
  is_monomial : Bool
  initial_form : @exactalg.Poly
  residue_form : @finalg.Poly
  exact_initial_support_ok : Bool
  residue_initial_support_ok : Bool
  univariate_supported : Bool
  univariate_corner_ok : Bool
  bivariate_supported : Bool
  bivariate_argmin_ok : Bool
  bivariate_newton_supported : Bool
  bivariate_duality_ok : Bool
  bivariate_balancing_ok : Bool
  bivariate_ties_ok : Bool
  bivariate_area_ok : Bool
}

///|
fn invalid_valued_initial_report(
  prime : Int32,
  weight : Array[Int32],
) -> ValuedInitialFormReport {
  {
    valid: false,
    supported: false,
    prime,
    nvars: weight.length(),
    weight: weight.copy(),
    term_count: 0,
    term_weights: [],
    minimum_weight: 0L,
    initial_indices: [],
    initial_exponents: [],
    initial_residues: [],
    initial_term_count: 0,
    is_zero: false,
    is_monomial: false,
    initial_form: @exactalg.poly_zero(),
    residue_form: @finalg.poly_of_terms(weight.length(), 2, []),
    exact_initial_support_ok: false,
    residue_initial_support_ok: false,
    univariate_supported: false,
    univariate_corner_ok: false,
    bivariate_supported: false,
    bivariate_argmin_ok: false,
    bivariate_newton_supported: false,
    bivariate_duality_ok: false,
    bivariate_balancing_ok: false,
    bivariate_ties_ok: false,
    bivariate_area_ok: false,
  }
}

///|
fn valued_initial_form_report_impl(
  poly : @exactalg.Poly,
  prime : Int32,
  weight : Array[Int32],
  include_newton : Bool,
) -> ValuedInitialFormReport {
  let data = match valued_initial_data(poly, prime, weight) {
    Some(value) => value
    None => return invalid_valued_initial_report(prime, weight)
  }
  let nvars = weight.length()
  let initial_form = valued_exact_initial_from_data(poly, data)
  let residue_form = valued_residue_initial_from_data(prime, nvars, data)
  let initial_exponents : Array[Array[Int32]] = []
  let initial_residues : Array[Int32] = []
  for index in data.initial_indices {
    initial_exponents.push(data.exponents[index].copy())
    initial_residues.push(data.residues[index])
  }
  let exact_initial_support_ok = match
    valued_padded_exponents(initial_form, nvars) {
    Some(actual) =>
      actual.length() == initial_exponents.length() &&
      tropical_points_subset(actual, initial_exponents) &&
      tropical_points_subset(initial_exponents, actual)
    None => false
  }
  let mut residue_initial_support_ok = tropical_finalg_poly_shape_ok(
      residue_form,
    ) &&
    residue_form.nvars == nvars &&
    residue_form.modulus == prime &&
    residue_form.terms.length() == data.initial_indices.length()
  if residue_initial_support_ok {
    for position in 0..<data.initial_indices.length() {
      let expected_exponents = initial_exponents[position]
      let expected_residue = initial_residues[position]
      let mut found = false
      for term in residue_form.terms {
        if int_arrays_equal(term.exp, expected_exponents) &&
          term.coeff.val == expected_residue {
          found = true
        }
      }
      if !found {
        residue_initial_support_ok = false
      }
    }
  }
  let is_zero = poly.terms.length() == 0
  let is_monomial = data.initial_indices.length() == 1
  let univariate_supported = nvars == 1
  let mut univariate_corner_ok = false
  if univariate_supported {
    match valued_exact_poly_to_qpoly(poly) {
      Some(qpoly) => {
        let w = weight[0]
        let oracle = padic_tropical_hypersurface_report(qpoly, prime, w, w)
        let contains = oracle.integer_corner_points.length() == 1 &&
          oracle.integer_corner_points[0] == w
        let empty = oracle.integer_corner_points.length() == 0
        univariate_corner_ok = oracle.valid &&
          ((contains && !is_monomial) || (empty && is_monomial))
      }
      None => univariate_corner_ok = false
    }
  }
  let bivariate_supported = nvars == 2
  let mut bivariate_argmin_ok = false
  let mut bivariate_newton_supported = false
  let mut bivariate_duality_ok = false
  let mut bivariate_balancing_ok = false
  let mut bivariate_ties_ok = false
  let mut bivariate_area_ok = false
  if bivariate_supported {
    let terms : Array[@strop.BTerm] = []
    for i in 0..<data.exponents.length() {
      terms.push(
        @strop.BTerm::new(
          data.valuations[i],
          data.exponents[i][0],
          data.exponents[i][1],
        ),
      )
    }
    let bpoly = @strop.BPoly::new(terms)
    let minima = bpoly.minima_scaled(
      weight[0].to_int64(),
      weight[1].to_int64(),
      1L,
    )
    bivariate_argmin_ok = if is_zero {
      minima.length() == 0
    } else {
      int_arrays_equal(minima, data.initial_indices)
    }
    if include_newton {
      let flags = tropical_bpoly_subdivision_flags(bpoly)
      bivariate_newton_supported = flags.0
      bivariate_duality_ok = flags.1
      bivariate_balancing_ok = flags.2
      bivariate_ties_ok = flags.3
      bivariate_area_ok = flags.4
    }
  }
  let valid = exact_initial_support_ok &&
    residue_initial_support_ok &&
    (!univariate_supported || univariate_corner_ok) &&
    (!bivariate_supported || bivariate_argmin_ok) &&
    (
      !bivariate_newton_supported ||
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
    prime,
    nvars,
    weight: weight.copy(),
    term_count: poly.terms.length(),
    term_weights: data.term_weights,
    minimum_weight: data.minimum_weight,
    initial_indices: data.initial_indices,
    initial_exponents,
    initial_residues,
    initial_term_count: data.initial_indices.length(),
    is_zero,
    is_monomial,
    initial_form,
    residue_form,
    exact_initial_support_ok,
    residue_initial_support_ok,
    univariate_supported,
    univariate_corner_ok,
    bivariate_supported,
    bivariate_argmin_ok,
    bivariate_newton_supported,
    bivariate_duality_ok,
    bivariate_balancing_ok,
    bivariate_ties_ok,
    bivariate_area_ok,
  }
}

///|
/// Full report for one valued initial form.
pub fn valued_initial_form_report(
  poly : @exactalg.Poly,
  prime : Int32,
  weight : Array[Int32],
) -> ValuedInitialFormReport {
  valued_initial_form_report_impl(poly, prime, weight, true)
}

///|
pub fn check_valued_initial_form(
  poly : @exactalg.Poly,
  prime : Int32,
  weight : Array[Int32],
) -> Bool {
  valued_initial_form_report(poly, prime, weight).valid
}

///|
pub(all) struct ValuedInitialIdealGridReport {
  valid : Bool
  supported : Bool
  prime : Int32
  nvars : Int32
  lower_bound : Int32
  upper_bound : Int32
  sample_point_count : Int32
  generator_count : Int32
  excluded_weights : Array[Array[Int32]]
  candidate_weights : Array[Array[Int32]]
  principal_exact : Bool
  all_initial_reports_ok : Bool
  partition_ok : Bool
}

///|
fn invalid_valued_initial_grid_report(
  prime : Int32,
  nvars : Int32,
  lo : Int32,
  hi : Int32,
  generator_count : Int32,
) -> ValuedInitialIdealGridReport {
  {
    valid: false,
    supported: false,
    prime,
    nvars,
    lower_bound: lo,
    upper_bound: hi,
    sample_point_count: 0,
    generator_count,
    excluded_weights: [],
    candidate_weights: [],
    principal_exact: generator_count == 1,
    all_initial_reports_ok: false,
    partition_ok: false,
  }
}

///|
/// Classify a bounded integer weight grid for an explicitly
/// presented ideal.
///
/// - `excluded_weights`: some displayed generator has monomial
///   initial form, hence the initial ideal contains a monomial.
/// - `candidate_weights`: no displayed generator excludes the
///   weight.
///
/// For one generator (`principal_exact = true`), candidates are
/// exactly the sampled tropical hypersurface points.  For several
/// generators the candidate set is only an outer approximation;
/// this report does not pretend to decide the full initial ideal.
pub fn valued_initial_ideal_grid_report(
  polys : Array[@exactalg.Poly],
  prime : Int32,
  nvars : Int32,
  lo : Int32,
  hi : Int32,
) -> ValuedInitialIdealGridReport {
  let count = match tropical_grid_count(nvars, lo, hi) {
    Some(value) => value
    None =>
      return invalid_valued_initial_grid_report(
        prime,
        nvars,
        lo,
        hi,
        polys.length(),
      )
  }
  guard polys.length() > 0 && polys.length() <= 16 && @fnum.is_prime(prime) else {
    return invalid_valued_initial_grid_report(
      prime,
      nvars,
      lo,
      hi,
      polys.length(),
    )
  }
  let side = hi - lo + 1
  let excluded_weights : Array[Array[Int32]] = []
  let candidate_weights : Array[Array[Int32]] = []
  let mut all_initial_reports_ok = true
  for index in 0..<count {
    let weight = tropical_grid_point(nvars, lo, side, index)
    let mut excluded = false
    for poly in polys {
      let report = valued_initial_form_report_impl(poly, prime, weight, false)
      if !report.valid {
        all_initial_reports_ok = false
      }
      if report.is_monomial {
        excluded = true
      }
    }
    if excluded {
      excluded_weights.push(weight)
    } else {
      candidate_weights.push(weight)
    }
  }
  let partition_ok = excluded_weights.length() + candidate_weights.length() ==
    count
  let valid = all_initial_reports_ok && partition_ok
  {
    valid,
    supported: true,
    prime,
    nvars,
    lower_bound: lo,
    upper_bound: hi,
    sample_point_count: count,
    generator_count: polys.length(),
    excluded_weights,
    candidate_weights,
    principal_exact: polys.length() == 1,
    all_initial_reports_ok,
    partition_ok,
  }
}

///|
pub fn check_valued_initial_ideal_grid(
  polys : Array[@exactalg.Poly],
  prime : Int32,
  nvars : Int32,
  lo : Int32,
  hi : Int32,
) -> Bool {
  valued_initial_ideal_grid_report(polys, prime, nvars, lo, hi).valid
}
