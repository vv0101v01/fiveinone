///|
/// Boolean-function and finite-topology commuting diagrams.
///
/// Boolean side: one truth table has two canonical finite
/// presentations in the federation.  finalg gives its algebraic
/// normal form over `F_2` (XOR of monomials), while the cubical
/// pillar gives face formulas and their ROBDD quotient.  The XOR
/// in an ANF is encoded in the face language as the mutually
/// exclusive disjunction `(a∧¬b)∨(¬a∧b)`; it is never confused
/// with face OR.  `FaceClass` then reads the common semantics in
/// the bridge's Boolean-lattice semiring.
///
/// Topology side: catmath's finite Alexandrov spaces are
/// specialization preorders.  The same preorder is a thin finite
/// category, so the category report supplies its skeleton (= T0
/// quotient count), components and exact adjacency invariant.
/// For finalg spectra there is one essential transpose:
/// `Spec::is_le(i,j)` is ideal inclusion `P_i ⊆ P_j`, whereas the
/// specialization relation `x ≤ y` means `x ∈ closure({y})`, i.e.
/// `P_y ⊆ P_x`.  The converter below performs exactly that
/// transpose and the Spec report checks the resulting open-set
/// families mask by mask.

///|
fn federation_pow2_checked(n : Int32) -> Int32? {
  guard n >= 0 && n <= 30 else { return None }
  let mut out = 1
  for _i in 0..<n {
    out = out * 2
  }
  Some(out)
}

///|
fn federation_bit(mask : Int32, k : Int32) -> Bool {
  ((mask >> k) & 1) == 1
}

///|
fn federation_face_xor(a : @cub.Face, b : @cub.Face) -> @cub.Face {
  @cub.face_or(
    @cub.face_and(a, @cub.face_not(b)),
    @cub.face_and(@cub.face_not(a), b),
  )
}

///|
/// Canonical full DNF of a truth table: one complete conjunction
/// of literals for each satisfying assignment.  Table entries are
/// read modulo 2, in finalg's assignment-mask order (bit `k` of
/// the mask is variable `k`).
pub fn truth_table_to_cubical_face_dnf(
  n : Int32,
  table : Array[Int32],
) -> @cub.Face? {
  let size = match federation_pow2_checked(n) {
    Some(size) => size
    None => return None
  }
  guard table.length() == size else { return None }
  let mut out = @cub.face_bot()
  for mask in 0..<size {
    if table[mask] % 2 != 0 {
      let mut term = @cub.face_top()
      for k in 0..<n {
        let literal = if federation_bit(mask, k) {
          @cub.face_var1(k)
        } else {
          @cub.face_var0(k)
        }
        term = @cub.face_and(term, literal)
      }
      out = @cub.face_or(out, term)
    }
  }
  Some(out)
}

///|
/// Read finalg ANF coefficients as a cubical face.  A coefficient
/// mask contributes the conjunction of its positive variables;
/// distinct monomials are combined by XOR, explicitly encoded in
/// the face language.
pub fn anf_coeffs_to_cubical_face(
  n : Int32,
  coeffs : Array[Int32],
) -> @cub.Face? {
  let size = match federation_pow2_checked(n) {
    Some(size) => size
    None => return None
  }
  guard coeffs.length() == size else { return None }
  let mut out = @cub.face_bot()
  for mask in 0..<size {
    if coeffs[mask] % 2 != 0 {
      let mut term = @cub.face_top()
      for k in 0..<n {
        if federation_bit(mask, k) {
          term = @cub.face_and(term, @cub.face_var1(k))
        }
      }
      out = federation_face_xor(out, term)
    }
  }
  Some(out)
}

///|
/// Cross-member report for one Boolean function given by a truth
/// table.
pub(all) struct BooleanFunctionFederationReport {
  valid : Bool
  nvars : Int32
  table_size : Int32
  support_count : Int32
  anf_coeffs : Array[Int32]
  anf_degree : Int32
  anf_term_count : Int32
  dnf_face : @cub.Face
  anf_face : @cub.Face
  satisfiable : Bool
  tautology : Bool
  anf_evaluation_ok : Bool
  anf_involution_ok : Bool
  dnf_evaluation_ok : Bool
  anf_face_evaluation_ok : Bool
  face_equivalence_ok : Bool
  witness_ok : Bool
  face_class_ok : Bool
}

///|
fn invalid_boolean_function_report(
  n : Int32,
  table : Array[Int32],
) -> BooleanFunctionFederationReport {
  {
    valid: false,
    nvars: n,
    table_size: table.length(),
    support_count: 0,
    anf_coeffs: [],
    anf_degree: -1,
    anf_term_count: 0,
    dnf_face: @cub.face_bot(),
    anf_face: @cub.face_bot(),
    satisfiable: false,
    tautology: false,
    anf_evaluation_ok: false,
    anf_involution_ok: false,
    dnf_evaluation_ok: false,
    anf_face_evaluation_ok: false,
    face_equivalence_ok: false,
    witness_ok: false,
    face_class_ok: false,
  }
}

///|
/// Build the Boolean-function report.  Every check is exhaustive
/// over the `2^n` assignments, so callers choose `n` accordingly;
/// table entries are normalized modulo 2 exactly as finalg's ANF
/// transform does.
pub fn boolean_function_federation_report(
  n : Int32,
  table : Array[Int32],
) -> BooleanFunctionFederationReport {
  let size = match federation_pow2_checked(n) {
    Some(size) => size
    None => return invalid_boolean_function_report(n, table)
  }
  guard table.length() == size else {
    return invalid_boolean_function_report(n, table)
  }
  let normalized = Array::makei(size, fn(i) {
    if table[i] % 2 == 0 {
      0
    } else {
      1
    }
  })
  let dnf_face = match truth_table_to_cubical_face_dnf(n, normalized) {
    Some(face) => face
    None => return invalid_boolean_function_report(n, table)
  }
  let anf_coeffs = @finalg.anf_transform(n, normalized)
  let anf_face = match anf_coeffs_to_cubical_face(n, anf_coeffs) {
    Some(face) => face
    None => return invalid_boolean_function_report(n, table)
  }
  let mut support_count = 0
  let mut anf_evaluation_ok = true
  let mut dnf_evaluation_ok = true
  let mut anf_face_evaluation_ok = true
  for mask in 0..<size {
    if normalized[mask] == 1 {
      support_count = support_count + 1
    }
    if @finalg.anf_eval(n, anf_coeffs, mask) != normalized[mask] {
      anf_evaluation_ok = false
    }
    let env = @cub.assignment_of_mask(mask, n)
    if @cub.face_holds(dnf_face, env) != (normalized[mask] == 1) {
      dnf_evaluation_ok = false
    }
    if @cub.face_holds(anf_face, env) != (normalized[mask] == 1) {
      anf_face_evaluation_ok = false
    }
  }
  let anf_involution_ok = int_arrays_equal(
    @finalg.anf_transform(n, anf_coeffs),
    normalized,
  )
  let face_equivalence_ok = @cub.face_eq_mod(dnf_face, anf_face, n)
  let satisfiable = support_count > 0
  let witness_matches = match @cub.face_witness(dnf_face, n) {
    Some(env) => satisfiable && @cub.face_holds(dnf_face, env)
    None => !satisfiable
  }
  let witness_ok = witness_matches && @cub.face_sat(dnf_face, n) == satisfiable
  let dnf_class = FaceClass::of_face(dnf_face, n)
  let anf_class = FaceClass::of_face(anf_face, n)
  let face_class_ok = dnf_class == anf_class &&
    dnf_class.is_bottom() == !satisfiable &&
    dnf_class.is_top() == (support_count == size) &&
    dnf_class.join(dnf_class.complement()).is_top() &&
    dnf_class.meet(dnf_class.complement()).is_bottom()
  let mut anf_term_count = 0
  for coeff in anf_coeffs {
    if coeff % 2 != 0 {
      anf_term_count = anf_term_count + 1
    }
  }
  let valid = anf_evaluation_ok &&
    anf_involution_ok &&
    dnf_evaluation_ok &&
    anf_face_evaluation_ok &&
    face_equivalence_ok &&
    witness_ok &&
    face_class_ok
  {
    valid,
    nvars: n,
    table_size: size,
    support_count,
    anf_coeffs,
    anf_degree: @finalg.anf_degree(anf_coeffs),
    anf_term_count,
    dnf_face,
    anf_face,
    satisfiable,
    tautology: support_count == size,
    anf_evaluation_ok,
    anf_involution_ok,
    dnf_evaluation_ok,
    anf_face_evaluation_ok,
    face_equivalence_ok,
    witness_ok,
    face_class_ok,
  }
}

///|
/// Whether the truth-table, ANF and face/BDD presentations all
/// describe the same Boolean function.
pub fn check_boolean_function_federation(
  n : Int32,
  table : Array[Int32],
) -> Bool {
  boolean_function_federation_report(n, table).valid
}

///|
fn fintop_shape_ok(tt : @catmath.FinTop) -> Bool {
  guard tt.n >= 0 && tt.le.length() == tt.n else { return false }
  for row in tt.le {
    guard row.length() == tt.n else { return false }
  }
  true
}

///|
fn bool_matrices_equal(a : Array[Array[Bool]], b : Array[Array[Bool]]) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard a[i].length() == b[i].length() else { return false }
    for j in 0..<a[i].length() {
      guard a[i][j] == b[i][j] else { return false }
    }
  }
  true
}

///|
/// Read a finite Alexandrov topology as its thin specialization
/// category: there is a unique arrow `x -> y` exactly when
/// `x ≤ y`.
pub fn catmath_fintop_to_symlib_fincat(tt : @catmath.FinTop) -> @sym.FinCat? {
  guard fintop_shape_ok(tt) && @catmath.check_preorder(tt) else { return None }
  let pairs : Array[(Int32, Int32)] = []
  for i in 0..<tt.n {
    for j in 0..<tt.n {
      if tt.le[i][j] {
        pairs.push((i, j))
      }
    }
  }
  Some(@sym.cat_poset(tt.n, pairs))
}

///|
/// Read a thin symlib finite category as a finite topology.  A
/// category with any Hom-set of size other than 0 or 1 is not a
/// preorder and is rejected rather than collapsed.
pub fn symlib_thin_fincat_to_catmath_fintop(
  c : @sym.FinCat,
) -> @catmath.FinTop? {
  let report = finite_category_federation_report(c)
  guard report.valid else { return None }
  let le : Array[Array[Bool]] = []
  for i in 0..<c.nobj {
    let row : Array[Bool] = []
    for j in 0..<c.nobj {
      let count = report.hom_count_matrix[i][j]
      guard count == 0 || count == 1 else { return None }
      row.push(count == 1)
    }
    le.push(row)
  }
  let top = @catmath.make_top(c.nobj, le)
  guard bool_matrices_equal(top.le, le) else { return None }
  Some(top)
}

///|
/// Cross-member report for one finite Alexandrov topology.
pub(all) struct FiniteTopologyFederationReport {
  valid : Bool
  n_points : Int32
  relation_count : Int32
  t0 : Bool
  t0_quotient_points : Int32
  component_count : Int32
  open_set_count : Int32
  adjacency_charpoly : @exactalg.QPoly
  preorder_ok : Bool
  semiring_closure_ok : Bool
  thin_category_ok : Bool
  t0_skeleton_ok : Bool
  components_ok : Bool
  identity_homeomorphism_ok : Bool
  open_sets_supported : Bool
  open_sets_ok : Bool
}

///|
fn invalid_finite_topology_report(
  tt : @catmath.FinTop,
) -> FiniteTopologyFederationReport {
  {
    valid: false,
    n_points: tt.n,
    relation_count: 0,
    t0: false,
    t0_quotient_points: 0,
    component_count: 0,
    open_set_count: 0,
    adjacency_charpoly: @exactalg.qpoly_zero(),
    preorder_ok: false,
    semiring_closure_ok: false,
    thin_category_ok: false,
    t0_skeleton_ok: false,
    components_ok: false,
    identity_homeomorphism_ok: false,
    open_sets_supported: false,
    open_sets_ok: false,
  }
}

///|
/// Build the finite-topology report.  Open-set enumeration is
/// exponential and is therefore a separately marked fragment for
/// `n <= 16`; all preorder/category/component clauses are
/// polynomial in the table size.
pub fn finite_topology_federation_report(
  tt : @catmath.FinTop,
) -> FiniteTopologyFederationReport {
  guard fintop_shape_ok(tt) else { return invalid_finite_topology_report(tt) }
  let preorder_ok = @catmath.check_preorder(tt)
  let closure = match federation_bool_closure(tt.le) {
    Some(closed) => closed
    None => return invalid_finite_topology_report(tt)
  }
  let semiring_closure_ok = bool_matrices_equal(closure, tt.le)
  let thin = match catmath_fintop_to_symlib_fincat(tt) {
    Some(cat) => cat
    None => return invalid_finite_topology_report(tt)
  }
  let category_report = finite_category_federation_report(thin)
  let mut relation_count = 0
  let mut hom_relation_ok = category_report.n_objects == tt.n
  for i in 0..<tt.n {
    for j in 0..<tt.n {
      if tt.le[i][j] {
        relation_count = relation_count + 1
      }
      if category_report.hom_count_matrix[i][j] !=
        (if tt.le[i][j] { 1 } else { 0 }) {
        hom_relation_ok = false
      }
    }
  }
  let thin_category_ok = category_report.valid && hom_relation_ok
  let t0_quotient = @catmath.t0_quotient(tt)
  let t0 = @catmath.is_t0(tt)
  let t0_skeleton_ok = t0_quotient.n == category_report.iso_class_count &&
    t0 == (t0_quotient.n == tt.n) &&
    @catmath.is_t0(t0_quotient)
  let catmath_components = @catmath.connected_components(tt)
  let closure_labels = match federation_closure_partition_labels(tt.le) {
    Some(labels) => labels
    None => return invalid_finite_topology_report(tt)
  }
  let components_ok = federation_same_partition(
      catmath_components, closure_labels,
    ) &&
    federation_unique_count(catmath_components) ==
    category_report.underlying_component_count
  let identity = Array::makei(tt.n, fn(i) { i })
  let identity_homeomorphism_ok = @catmath.is_homeomorphism(tt, tt, identity)
  let open_sets_supported = tt.n <= 16
  let mut open_set_count = 0
  let mut open_sets_ok = false
  if open_sets_supported {
    let opens = @catmath.open_sets(tt)
    open_set_count = opens.length()
    let total = match federation_pow2_checked(tt.n) {
      Some(total) => total
      None => return invalid_finite_topology_report(tt)
    }
    let mut counted = 0
    let mut complements_closed = true
    for mask in 0..<total {
      let subset = Array::makei(tt.n, fn(x) { federation_bit(mask, x) })
      if @catmath.is_open(tt, subset) {
        counted = counted + 1
        let complement = Array::makei(tt.n, fn(x) { !subset[x] })
        if !@catmath.is_closed(tt, complement) {
          complements_closed = false
        }
      }
    }
    open_sets_ok = counted == open_set_count && complements_closed
  }
  let valid = preorder_ok &&
    semiring_closure_ok &&
    thin_category_ok &&
    t0_skeleton_ok &&
    components_ok &&
    identity_homeomorphism_ok &&
    (!open_sets_supported || open_sets_ok)
  {
    valid,
    n_points: tt.n,
    relation_count,
    t0,
    t0_quotient_points: t0_quotient.n,
    component_count: federation_unique_count(catmath_components),
    open_set_count,
    adjacency_charpoly: category_report.hom_count_charpoly,
    preorder_ok,
    semiring_closure_ok,
    thin_category_ok,
    t0_skeleton_ok,
    components_ok,
    identity_homeomorphism_ok,
    open_sets_supported,
    open_sets_ok,
  }
}

///|
/// Whether all applicable finite-topology translations commute.
pub fn check_finite_topology_federation(tt : @catmath.FinTop) -> Bool {
  finite_topology_federation_report(tt).valid
}

///|
/// The finite Alexandrov space underlying a finalg spectrum.
///
/// This is the transpose of finalg's inclusion matrix:
/// `le[x][y] = (P_y ⊆ P_x)`, because `x ≤ y` in the
/// specialization preorder means `x ∈ closure({y}) = V(P_y)`.
pub fn finalg_spec_to_catmath_fintop(
  spectrum : @fscheme.Spec,
) -> @catmath.FinTop {
  let n = spectrum.primes.length()
  let le : Array[Array[Bool]] = []
  for x in 0..<n {
    let row : Array[Bool] = []
    for y in 0..<n {
      row.push(spectrum.is_le(y, x))
    }
    le.push(row)
  }
  @catmath.make_top(n, le)
}

///|
fn federation_power_at_most(base : Int32, exp : Int32, cap : Int32) -> Bool {
  guard base >= 0 && exp >= 0 && cap >= 1 else { return false }
  let mut acc = 1
  for _i in 0..<exp {
    // Both factors are non-negative; test before multiplying so
    // the smallness guard itself cannot overflow Int32.
    if base != 0 && acc > cap / base {
      return false
    }
    acc = acc * base
  }
  acc <= cap
}

///|
fn federation_preorder_height(le : Array[Array[Bool]]) -> Int32 {
  let n = le.length()
  if n == 0 {
    return -1
  }
  let dist = Array::make(n, 0)
  for _step in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        if le[i][j] && !le[j][i] && dist[i] + 1 > dist[j] {
          dist[j] = dist[i] + 1
        }
      }
    }
  }
  let mut best = 0
  for d in dist {
    if d > best {
      best = d
    }
  }
  best
}

///|
/// Cross-member report for the spectrum of a finite finalg
/// algebra, read as a catmath finite topology.
pub(all) struct FiniteSpecFederationReport {
  valid : Bool
  prime_count : Int32
  open_count : Int32
  component_count : Int32
  block_count : Int32
  irreducible_component_count : Int32
  dimension : Int32
  topology_ok : Bool
  opens_supported : Bool
  opens_ok : Bool
  dimension_ok : Bool
  blocks_supported : Bool
  blocks_ok : Bool
}

///|
/// Build the finite-Spec report.  The mask-by-mask open-family
/// comparison and the block decomposition enumerate elements of
/// the finite algebra, so they are marked fragments guarded by a
/// small `p^dim` bound; the specialization-preorder and dimension
/// clauses do not depend on that enumeration.
pub fn finite_spec_federation_report(
  alg : @ffinite.FinAlg,
) -> FiniteSpecFederationReport {
  let spectrum = @fscheme.spec(alg)
  let top = finalg_spec_to_catmath_fintop(spectrum)
  let topology = finite_topology_federation_report(top)
  let n = spectrum.primes.length()
  let opens_supported = n <= 16 &&
    federation_power_at_most(alg.p, alg.dim, 4096)
  let mut open_count = 0
  let mut opens_ok = false
  if opens_supported {
    let seen = spectrum.opens()
    let total = match federation_pow2_checked(n) {
      Some(total) => total
      None => 0
    }
    opens_ok = seen.length() == total
    for mask in 0..<total {
      if seen[mask] {
        open_count = open_count + 1
      }
      let subset = Array::makei(n, fn(x) { federation_bit(mask, x) })
      if @catmath.is_open(top, subset) != seen[mask] {
        opens_ok = false
      }
    }
    opens_ok = opens_ok && open_count == topology.open_set_count
  }
  let dimension = spectrum.dimension()
  let dimension_ok = dimension == federation_preorder_height(top.le)
  let blocks_supported = opens_supported && n > 0
  let mut block_count = 0
  let mut blocks_ok = false
  if blocks_supported {
    block_count = @ffinite.decompose_blocks(alg).length()
    blocks_ok = block_count == topology.component_count
  }
  let valid = topology.valid &&
    dimension_ok &&
    (!opens_supported || opens_ok) &&
    (!blocks_supported || blocks_ok)
  {
    valid,
    prime_count: n,
    open_count,
    component_count: topology.component_count,
    block_count,
    irreducible_component_count: spectrum.irreducible_components().length(),
    dimension,
    topology_ok: topology.valid,
    opens_supported,
    opens_ok,
    dimension_ok,
    blocks_supported,
    blocks_ok,
  }
}

///|
/// Whether the finite spectrum and its Alexandrov topology agree
/// in every applicable clause above.
pub fn check_finite_spec_federation(alg : @ffinite.FinAlg) -> Bool {
  finite_spec_federation_report(alg).valid
}
