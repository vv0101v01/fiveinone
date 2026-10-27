///|
/// Five-member federation executable checks inside the single bridge package.
///
/// These functions are ordinary library checks.  In the current
/// federation stage they are compile-checked together with the rest
/// of the package; running the test suite remains a separate,
/// explicitly requested step.

///|
/// Finite categories: symlib tables, catmath tables and finalg's
/// closure dictionary agree on the walking arrow, and catmath's
/// delooping of a cyclic group satisfies its own category checker.
pub fn check_federation_category_bridge() -> Bool {
  let table = @sym.cat_arrow()
  let catmath_table = match fincat_to_catmath_category(table) {
    Some(category) => category
    None => return false
  }
  guard @catmath.check_laws(catmath_table) else { return false }
  let back = match catmath_category_to_fincat(catmath_table) {
    Some(back) => back
    None => return false
  }
  guard fincat_tables_equal(table, back) else { return false }
  guard fincat_finalg_category_laws(table) else { return false }
  let delooping = @catmath.group_as_category(@catmath.cyclic_group(4))
  @catmath.check_laws(delooping)
}

///|
/// Finite groups: Cayley tables and permutation groups agree in both
/// directions on small cyclic examples.
pub fn check_federation_group_bridge() -> Bool {
  let cyclic6 = @catmath.cyclic_group(6)
  let embedded = match catmath_fin_group_to_symlib_perm_group(cyclic6) {
    Some(group) => group
    None => return false
  }
  guard embedded.order() == 6L else { return false }
  let table = match
    symlib_perm_group_to_catmath_fin_group(@sym.PermGroup::cyclic(5), 32) {
    Some(table) => table
    None => return false
  }
  table.order == 5 && @catmath.check_group(table)
}

///|
/// Polynomials: the finalg/QPoly representative round trip holds, an
/// integral QPoly reduces coefficientwise as documented, and finalg's
/// Groebner ideal membership sees the expected generator.
pub fn check_federation_polynomial_bridge() -> Bool {
  let finite_poly = @finalg.poly_of_terms(1, 7, [(1, [0]), (2, [1]), (1, [2])])
  guard finalg_univariate_qpoly_roundtrip(finite_poly) else { return false }
  let integral_poly = @exactalg.qpoly_normalize([
    @exactalg.rat_int(1),
    @exactalg.rat_int(-3),
    @exactalg.rat_int(2),
  ])
  let reduced = match qpoly_to_finalg_univariate(integral_poly, 5) {
    Some(reduced) => reduced
    None => return false
  }
  let coeffs = match finalg_univariate_dense_coeffs(reduced) {
    Some(coeffs) => coeffs
    None => return false
  }
  guard coeffs.length() == 3 else { return false }
  guard coeffs[0] == 1 && coeffs[1] == 2 && coeffs[2] == 2 else { return false }
  let x = @finalg.Poly::variable(1, 7, 0)
  let one = @finalg.Poly::one(1, 7)
  @finalg.ideal_membership(x, [x]) && !@finalg.ideal_membership(one, [x])
}

///|
/// Integer matrices: finalg/catmath Smith factors and exact/finite
/// characteristic polynomials agree on small examples.
pub fn check_federation_matrix_bridge() -> Bool {
  integer_snf_cross_check([[2, 4], [6, 8]]) &&
  integer_matrix_charpoly_cross_check_mod([[2, 1], [0, 3]], 7)
}

///|
/// Circle loops: cubical degrees, finalg winding representatives and
/// catmath encode/decode agree on a symmetric sample range.
pub fn check_federation_circle_bridge() -> Bool {
  circle_winding_cross_check([-3, -1, 0, 1, 2, 5])
}

///|
/// finalg's proof-enabled arithmetic package still satisfies its
/// elementary executable specifications.  This is not a `moon prove`
/// run; it only exercises the compiled functions when called.
pub fn check_federation_finalg_verify_bridge() -> Bool {
  let division = @fverify.euclid_divmod(37, 5)
  division.q == 7 &&
  division.r == 2 &&
  @fverify.pow2_rec(8) == 256 &&
  @fverify.pow_mod(2, 10, 1000) == 24 &&
  @fverify.mod_pos(-3, 7) == 4
}

///|
/// catmath's canonical-form and derived-theorem registries are
/// present and non-empty after the namespace move.
pub fn check_federation_catmath_registry() -> Bool {
  @catmath.canonical_index().length() > 0 &&
  @catmath.derived_index().length() > 0
}
