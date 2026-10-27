///|
/// Polynomial and integer-matrix commuting diagrams for the direct
/// 3+2 federation.
///
/// The central distinction is between *reduction* and *lifting*.
/// Coefficientwise reduction `Z[x] -> F_p[x]` is a ring homomorphism
/// and therefore commutes with multiplication, formal derivative
/// and evaluation at integral points.  The representative lift
/// `F_p[x] -> Q[x]` used elsewhere in this package is only a
/// section on coefficients; this file never treats it as a ring
/// map.  Within that boundary, finalg supplies finite-field
/// polynomial and quotient-algebra algorithms, catmath supplies an
/// independent dense multiplication engine, exact algebra supplies
/// the rational and integral source algorithms, and semiring/trop
/// supplies the p-adic tropicalization.

///|
fn federation_trim_dense(coeffs : Array[Int32]) -> Array[Int32] {
  let mut last = coeffs.length() - 1
  while last > 0 && coeffs[last] == 0 {
    last = last - 1
  }
  if coeffs.length() == 0 {
    return [0]
  }
  let out : Array[Int32] = []
  for i in 0..<=last {
    out.push(coeffs[i])
  }
  out
}

///|
fn federation_dense_degree(coeffs : Array[Int32]) -> Int32 {
  let trimmed = federation_trim_dense(coeffs)
  if trimmed.length() == 1 && trimmed[0] == 0 {
    -1
  } else {
    trimmed.length() - 1
  }
}

///|
fn federation_unique_sorted(xs : Array[Int32]) -> Array[Int32] {
  let sorted = federation_sorted_copy(xs)
  let out : Array[Int32] = []
  for x in sorted {
    if out.length() == 0 || out[out.length() - 1] != x {
      out.push(x)
    }
  }
  out
}

///|
fn federation_tropical_root_pairs(
  poly : @strop.UniPoly,
) -> Array[(Int64, Int64)] {
  let roots = @strop.sort_rats(poly.roots())
  let out : Array[(Int64, Int64)] = []
  for root in roots {
    out.push((root.n, root.d))
  }
  out
}

///|
fn federation_tropical_pairs_equal(
  a : Array[(Int64, Int64)],
  b : Array[(Int64, Int64)],
) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard a[i].0 == b[i].0 && a[i].1 == b[i].1 else { return false }
  }
  true
}

///|
/// Cross-member report for reducing two integral rational
/// polynomials modulo a prime.
pub(all) struct PolynomialReductionFederationReport {
  valid : Bool
  prime : Int32
  exact_degree_f : Int32
  exact_degree_g : Int32
  exact_degree_product : Int32
  reduced_degree_f : Int32
  reduced_degree_g : Int32
  reduced_degree_product : Int32
  reduced_f_coeffs : Array[Int32]
  reduced_g_coeffs : Array[Int32]
  reduced_product_coeffs : Array[Int32]
  finite_roots_f : Array[Int32]
  multiple_finite_roots_f : Array[Int32]
  /// Images in `F_p` of those rational roots whose denominators
  /// are invertible modulo `p`.
  rational_root_images_f : Array[Int32]
  /// `(a, a')` with `a'` a root modulo `p^2` reducing to the
  /// simple root `a` modulo `p`, when the small-prime fragment is
  /// supported.
  hensel_lifts_f : Array[(Int32, Int32)]
  quotient_dimension : Int32
  quotient_is_field : Bool
  quotient_is_reduced : Bool
  quotient_is_semisimple : Bool
  multiplication_ok : Bool
  derivative_ok : Bool
  evaluation_ok : Bool
  catmath_multiplication_ok : Bool
  rational_root_images_ok : Bool
  hensel_supported : Bool
  hensel_ok : Bool
  ideal_supported : Bool
  ideal_membership_ok : Bool
  companion_supported : Bool
  companion_ok : Bool
  tropical_supported : Bool
  tropical_ok : Bool
}

///|
fn invalid_polynomial_reduction_report(
  p : Int32,
  f : @exactalg.QPoly,
  g : @exactalg.QPoly,
) -> PolynomialReductionFederationReport {
  {
    valid: false,
    prime: p,
    exact_degree_f: @exactalg.qpoly_degree(f),
    exact_degree_g: @exactalg.qpoly_degree(g),
    exact_degree_product: @exactalg.qpoly_degree(@exactalg.qpoly_mul(f, g)),
    reduced_degree_f: -1,
    reduced_degree_g: -1,
    reduced_degree_product: -1,
    reduced_f_coeffs: [0],
    reduced_g_coeffs: [0],
    reduced_product_coeffs: [0],
    finite_roots_f: [],
    multiple_finite_roots_f: [],
    rational_root_images_f: [],
    hensel_lifts_f: [],
    quotient_dimension: 0,
    quotient_is_field: false,
    quotient_is_reduced: false,
    quotient_is_semisimple: false,
    multiplication_ok: false,
    derivative_ok: false,
    evaluation_ok: false,
    catmath_multiplication_ok: false,
    rational_root_images_ok: false,
    hensel_supported: false,
    hensel_ok: false,
    ideal_supported: false,
    ideal_membership_ok: false,
    companion_supported: false,
    companion_ok: false,
    tropical_supported: false,
    tropical_ok: false,
  }
}

///|
/// Build the polynomial-reduction report for integral `f`, `g`.
///
/// The finite-root scan is exhaustive over `F_p`, so this report is
/// intended for explicitly chosen small primes.  The companion/
/// quotient fragment additionally requires `f` to be monic of
/// positive degree and `p > deg(f)`, because finalg's
/// characteristic-polynomial algorithm interpolates at `deg+1`
/// field points.  Field/reduced/semisimple values are native
/// finalg quotient-algebra outputs; in particular, absence of a
/// repeated *linear* root is not by itself used as a separability
/// claim.
pub fn polynomial_reduction_federation_report(
  f : @exactalg.QPoly,
  g : @exactalg.QPoly,
  p : Int32,
  sample_points : Array[Int32],
) -> PolynomialReductionFederationReport {
  guard @fnum.is_prime(p) else {
    return invalid_polynomial_reduction_report(p, f, g)
  }
  let product = @exactalg.qpoly_mul(f, g)
  let reduced_f = match qpoly_to_finalg_univariate(f, p) {
    Some(poly) => poly
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let reduced_g = match qpoly_to_finalg_univariate(g, p) {
    Some(poly) => poly
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let reduced_product = match qpoly_to_finalg_univariate(product, p) {
    Some(poly) => poly
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let reduced_f_coeffs = match finalg_univariate_dense_coeffs(reduced_f) {
    Some(coeffs) => federation_trim_dense(coeffs)
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let reduced_g_coeffs = match finalg_univariate_dense_coeffs(reduced_g) {
    Some(coeffs) => federation_trim_dense(coeffs)
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let reduced_product_coeffs = match
    finalg_univariate_dense_coeffs(reduced_product) {
    Some(coeffs) => federation_trim_dense(coeffs)
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let multiplication_ok = reduced_product.equal(reduced_f.mul(reduced_g))
  let reduced_derivative = match
    qpoly_to_finalg_univariate(@exactalg.qpoly_derivative(f), p) {
    Some(poly) => poly
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let derivative_ok = reduced_derivative.equal(reduced_f.derivative(0))
  let reduced_derivative_coeffs = match
    finalg_univariate_dense_coeffs(reduced_derivative) {
    Some(coeffs) => federation_trim_dense(coeffs)
    None => return invalid_polynomial_reduction_report(p, f, g)
  }
  let mut evaluation_ok = true
  for x in sample_points {
    let exact_value = @exactalg.qpoly_eval(f, @exactalg.rat_int(x))
    let finite_value = @finalg.up_eval(p, reduced_f_coeffs, @fnum.mod_pos(x, p))
    if exact_value.den != 1N ||
      bigint_mod_pos(exact_value.num, p) != finite_value {
      evaluation_ok = false
    }
  }
  let (catmath_product, _) = @catmath.poly_mul_naive_steps(
    reduced_f_coeffs, reduced_g_coeffs, p,
  )
  let catmath_multiplication_ok = int_arrays_equal(
    federation_trim_dense(catmath_product),
    reduced_product_coeffs,
  )
  let finite_roots : Array[Int32] = []
  let multiple_roots : Array[Int32] = []
  // The zero polynomial vanishes at every field point, but calling
  // all p points its roots is still the literal finite-field set;
  // users who need the scheme-theoretic statement should inspect
  // reduced_degree_f == -1 as the degenerate case.
  for a in 0..<p {
    if @finalg.up_eval(p, reduced_f_coeffs, a) == 0 {
      finite_roots.push(a)
      if @finalg.up_eval(p, reduced_derivative_coeffs, a) == 0 {
        multiple_roots.push(a)
      }
    }
  }
  let rational_images : Array[Int32] = []
  for root in @exactalg.qpoly_rational_roots(f) {
    let den_mod = bigint_mod_pos(root.den, p)
    if den_mod != 0 {
      match @fnum.invmod(den_mod, p) {
        Some(inv) =>
          rational_images.push(
            @fnum.mul_mod(bigint_mod_pos(root.num, p), inv, p),
          )
        None => ()
      }
    }
  }
  let rational_root_images = federation_unique_sorted(rational_images)
  let mut rational_root_images_ok = true
  for image in rational_root_images {
    if @finalg.up_eval(p, reduced_f_coeffs, image) != 0 {
      rational_root_images_ok = false
    }
  }
  let hensel_supported = p <= 30000
  let hensel_lifts : Array[(Int32, Int32)] = []
  let mut hensel_ok = hensel_supported
  if hensel_supported {
    for a in finite_roots {
      let derivative_value = @finalg.up_eval(p, reduced_derivative_coeffs, a)
      if derivative_value != 0 {
        let exact_value = @exactalg.qpoly_eval(f, @exactalg.rat_int(a))
        match @fnum.invmod(derivative_value, p) {
          Some(inv_derivative) =>
            if exact_value.den != 1N ||
              exact_value.num % BigInt::from_int(p) != 0N {
              hensel_ok = false
            } else {
              let scaled = bigint_mod_pos(
                exact_value.num / BigInt::from_int(p),
                p,
              )
              let step = @fnum.mul_mod(scaled, inv_derivative, p)
              let correction = if step == 0 { 0 } else { p - step }
              let lift = a + correction * p
              let lifted_value = @exactalg.qpoly_eval(
                f,
                @exactalg.rat_int(lift),
              )
              hensel_lifts.push((a, lift))
              if lifted_value.den != 1N ||
                bigint_mod_pos(lifted_value.num, p * p) != 0 {
                hensel_ok = false
              }
            }
          None => hensel_ok = false
        }
      }
    }
  }
  let ideal_supported = !reduced_g.is_zero()
  let ideal_membership_ok = if ideal_supported {
    @finalg.ideal_membership(reduced_product, [reduced_g]) &&
    reduced_product.normal_form([reduced_g]).is_zero()
  } else {
    false
  }
  let f_degree = @exactalg.qpoly_degree(f)
  let f_monic = f_degree >= 1 &&
    @exactalg.rat_eq(@exactalg.qpoly_leading(f), @exactalg.rat_int(1))
  let companion_supported = f_monic &&
    p > f_degree &&
    federation_dense_degree(reduced_f_coeffs) == f_degree
  let mut companion_ok = false
  let mut quotient_dimension = 0
  let mut quotient_is_field = false
  let mut quotient_is_reduced = false
  let mut quotient_is_semisimple = false
  if companion_supported {
    let companion = @finalg.companion_matrix(p, reduced_f_coeffs)
    let companion_matrix = @flinalg.Matrix::from_rows(p, companion)
    let charpoly = federation_trim_dense(@finalg.mat_charpoly(companion_matrix))
    let quotient = @ffinite.FinAlg::univariate_quotient(p, reduced_f_coeffs)
    quotient_dimension = quotient.dim
    quotient_is_field = @ffinite.is_field_alg(quotient)
    quotient_is_reduced = @ffinite.is_reduced(quotient)
    quotient_is_semisimple = @ffinite.is_semisimple_ring(quotient)
    companion_ok = int_arrays_equal(charpoly, reduced_f_coeffs) &&
      quotient_dimension == f_degree &&
      quotient.validate() &&
      (!quotient_is_field || (quotient_is_reduced && quotient_is_semisimple))
  }
  let tropical_supported = !@exactalg.qpoly_is_zero(f) &&
    !@exactalg.qpoly_is_zero(g)
  let mut tropical_ok = false
  if tropical_supported {
    let trop_f = qpoly_tropicalize_padic(f, p)
    let trop_g = qpoly_tropicalize_padic(g, p)
    let trop_product = qpoly_tropicalize_padic(product, p)
    let trop_mul = @strop.trop_poly_mul(trop_f, trop_g)
    let merged_raw = trop_f.roots()
    for root in trop_g.roots() {
      merged_raw.push(root)
    }
    let merged_sorted = @strop.sort_rats(merged_raw)
    let merged_pairs : Array[(Int64, Int64)] = []
    for root in merged_sorted {
      merged_pairs.push((root.n, root.d))
    }
    let product_pairs = federation_tropical_root_pairs(trop_product)
    tropical_ok = federation_tropical_pairs_equal(product_pairs, merged_pairs) &&
      federation_tropical_pairs_equal(
        product_pairs,
        federation_tropical_root_pairs(trop_mul),
      )
  }
  let valid = multiplication_ok &&
    derivative_ok &&
    evaluation_ok &&
    catmath_multiplication_ok &&
    rational_root_images_ok &&
    (!hensel_supported || hensel_ok) &&
    (!ideal_supported || ideal_membership_ok) &&
    (!companion_supported || companion_ok) &&
    (!tropical_supported || tropical_ok)
  {
    valid,
    prime: p,
    exact_degree_f: f_degree,
    exact_degree_g: @exactalg.qpoly_degree(g),
    exact_degree_product: @exactalg.qpoly_degree(product),
    reduced_degree_f: federation_dense_degree(reduced_f_coeffs),
    reduced_degree_g: federation_dense_degree(reduced_g_coeffs),
    reduced_degree_product: federation_dense_degree(reduced_product_coeffs),
    reduced_f_coeffs,
    reduced_g_coeffs,
    reduced_product_coeffs,
    finite_roots_f: finite_roots,
    multiple_finite_roots_f: multiple_roots,
    rational_root_images_f: rational_root_images,
    hensel_lifts_f: hensel_lifts,
    quotient_dimension,
    quotient_is_field,
    quotient_is_reduced,
    quotient_is_semisimple,
    multiplication_ok,
    derivative_ok,
    evaluation_ok,
    catmath_multiplication_ok,
    rational_root_images_ok,
    hensel_supported,
    hensel_ok,
    ideal_supported,
    ideal_membership_ok,
    companion_supported,
    companion_ok,
    tropical_supported,
    tropical_ok,
  }
}

///|
/// Whether every applicable polynomial-reduction diagram commutes.
pub fn check_polynomial_reduction_federation(
  f : @exactalg.QPoly,
  g : @exactalg.QPoly,
  p : Int32,
  sample_points : Array[Int32],
) -> Bool {
  polynomial_reduction_federation_report(f, g, p, sample_points).valid
}

///|
fn federation_finite_matrices_equal(
  a : @flinalg.Matrix,
  b : @flinalg.Matrix,
) -> Bool {
  guard a.p == b.p && a.rows == b.rows && a.cols == b.cols else { return false }
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      guard a.get(i, j) == b.get(i, j) else { return false }
    }
  }
  true
}

///|
/// Cross-member report for one integer matrix.  In addition to the
/// first-wave SNF comparison, this relates exact rational rank,
/// determinant and (minimal/characteristic) polynomials to the two
/// finite-field rank engines and, when the cokernel is finite and
/// below the caller's group-order cap, to the finite abelian group
/// explicitly assembled from the Smith factors.
pub(all) struct IntegerMatrixFederationReport {
  valid : Bool
  rows : Int32
  cols : Int32
  prime : Int32
  exact_rank : Int32
  finalg_snf_rank : Int32
  catmath_snf_rank : Int32
  finalg_finite_rank : Int32
  catmath_finite_rank : Int32
  invariant_factors : Array[Int32]
  determinant : @exactalg.Rat
  trace : @exactalg.Rat
  charpoly : @exactalg.QPoly
  minimal_polynomial : @exactalg.QPoly
  finite_cokernel_supported : Bool
  finite_cokernel_order : Int32
  snf_ok : Bool
  rank_ok : Bool
  determinant_ok : Bool
  charpoly_supported : Bool
  charpoly_ok : Bool
  finite_cokernel_ok : Bool
}

///|
fn invalid_integer_matrix_federation_report(
  rows : Array[Array[Int32]],
  p : Int32,
) -> IntegerMatrixFederationReport {
  let (nrows, ncols) = match int_matrix_shape(rows) {
    Some(shape) => shape
    None => (rows.length(), 0)
  }
  {
    valid: false,
    rows: nrows,
    cols: ncols,
    prime: p,
    exact_rank: 0,
    finalg_snf_rank: 0,
    catmath_snf_rank: 0,
    finalg_finite_rank: 0,
    catmath_finite_rank: 0,
    invariant_factors: [],
    determinant: @exactalg.rat_zero(),
    trace: @exactalg.rat_zero(),
    charpoly: @exactalg.qpoly_zero(),
    minimal_polynomial: @exactalg.qpoly_zero(),
    finite_cokernel_supported: false,
    finite_cokernel_order: 0,
    snf_ok: false,
    rank_ok: false,
    determinant_ok: false,
    charpoly_supported: false,
    charpoly_ok: false,
    finite_cokernel_ok: false,
  }
}

///|
/// Build the integer-matrix report.  The matrix is read as a map
/// `Z^cols -> Z^rows`; its cokernel is finite exactly when the
/// exact rank equals `rows`.  `group_cap` bounds the order of the
/// explicit finite abelian group built in that case.
pub fn integer_matrix_federation_report(
  rows : Array[Array[Int32]],
  p : Int32,
  group_cap : Int32,
) -> IntegerMatrixFederationReport {
  let (nrows, ncols) = match int_matrix_shape(rows) {
    Some(shape) => shape
    None => return invalid_integer_matrix_federation_report(rows, p)
  }
  guard @fnum.is_prime(p) && group_cap > 0 else {
    return invalid_integer_matrix_federation_report(rows, p)
  }
  let normal = match integer_matrix_normal_form_report(rows) {
    Some(report) => report
    None => return invalid_integer_matrix_federation_report(rows, p)
  }
  let exact_matrix = @exactalg.qmat_from_int_rows(rows)
  let exact_rank = @exactalg.qmat_rank(exact_matrix)
  let mut finalg_snf_rank = 0
  for entry in normal.finalg_snf_diag {
    if entry != 0 {
      finalg_snf_rank = finalg_snf_rank + 1
    }
  }
  let catmath_matrix = @catmath.int_mat_of(nrows, ncols, copy_int_matrix(rows))
  let catmath_snf_rank = @catmath.snf_rank(catmath_matrix)
  let finalg_finite_rank = @flinalg.Matrix::from_rows(p, rows).rank()
  let catmath_finite_rank = @catmath.rank_f_p(copy_int_matrix(rows), p)
  let rank_ok = exact_rank == finalg_snf_rank &&
    exact_rank == catmath_snf_rank &&
    finalg_finite_rank == catmath_finite_rank &&
    finalg_finite_rank <= exact_rank
  let square = nrows == ncols
  let determinant = if square {
    @exactalg.qmat_det(exact_matrix)
  } else {
    @exactalg.rat_zero()
  }
  let trace = if square {
    @exactalg.qmat_trace(exact_matrix)
  } else {
    @exactalg.rat_zero()
  }
  let charpoly = if square {
    @exactalg.qmat_charpoly(exact_matrix)
  } else {
    @exactalg.qpoly_zero()
  }
  let minimal_polynomial = if square {
    @exactalg.qmat_minimal_polynomial(exact_matrix)
  } else {
    @exactalg.qpoly_zero()
  }
  let mut determinant_ok = !square
  if square {
    if exact_rank < nrows {
      determinant_ok = @exactalg.rat_is_zero(determinant)
    } else {
      let mut product = 1N
      for factor in normal.catmath_snf_factors {
        product = product * BigInt::from_int(factor)
      }
      determinant_ok = determinant.den == 1N &&
        @exactalg.bigint_abs(determinant.num) == product
    }
  }
  let charpoly_supported = square && p > nrows
  let mut charpoly_ok = false
  if square {
    let exact_cayley_hamilton = @exactalg.qmat_is_zero(
      @exactalg.qmat_poly_eval(charpoly, exact_matrix),
    )
    let minimal_divides = @exactalg.qpoly_is_zero(
      @exactalg.qpoly_mod(charpoly, minimal_polynomial),
    )
    let finite_ok = if charpoly_supported {
      let finite_matrix = @flinalg.Matrix::from_rows(p, rows)
      let finite_charpoly = @finalg.mat_charpoly(finite_matrix)
      integer_matrix_charpoly_cross_check_mod(rows, p) &&
      federation_finite_matrices_equal(
        @finalg.mat_poly_eval(finite_charpoly, finite_matrix),
        @flinalg.Matrix::zero(p, nrows, ncols),
      )
    } else {
      true
    }
    charpoly_ok = exact_cayley_hamilton && minimal_divides && finite_ok
  }
  let mut cokernel_order_big = 1N
  for factor in normal.catmath_snf_factors {
    cokernel_order_big = cokernel_order_big * BigInt::from_int(factor)
  }
  let finite_cokernel_supported = exact_rank == nrows &&
    cokernel_order_big >= 1N &&
    cokernel_order_big <= BigInt::from_int(group_cap)
  let mut finite_cokernel_order = 0
  let mut finite_cokernel_ok = false
  if finite_cokernel_supported {
    finite_cokernel_order = cokernel_order_big.to_int()
    // Z^rows / A Z^cols ≅ ⊕ Z/d_i.  Factors equal to 1 contribute
    // the trivial group and may be kept or omitted.
    let mut group = @catmath.cyclic_group(1)
    for factor in normal.catmath_snf_factors {
      group = @catmath.direct_product(group, @catmath.cyclic_group(factor))
    }
    let expected_invariants : Array[Int32] = []
    for factor in normal.catmath_snf_factors {
      if factor > 1 {
        expected_invariants.push(factor)
      }
    }
    finite_cokernel_ok = group.order == finite_cokernel_order &&
      check_finite_group_federation(group, group_cap) &&
      int_arrays_equal(
        @catmath.abelian_invariant_factors(group),
        expected_invariants,
      )
  }
  let valid = normal.snf_agrees &&
    normal.hnf_idempotent &&
    rank_ok &&
    determinant_ok &&
    (!square || charpoly_ok) &&
    (!finite_cokernel_supported || finite_cokernel_ok)
  {
    valid,
    rows: nrows,
    cols: ncols,
    prime: p,
    exact_rank,
    finalg_snf_rank,
    catmath_snf_rank,
    finalg_finite_rank,
    catmath_finite_rank,
    invariant_factors: normal.catmath_snf_factors,
    determinant,
    trace,
    charpoly,
    minimal_polynomial,
    finite_cokernel_supported,
    finite_cokernel_order,
    snf_ok: normal.snf_agrees && normal.hnf_idempotent,
    rank_ok,
    determinant_ok,
    charpoly_supported,
    charpoly_ok,
    finite_cokernel_ok,
  }
}

///|
/// Whether every applicable integer-matrix diagram commutes.
pub fn check_integer_matrix_federation(
  rows : Array[Array[Int32]],
  p : Int32,
  group_cap : Int32,
) -> Bool {
  integer_matrix_federation_report(rows, p, group_cap).valid
}
