///|
/// Concrete checks for the research-driven unification layer:
/// finite Heyting observable-subtype logic and bounded
/// tropical corner loci.  As with the earlier bridge checks,
/// the current stage compiles these functions and their tests;
/// executing them remains a separate runtime-stage step.

///|
/// A non-Boolean chain-with-isolated-point topology, the
/// discrete Boolean topology, and the finite spectrum already
/// used by the topology bridge.
pub fn check_federation_heyting_unification_bridge() -> Bool {
  let chain = @catmath.make_top(3, [
    [true, true, false],
    [false, true, false],
    [false, false, true],
  ])
  let chain_report = finite_heyting_topology_report(chain)
  guard chain_report.valid && !chain_report.boolean else { return false }
  guard chain_report.open_count == 6 else { return false }
  // The open `{1}` has pseudocomplement `{2}`, not its
  // set-theoretic complement `{0,2}`; this is the point at
  // which the observable subtype lattice is Heyting rather
  // than Boolean.
  guard fintop_heyting_negation(chain, 2) == Some(4) else { return false }
  guard fintop_open_subtype_of(chain, 2, 3) else { return false }
  guard !fintop_open_subtype_of(chain, 3, 2) else { return false }

  let discrete = @catmath.make_top(3, [
    [true, false, false],
    [false, true, false],
    [false, false, true],
  ])
  let discrete_report = finite_heyting_topology_report(discrete)
  guard discrete_report.valid && discrete_report.boolean else { return false }
  guard discrete_report.open_count == 8 else { return false }

  let alg = @ffinite.FinAlg::univariate_quotient(5, [3, 4, 1])
  let spectral_topology = finalg_spec_to_catmath_fintop(@fscheme.spec(alg))
  check_finite_heyting_topology(spectral_topology)
}

///|
/// Multivariate support tropicalization with a Gröbner-refined
/// sample, plus exact p-adic univariate corner points.
///
/// For `<x+y+1, x+1> = <x+1, y>`, the generators' sample has
/// the three points `(0,0), (0,1), (0,2)`, while the monomial
/// `y` in the Gröbner basis correctly refines it to the empty
/// sample.  This example also keeps the distinction visible:
/// refinement is not a claim that every lex Gröbner basis is a
/// tropical basis.
pub fn check_federation_tropical_unification_bridge() -> Bool {
  let line = @finalg.poly_of_terms(2, 5, [(1, [0, 0]), (1, [1, 0]), (1, [0, 1])])
  let vertical = @finalg.poly_of_terms(2, 5, [(1, [0, 0]), (1, [1, 0])])
  let report = tropical_corner_sample_report([line, vertical], -2, 2)
  guard report.valid && report.bivariate_supported else { return false }
  guard report.generator_point_count == 3 else { return false }
  guard report.groebner_point_count == 0 && !report.samples_equal else {
    return false
  }
  let singleton = tropical_corner_sample_report([line], -2, 2)
  guard singleton.valid && singleton.samples_equal else { return false }

  let factor2 = @exactalg.qpoly_root_factor(@exactalg.rat_int(2))
  let factor4 = @exactalg.qpoly_root_factor(@exactalg.rat_int(4))
  let product = @exactalg.qpoly_mul(factor2, factor4)
  let padic = padic_tropical_hypersurface_report(product, 2, -1, 4)
  padic.valid && int_arrays_equal(padic.integer_corner_points, [1, 2])
}
