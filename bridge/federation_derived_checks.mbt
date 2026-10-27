///|
/// Concrete second-wave federation certificates.
///
/// Each function merely evaluates the corresponding report on a
/// small native example.  They are library checks: the current
/// development stage compile-checks them, while executing the
/// test suite remains a separate explicitly requested step.

///|
/// Finite categories, groups and G-sets: table categories, the
/// Cayley embedding / delooping / regular projector diagram, and
/// the Burnside/orbit/projector diagram.
pub fn check_federation_finite_structure_derived_bridges() -> Bool {
  guard check_finite_category_federation(@sym.cat_arrow()) else { return false }
  guard check_finite_category_federation(@sym.cat_cospan()) else {
    return false
  }
  guard check_finite_group_federation(@catmath.cyclic_group(6), 32) else {
    return false
  }
  guard check_finite_group_federation(@catmath.symmetric_group(3), 32) else {
    return false
  }
  let cosets = @catmath.coset_gset(@catmath.cyclic_group(6), [0, 3])
  check_finite_gset_federation(cosets)
}

///|
/// Polynomial reduction and integer matrices: reduction as a ring
/// homomorphism, roots/Hensel lifts, companion and quotient
/// algebra, tropicalization, SNF/rank/characteristic polynomials
/// and the finite cokernel group.
pub fn check_federation_algebra_derived_bridges() -> Bool {
  let f = @exactalg.qpoly_normalize([
    @exactalg.rat_int(8),
    @exactalg.rat_int(-6),
    @exactalg.rat_int(1),
  ])
  let g = @exactalg.qpoly_normalize([@exactalg.rat_int(1), @exactalg.rat_int(1)])
  guard check_polynomial_reduction_federation(f, g, 5, [-1, 0, 2, 7]) else {
    return false
  }
  check_integer_matrix_federation([[2, 4], [6, 8]], 5, 64)
}

///|
/// Boolean functions, finite Alexandrov topologies and a finite
/// spectrum: ANF versus DNF/BDD semantics, specialization
/// preorders as thin categories, and the transposed Spec order.
pub fn check_federation_boolean_topology_derived_bridges() -> Bool {
  guard check_boolean_function_federation(3, [0, 0, 0, 1, 0, 1, 1, 1]) else {
    return false
  }
  let top = @catmath.make_top(3, [
    [true, true, false],
    [false, true, false],
    [false, false, true],
  ])
  guard check_finite_topology_federation(top) else { return false }
  let alg = @ffinite.FinAlg::univariate_quotient(5, [3, 4, 1])
  check_finite_spec_federation(alg)
}

///|
/// Functional graphs and homology: tail/cycle decomposition with
/// its characteristic-polynomial formula, `F_p` chain ranks and
/// homology, and integral two-boundary homology.
pub fn check_federation_dynamics_homology_derived_bridges() -> Bool {
  let dynamics = @catmath.make_dyn(6, [1, 2, 1, 4, 3, 3])
  guard check_finite_dynamics_federation(dynamics) else { return false }
  guard check_fp_chain_complex_federation(@catmath.koszul_poly(5)) else {
    return false
  }
  check_integral_homology_federation([[0, 0]], [[2, 0], [0, 3]], 2)
}

///|
/// The common STLC fragment.  The swap example deliberately
/// exercises the one recorded difference between the two native
/// normalizers: cubical unit-η versus catmath's raw neutral unit
/// subterm, aligned only after the explicit bridge completion.
pub fn check_federation_stlc_derived_bridge() -> Bool {
  let atom = @catmath.stype_atom()
  let one = @catmath.stype_one()
  let identity = @catmath.sterm_lam_of(atom, @catmath.sterm_var_of(0))
  guard check_stlc_federation([], identity) else { return false }
  let p = @catmath.sterm_var_of(0)
  let swap = @catmath.sterm_lam_of(
    @catmath.stype_pair(atom, one),
    @catmath.sterm_pair_of(@catmath.sterm_snd_of(p), @catmath.sterm_fst_of(p)),
  )
  let swap_report = stlc_federation_report([], swap)
  guard swap_report.valid && swap_report.unit_eta_completion_needed else {
    return false
  }
  check_stlc_federation(
    [@catmath.stype_arrow(atom, atom)],
    @catmath.sterm_var_of(0),
  )
}
