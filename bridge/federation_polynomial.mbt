///|
/// Polynomial and integer-matrix bridges between:
///
/// * exact algebra's univariate `QPoly` over the rationals;
/// * finalg's multivariate `Poly` over `Z/mZ`, specialized to one
///   variable;
/// * finalg and catmath integer Smith normal forms.

///|
fn bigint_mod_pos(x : BigInt, modulus : Int32) -> Int32 {
  let big_modulus = BigInt::from_int(modulus)
  let mut residue = x % big_modulus
  if residue < 0N {
    residue = residue + big_modulus
  }
  residue.to_int()
}

///|
fn dense_coeffs_to_finalg_poly(
  coeffs : Array[Int32],
  modulus : Int32,
) -> @finalg.Poly {
  let raw : Array[(Int32, Array[Int32])] = []
  for degree in 0..<coeffs.length() {
    if coeffs[degree] != 0 {
      raw.push((coeffs[degree], [degree]))
    }
  }
  @finalg.poly_of_terms(1, modulus, raw)
}

///|
/// Reduce an integral univariate rational polynomial modulo `modulus`
/// and view it as a one-variable finalg polynomial.
///
/// Returns `None` when any coefficient has a non-unit denominator:
/// reduction of an arbitrary rational modulo a composite or a prime
/// dividing a denominator is not the coefficientwise map claimed by
/// the finalg representation.  Coefficients are reduced with BigInt,
/// so large integral numerators are not first truncated to `Int`.
pub fn qpoly_to_finalg_univariate(
  p : @exactalg.QPoly,
  modulus : Int32,
) -> @finalg.Poly? {
  guard modulus >= 2 else { return None }
  let coeffs : Array[Int32] = []
  for coeff in p.coeffs {
    guard coeff.den == 1N else { return None }
    coeffs.push(bigint_mod_pos(coeff.num, modulus))
  }
  Some(dense_coeffs_to_finalg_poly(coeffs, modulus))
}

///|
/// Dense low-to-high coefficients of a one-variable finalg polynomial.
/// Returns `None` for a genuinely multivariate polynomial.
pub fn finalg_univariate_dense_coeffs(p : @finalg.Poly) -> Array[Int32]? {
  guard p.nvars == 1 else { return None }
  let mut degree = -1
  for term in p.terms {
    guard term.exp.length() == 1 else { return None }
    if term.exp[0] > degree {
      degree = term.exp[0]
    }
  }
  if degree < 0 {
    return Some([0])
  }
  let coeffs = Array::make(degree + 1, 0)
  for term in p.terms {
    coeffs[term.exp[0]] = term.coeff.val
  }
  Some(coeffs)
}

///|
/// Lift a one-variable finalg polynomial to `QPoly` by taking the
/// canonical representatives `0 <= c < modulus` as integers.
///
/// This is a section of reduction modulo `modulus` on coefficient
/// representatives, not a ring homomorphism from `F_m[x]` to `Q[x]`.
pub fn finalg_univariate_to_qpoly(p : @finalg.Poly) -> @exactalg.QPoly? {
  let coeffs = match finalg_univariate_dense_coeffs(p) {
    Some(coeffs) => coeffs
    None => return None
  }
  let rationals : Array[@exactalg.Rat] = []
  for coeff in coeffs {
    rationals.push(@exactalg.rat_int(coeff))
  }
  Some(@exactalg.qpoly_normalize(rationals))
}

///|
/// Check that a one-variable finalg polynomial survives the round trip
/// finalg -> QPoly -> finalg modulo its own ambient modulus.
pub fn finalg_univariate_qpoly_roundtrip(p : @finalg.Poly) -> Bool {
  let lifted = match finalg_univariate_to_qpoly(p) {
    Some(lifted) => lifted
    None => return false
  }
  match qpoly_to_finalg_univariate(lifted, p.modulus) {
    Some(back) => back.equal(p)
    None => false
  }
}

///|
fn int_arrays_equal(a : Array[Int32], b : Array[Int32]) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard a[i] == b[i] else { return false }
  }
  true
}

///|
fn int_rows_equal(a : Array[Array[Int32]], b : Array[Array[Int32]]) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard int_arrays_equal(a[i], b[i]) else { return false }
  }
  true
}

///|
fn int_matrix_shape(rows : Array[Array[Int32]]) -> (Int32, Int32)? {
  guard rows.length() > 0 else { return None }
  let cols = rows[0].length()
  guard cols > 0 else { return None }
  for row in rows {
    guard row.length() == cols else { return None }
  }
  Some((rows.length(), cols))
}

///|
fn copy_int_matrix(rows : Array[Array[Int32]]) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  for row in rows {
    out.push(row.copy())
  }
  out
}

///|
/// Agreement report for the two independent integer Smith normal
/// form implementations, plus finalg's Hermite normal form.
pub(all) struct IntegerMatrixNormalFormReport {
  finalg_snf_diag : Array[Int32]
  catmath_snf_factors : Array[Int32]
  snf_agrees : Bool
  finalg_hnf : Array[Array[Int32]]
  hnf_idempotent : Bool
}

///|
/// Compute integer-matrix normal forms in both finalg and catmath and
/// compare their Smith invariant factors.  The inherited small-matrix
/// and 32-bit-entry caveats of both implementations apply.
pub fn integer_matrix_normal_form_report(
  rows : Array[Array[Int32]],
) -> IntegerMatrixNormalFormReport? {
  let (nrows, ncols) = match int_matrix_shape(rows) {
    Some(shape) => shape
    None => return None
  }
  let (diag, _, _) = @finalg.snf_int(copy_int_matrix(rows))
  let finalg_factors : Array[Int32] = []
  for entry in diag {
    if entry > 0 {
      finalg_factors.push(entry)
    }
  }
  let catmath_matrix = @catmath.int_mat_of(nrows, ncols, copy_int_matrix(rows))
  let catmath_factors = @catmath.snf_invariant_factors(catmath_matrix)
  let (hnf, _) = @finalg.hnf_int(copy_int_matrix(rows))
  let (hnf_twice, _) = @finalg.hnf_int(copy_int_matrix(hnf))
  Some({
    finalg_snf_diag: diag,
    catmath_snf_factors: catmath_factors,
    snf_agrees: int_arrays_equal(finalg_factors, catmath_factors),
    finalg_hnf: hnf,
    hnf_idempotent: int_rows_equal(hnf, hnf_twice),
  })
}

///|
/// Whether finalg and catmath agree on all positive Smith invariant
/// factors of an integer matrix.
pub fn integer_snf_cross_check(rows : Array[Array[Int32]]) -> Bool {
  match integer_matrix_normal_form_report(rows) {
    Some(report) => report.snf_agrees
    None => false
  }
}

///|
/// Compare an integer matrix's exact rational characteristic
/// polynomial, reduced modulo a prime `p`, with finalg's finite-field
/// characteristic polynomial.  finalg's interpolation algorithm needs
/// `p > n` for an `n x n` matrix; other inputs return `false`.
pub fn integer_matrix_charpoly_cross_check_mod(
  rows : Array[Array[Int32]],
  p : Int32,
) -> Bool {
  let (nrows, ncols) = match int_matrix_shape(rows) {
    Some(shape) => shape
    None => return false
  }
  guard nrows == ncols else { return false }
  guard p > nrows && @fnum.is_prime(p) else { return false }
  let exact_charpoly = @exactalg.qmat_charpoly(
    @exactalg.qmat_from_int_rows(rows),
  )
  let exact_mod = match qpoly_to_finalg_univariate(exact_charpoly, p) {
    Some(poly) => poly
    None => return false
  }
  let finite_matrix = @flinalg.Matrix::from_rows(p, rows)
  let finite_coeffs = @finalg.mat_charpoly(finite_matrix)
  let finite_poly = dense_coeffs_to_finalg_poly(finite_coeffs, p)
  exact_mod.equal(finite_poly)
}
