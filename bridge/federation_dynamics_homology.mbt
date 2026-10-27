///|
/// Functional-graph and homology commuting diagrams.
///
/// Dynamics side: a catmath finite dynamical system is the same
/// finite function that semiring/graph decomposes into tails and
/// directed cycles.  Its weak components are the cycle basins,
/// and the adjacency matrix over `Q` has characteristic
/// polynomial
///
/// `x^(number of tail points) * product over cycles (x^L - 1)`.
///
/// The report checks that formula against exact algebra.  Only
/// when the function is actually a permutation is it also read as
/// a symlib permutation; a general functional graph is never
/// silently promoted to one.
///
/// Homology side: catmath chain complexes over `F_p` are re-read
/// by finalg/linalg rank computations, and a pair of consecutive
/// integer boundary matrices is checked against exact rational
/// rank/product computations and both SNF engines.  The mod-`p`
/// two-map homology dimension is reported with the universal
/// coefficient lower bound, not with a false equality that would
/// omit the `Tor(H_{n-1}, F_p)` contribution.

///|
fn dynsys_shape_ok(ds : @catmath.DynSys) -> Bool {
  guard ds.n >= 0 && ds.f.length() == ds.n else { return false }
  for y in ds.f {
    guard y >= 0 && y < ds.n else { return false }
  }
  true
}

///|
/// The functional graph of a finite dynamical system, with one
/// unit-weight edge `x -> f(x)` for every point.
pub fn catmath_dynsys_to_semiring_graph(ds : @catmath.DynSys) -> @sgraph.Graph? {
  guard dynsys_shape_ok(ds) else { return None }
  let from = Array::makei(ds.n, fn(i) { i })
  let weights = Array::make(ds.n, 1)
  Some(@sgraph.Graph::build(ds.n, from, ds.f.copy(), weights))
}

///|
/// Cross-member report for one finite dynamical system.
pub(all) struct FiniteDynamicsFederationReport {
  valid : Bool
  n_points : Int32
  component_count : Int32
  cycle_lengths : Array[Int32]
  periodic_point_count : Int32
  fixed_point_count : Int32
  tail_point_count : Int32
  adjacency_charpoly : @exactalg.QPoly
  is_permutation : Bool
  permutation_order : Int32
  decomposition_ok : Bool
  components_ok : Bool
  charpoly_formula_ok : Bool
  permutation_ok : Bool
}

///|
fn invalid_finite_dynamics_report(
  ds : @catmath.DynSys,
) -> FiniteDynamicsFederationReport {
  {
    valid: false,
    n_points: ds.n,
    component_count: 0,
    cycle_lengths: [],
    periodic_point_count: 0,
    fixed_point_count: 0,
    tail_point_count: 0,
    adjacency_charpoly: @exactalg.qpoly_zero(),
    is_permutation: false,
    permutation_order: 0,
    decomposition_ok: false,
    components_ok: false,
    charpoly_formula_ok: false,
    permutation_ok: false,
  }
}

///|
/// Build the functional-graph report described at the head of
/// this file.
pub fn finite_dynamics_federation_report(
  ds : @catmath.DynSys,
) -> FiniteDynamicsFederationReport {
  let graph = match catmath_dynsys_to_semiring_graph(ds) {
    Some(graph) => graph
    None => return invalid_finite_dynamics_report(ds)
  }
  let catmath_dec = @catmath.cycle_decompose(ds)
  let semiring_dec = @sgraph.functional_decompose(graph)
  guard catmath_dec.length() == ds.n &&
    semiring_dec.cycle_id.length() == ds.n &&
    semiring_dec.dist_to_cycle.length() == ds.n else {
    return invalid_finite_dynamics_report(ds)
  }
  let catmath_labels : Array[Int32] = []
  let mut decomposition_ok = true
  for x in 0..<ds.n {
    let (component, tail, cycle_len) = catmath_dec[x]
    catmath_labels.push(component)
    let semiring_cycle = semiring_dec.cycle_id[x]
    if semiring_cycle < 0 ||
      semiring_cycle >= semiring_dec.cycle_len.length() ||
      tail != semiring_dec.dist_to_cycle[x] ||
      cycle_len != semiring_dec.cycle_len[semiring_cycle] {
      decomposition_ok = false
    }
  }
  decomposition_ok = decomposition_ok &&
    federation_same_partition(catmath_labels, semiring_dec.cycle_id)
  let edges : Array[(Int32, Int32)] = []
  for x in 0..<ds.n {
    edges.push((x, ds.f[x]))
  }
  let finalg_labels = @fcat.graph_components(@fcat.Graph::{ n: ds.n, edges, })
  let components_ok = federation_same_partition(catmath_labels, finalg_labels)
  let periodic = @catmath.periodic_points(ds)
  let seen_components : Array[Int32] = []
  let cycle_lengths_unsorted : Array[Int32] = []
  for x in periodic {
    let (component, _tail, cycle_len) = catmath_dec[x]
    let mut seen = false
    for old in seen_components {
      if old == component {
        seen = true
      }
    }
    if !seen {
      seen_components.push(component)
      cycle_lengths_unsorted.push(cycle_len)
    }
  }
  let cycle_lengths = federation_sorted_copy(cycle_lengths_unsorted)
  let tail_count = ds.n - periodic.length()
  let adjacency = Array::makei(ds.n, fn(_i) { Array::make(ds.n, 0) })
  for x in 0..<ds.n {
    adjacency[x][ds.f[x]] = 1
  }
  let exact_charpoly = if ds.n == 0 {
    @exactalg.qpoly_one()
  } else {
    @exactalg.qmat_charpoly(@exactalg.qmat_from_int_rows(adjacency))
  }
  let mut formula = @exactalg.qpoly_pow(@exactalg.qpoly_x(), tail_count)
  for len in cycle_lengths_unsorted {
    let cycle_factor = @exactalg.qpoly_sub(
      @exactalg.qpoly_pow(@exactalg.qpoly_x(), len),
      @exactalg.qpoly_one(),
    )
    formula = @exactalg.qpoly_mul(formula, cycle_factor)
  }
  let charpoly_formula_ok = @exactalg.qpoly_eq(exact_charpoly, formula)
  let is_permutation = @catmath.is_permutation(ds)
  let mut permutation_order = 0
  let mut permutation_ok = !is_permutation
  if is_permutation {
    let perm = @sym.Perm::from_img(ds.f.copy())
    let sym_lengths : Array[Int32] = []
    for cycle in perm.cycles() {
      sym_lengths.push(cycle.length())
    }
    permutation_order = perm.order()
    let generated = @sym.PermGroup::new(ds.n, [perm])
    permutation_ok = int_arrays_equal(
        federation_sorted_copy(sym_lengths),
        cycle_lengths,
      ) &&
      generated.order() == permutation_order.to_int64()
  }
  let valid = decomposition_ok &&
    components_ok &&
    charpoly_formula_ok &&
    permutation_ok
  {
    valid,
    n_points: ds.n,
    component_count: federation_unique_count(catmath_labels),
    cycle_lengths,
    periodic_point_count: periodic.length(),
    fixed_point_count: @catmath.fixed_points(ds).length(),
    tail_point_count: tail_count,
    adjacency_charpoly: exact_charpoly,
    is_permutation,
    permutation_order,
    decomposition_ok,
    components_ok,
    charpoly_formula_ok,
    permutation_ok,
  }
}

///|
/// Whether the functional-graph translations all commute.
pub fn check_finite_dynamics_federation(ds : @catmath.DynSys) -> Bool {
  finite_dynamics_federation_report(ds).valid
}

///|
fn catmath_fp_matrix_shape_ok(m : @catmath.Mat, p : Int32) -> Bool {
  guard m.p == p && m.rows >= 0 && m.cols >= 0 else { return false }
  guard m.data.length() == m.rows else { return false }
  for row in m.data {
    guard row.length() == m.cols else { return false }
  }
  true
}

///|
/// Cross-member report for one finite chain complex over `F_p`.
pub(all) struct FpChainComplexFederationReport {
  valid : Bool
  prime : Int32
  dimensions : Array[Int32]
  boundary_ranks : Array[Int32]
  homology_dimensions : Array[Int32]
  euler_characteristic : Int32
  shape_ok : Bool
  chain_ok : Bool
  ranks_ok : Bool
  homology_ok : Bool
  euler_ok : Bool
}

///|
fn invalid_fp_chain_complex_report(
  cc : @catmath.ChainComplex,
) -> FpChainComplexFederationReport {
  {
    valid: false,
    prime: cc.p,
    dimensions: [],
    boundary_ranks: [],
    homology_dimensions: [],
    euler_characteristic: 0,
    shape_ok: false,
    chain_ok: false,
    ranks_ok: false,
    homology_ok: false,
    euler_ok: false,
  }
}

///|
/// Build the `F_p` chain-complex report.
///
/// catmath's representation stores only the differentials
/// `diff[k] = d_{k+1}`; with no differential at all the dimension
/// of `C_0` is not determined by the value, so the empty list is
/// rejected here rather than assigned a fictitious homology.
pub fn fp_chain_complex_federation_report(
  cc : @catmath.ChainComplex,
) -> FpChainComplexFederationReport {
  guard @fnum.is_prime(cc.p) && cc.diff.length() > 0 else {
    return invalid_fp_chain_complex_report(cc)
  }
  let mut shape_ok = true
  for m in cc.diff {
    if !catmath_fp_matrix_shape_ok(m, cc.p) {
      shape_ok = false
    }
  }
  for k in 0..<(cc.diff.length() - 1) {
    if cc.diff[k].cols != cc.diff[k + 1].rows {
      shape_ok = false
    }
  }
  guard shape_ok else { return invalid_fp_chain_complex_report(cc) }
  let dimensions : Array[Int32] = [cc.diff[0].rows]
  for m in cc.diff {
    dimensions.push(m.cols)
  }
  let boundary_ranks : Array[Int32] = []
  let mut ranks_ok = true
  for m in cc.diff {
    let catmath_rank = @catmath.mat_rank(m)
    let finalg_rank = @flinalg.Matrix::from_rows(cc.p, m.data).rank()
    boundary_ranks.push(finalg_rank)
    if catmath_rank != finalg_rank {
      ranks_ok = false
    }
  }
  let homology_dimensions : Array[Int32] = []
  let mut homology_ok = true
  for degree in 0..<dimensions.length() {
    let expected = if degree == 0 {
      dimensions[0] - boundary_ranks[0]
    } else {
      let kernel_dim = dimensions[degree] - boundary_ranks[degree - 1]
      if degree < boundary_ranks.length() {
        kernel_dim - boundary_ranks[degree]
      } else {
        kernel_dim
      }
    }
    homology_dimensions.push(expected)
    if @catmath.homology_dim(cc, degree) != expected {
      homology_ok = false
    }
  }
  let mut dimension_euler = 0
  let mut homology_euler = 0
  for degree in 0..<dimensions.length() {
    if degree % 2 == 0 {
      dimension_euler = dimension_euler + dimensions[degree]
      homology_euler = homology_euler + homology_dimensions[degree]
    } else {
      dimension_euler = dimension_euler - dimensions[degree]
      homology_euler = homology_euler - homology_dimensions[degree]
    }
  }
  let chain_ok = @catmath.check_chain_complex(cc)
  let euler_ok = dimension_euler == homology_euler
  let valid = chain_ok && ranks_ok && homology_ok && euler_ok
  {
    valid,
    prime: cc.p,
    dimensions,
    boundary_ranks,
    homology_dimensions,
    euler_characteristic: dimension_euler,
    shape_ok,
    chain_ok,
    ranks_ok,
    homology_ok,
    euler_ok,
  }
}

///|
/// Whether catmath and finalg/linalg agree on this chain complex
/// and its homology dimensions.
pub fn check_fp_chain_complex_federation(cc : @catmath.ChainComplex) -> Bool {
  fp_chain_complex_federation_report(cc).valid
}

///|
/// Cross-member report for two consecutive integer boundary maps
/// `C_{n+1} --B--> C_n --A--> C_{n-1}`.
pub(all) struct IntegralHomologyFederationReport {
  valid : Bool
  middle_dimension : Int32
  rank_a : Int32
  rank_b : Int32
  free_rank : Int32
  torsion_factors : Array[Int32]
  prime : Int32
  mod_p_rank_a : Int32
  mod_p_rank_b : Int32
  mod_p_homology_dimension : Int32
  p_torsion_factor_count : Int32
  product_zero_ok : Bool
  snf_ok : Bool
  universal_coefficient_bound_ok : Bool
}

///|
fn invalid_integral_homology_report(
  p : Int32,
) -> IntegralHomologyFederationReport {
  {
    valid: false,
    middle_dimension: 0,
    rank_a: 0,
    rank_b: 0,
    free_rank: 0,
    torsion_factors: [],
    prime: p,
    mod_p_rank_a: 0,
    mod_p_rank_b: 0,
    mod_p_homology_dimension: 0,
    p_torsion_factor_count: 0,
    product_zero_ok: false,
    snf_ok: false,
    universal_coefficient_bound_ok: false,
  }
}

///|
/// Build the integral-homology report for one middle degree.
///
/// `d_n` is the outgoing boundary `A` and `d_n1` the incoming
/// boundary `B`, matching catmath's argument order.  The torsion
/// list is the part `> 1` of the Smith factors of `B` (the kernel
/// of an integer matrix is a pure sublattice, so those are the
/// torsion factors of `ker A / im B`).  Modulo `p`, the dimension
/// of `ker(A⊗F_p)/im(B⊗F_p)` is computed from both finite-field
/// rank engines and checked against the universal coefficient
/// inequality `dim >= free_rank + #{torsion factors divisible by
/// p}`; equality is not claimed because `Tor(H_{n-1},F_p)` may
/// contribute further dimensions.
pub fn integral_homology_federation_report(
  d_n : Array[Array[Int32]],
  d_n1 : Array[Array[Int32]],
  p : Int32,
) -> IntegralHomologyFederationReport {
  guard @fnum.is_prime(p) else { return invalid_integral_homology_report(p) }
  let (a_rows, a_cols) = match int_matrix_shape(d_n) {
    Some(shape) => shape
    None => return invalid_integral_homology_report(p)
  }
  let (b_rows, b_cols) = match int_matrix_shape(d_n1) {
    Some(shape) => shape
    None => return invalid_integral_homology_report(p)
  }
  guard a_cols == b_rows else { return invalid_integral_homology_report(p) }
  let _ = a_rows
  let _ = b_cols
  let exact_a = @exactalg.qmat_from_int_rows(d_n)
  let exact_b = @exactalg.qmat_from_int_rows(d_n1)
  let product_zero_ok = @exactalg.qmat_is_zero(
    @exactalg.qmat_mul(exact_a, exact_b),
  )
  let rank_a = @exactalg.qmat_rank(exact_a)
  let rank_b = @exactalg.qmat_rank(exact_b)
  let b_normal = match integer_matrix_normal_form_report(d_n1) {
    Some(report) => report
    None => return invalid_integral_homology_report(p)
  }
  let (catmath_free, catmath_torsion) = @catmath.integral_homology(
    @catmath.int_mat_of(a_rows, a_cols, copy_int_matrix(d_n)),
    @catmath.int_mat_of(b_rows, b_cols, copy_int_matrix(d_n1)),
  )
  let finalg_torsion : Array[Int32] = []
  for factor in b_normal.finalg_snf_diag {
    if factor > 1 {
      finalg_torsion.push(factor)
    }
  }
  let free_rank = a_cols - rank_a - rank_b
  let snf_ok = b_normal.snf_agrees &&
    catmath_free == free_rank &&
    int_arrays_equal(catmath_torsion, finalg_torsion)
  let finalg_rank_a = @flinalg.Matrix::from_rows(p, d_n).rank()
  let finalg_rank_b = @flinalg.Matrix::from_rows(p, d_n1).rank()
  let catmath_rank_a = @catmath.rank_f_p(copy_int_matrix(d_n), p)
  let catmath_rank_b = @catmath.rank_f_p(copy_int_matrix(d_n1), p)
  let mod_p_homology_dimension = a_cols - finalg_rank_a - finalg_rank_b
  let mut p_torsion_factor_count = 0
  for factor in finalg_torsion {
    if factor % p == 0 {
      p_torsion_factor_count = p_torsion_factor_count + 1
    }
  }
  let universal_coefficient_bound_ok = finalg_rank_a == catmath_rank_a &&
    finalg_rank_b == catmath_rank_b &&
    mod_p_homology_dimension >= free_rank + p_torsion_factor_count
  let valid = product_zero_ok &&
    snf_ok &&
    universal_coefficient_bound_ok &&
    free_rank >= 0
  {
    valid,
    middle_dimension: a_cols,
    rank_a,
    rank_b,
    free_rank,
    torsion_factors: finalg_torsion,
    prime: p,
    mod_p_rank_a: finalg_rank_a,
    mod_p_rank_b: finalg_rank_b,
    mod_p_homology_dimension,
    p_torsion_factor_count,
    product_zero_ok,
    snf_ok,
    universal_coefficient_bound_ok,
  }
}

///|
/// Whether the two-boundary integral homology diagram commutes.
pub fn check_integral_homology_federation(
  d_n : Array[Array[Int32]],
  d_n1 : Array[Array[Int32]],
  p : Int32,
) -> Bool {
  integral_homology_federation_report(d_n, d_n1, p).valid
}
