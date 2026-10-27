///|
/// Derived finite-structure reports for the direct 3+2 federation.
///
/// The reports in this file do not identify the member
/// representations with one another.  They state only the commuting
/// diagrams that are valid after the explicitly documented finite
/// translations:
///
/// * a finite category table may be read in symlib, catmath and
///   finalg/cat; its object graph may then be decategorified to a
///   Boolean reachability problem and to an exact rational
///   Hom-count matrix;
/// * a finite Cayley table may be Cayley-embedded as permutations,
///   delooped as a one-object category (when catmath's constructor
///   convention `e = 0` is met), represented by finalg finite
///   equivalences, and averaged to the exact rank-one projector of
///   the regular representation;
/// * a finite G-set may be read by symlib's table algorithms,
///   whose Burnside count and orbit partition must agree with
///   catmath, with Boolean orbit closure, and with the rank of the
///   averaged permutation representation.
///
/// Keeping those side conditions in the report is the point: a
/// failed or unsupported translation is reported as such rather
/// than being silently promoted to an equivalence.

///|
fn federation_sorted_copy(xs : Array[Int32]) -> Array[Int32] {
  let out = xs.copy()
  out.sort()
  out
}

///|
fn federation_unique_count(labels : Array[Int32]) -> Int32 {
  let seen : Array[Int32] = []
  for label in labels {
    let mut found = false
    for old in seen {
      if old == label {
        found = true
      }
    }
    if !found {
      seen.push(label)
    }
  }
  seen.length()
}

///|
fn federation_same_partition(a : Array[Int32], b : Array[Int32]) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    for j in 0..<a.length() {
      guard (a[i] == a[j]) == (b[i] == b[j]) else { return false }
    }
  }
  true
}

///|
fn federation_partition_labels(
  blocks : Array[Array[Int32]],
  n : Int32,
) -> Array[Int32] {
  let labels = Array::make(n, -1)
  for block_index in 0..<blocks.length() {
    for x in blocks[block_index] {
      if x >= 0 && x < n {
        labels[x] = block_index
      }
    }
  }
  labels
}

///|
fn federation_bool_closure(
  adjacency : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = adjacency.length()
  for row in adjacency {
    guard row.length() == n else { return None }
  }
  let matrix : @smat.Mat[@semialg.BoolSr] = @smat.Mat::new(
    n,
    n,
    @semialg.BoolSr::of(false),
  )
  for i in 0..<n {
    for j in 0..<n {
      matrix.set(i, j, @semialg.BoolSr::of(adjacency[i][j]))
    }
  }
  let closed = @smat.closure_fw_inplace(matrix)
  let out : Array[Array[Bool]] = []
  for i in 0..<n {
    let row : Array[Bool] = []
    for j in 0..<n {
      row.push(closed.get(i, j).is_one())
    }
    out.push(row)
  }
  Some(out)
}

///|
fn federation_closure_partition_labels(
  adjacency : Array[Array[Bool]],
) -> Array[Int32]? {
  let n = adjacency.length()
  let symmetric : Array[Array[Bool]] = []
  for i in 0..<n {
    guard adjacency[i].length() == n else { return None }
    let row : Array[Bool] = []
    for j in 0..<n {
      row.push(adjacency[i][j] || adjacency[j][i] || i == j)
    }
    symmetric.push(row)
  }
  let closed = match federation_bool_closure(symmetric) {
    Some(closed) => closed
    None => return None
  }
  let labels = Array::make(n, -1)
  let mut next_label = 0
  for i in 0..<n {
    if labels[i] < 0 {
      for j in 0..<n {
        if closed[i][j] {
          labels[j] = next_label
        }
      }
      next_label = next_label + 1
    }
  }
  Some(labels)
}

///|
/// Cross-member report for one finite table category.
pub(all) struct FiniteCategoryFederationReport {
  valid : Bool
  n_objects : Int32
  n_morphisms : Int32
  iso_class_count : Int32
  skeleton_object_count : Int32
  underlying_component_count : Int32
  hom_count_matrix : Array[Array[Int32]]
  directed_reachability : Array[Array[Bool]]
  hom_count_charpoly : @exactalg.QPoly
  catmath_laws_ok : Bool
  finalg_laws_ok : Bool
  hom_counts_ok : Bool
  skeleton_ok : Bool
  reachability_ok : Bool
  components_ok : Bool
}

///|
fn invalid_finite_category_report(
  n_objects : Int32,
  n_morphisms : Int32,
) -> FiniteCategoryFederationReport {
  {
    valid: false,
    n_objects,
    n_morphisms,
    iso_class_count: 0,
    skeleton_object_count: 0,
    underlying_component_count: 0,
    hom_count_matrix: [],
    directed_reachability: [],
    hom_count_charpoly: @exactalg.qpoly_zero(),
    catmath_laws_ok: false,
    finalg_laws_ok: false,
    hom_counts_ok: false,
    skeleton_ok: false,
    reachability_ok: false,
    components_ok: false,
  }
}

///|
/// Build the five-member finite-category report.
///
/// The directed-reachability clause is the finite form of the
/// elementary theorem that, in a category, a directed path in the
/// underlying object graph exists exactly when the corresponding
/// Hom-set is non-empty: paths compose, and identities account for
/// the reflexive diagonal.  The undirected clause instead compares
/// finalg/cat's graph components with the symmetric Boolean
/// closure.  The Hom-count characteristic polynomial is an exact
/// decategorified invariant, not a claim that matrix similarity
/// classifies categories.
pub fn finite_category_federation_report(
  c : @sym.FinCat,
) -> FiniteCategoryFederationReport {
  let catmath_category = match fincat_to_catmath_category(c) {
    Some(category) => category
    None => return invalid_finite_category_report(c.nobj, c.nmor)
  }
  let n = c.nobj
  let hom_counts = Array::makei(n, fn(_i) { Array::make(n, 0) })
  for mor in 0..<c.nmor {
    let i = c.dom[mor]
    let j = c.cod[mor]
    hom_counts[i][j] = hom_counts[i][j] + 1
  }
  let mut hom_counts_ok = true
  for i in 0..<n {
    for j in 0..<n {
      if @catmath.hom(catmath_category, i, j).length() != hom_counts[i][j] {
        hom_counts_ok = false
      }
    }
  }
  let directed_adjacency : Array[Array[Bool]] = []
  let undirected_adjacency : Array[Array[Bool]] = []
  for i in 0..<n {
    let directed_row : Array[Bool] = []
    let undirected_row : Array[Bool] = []
    for j in 0..<n {
      directed_row.push(hom_counts[i][j] > 0)
      undirected_row.push(hom_counts[i][j] > 0 || hom_counts[j][i] > 0)
    }
    directed_adjacency.push(directed_row)
    undirected_adjacency.push(undirected_row)
  }
  let directed_reachability = match
    federation_bool_closure(directed_adjacency) {
    Some(closed) => closed
    None => return invalid_finite_category_report(c.nobj, c.nmor)
  }
  let mut reachability_ok = true
  for i in 0..<n {
    for j in 0..<n {
      if directed_reachability[i][j] != (hom_counts[i][j] > 0) {
        reachability_ok = false
      }
    }
  }
  let edges : Array[(Int32, Int32)] = []
  for mor in 0..<c.nmor {
    edges.push((c.dom[mor], c.cod[mor]))
  }
  let finalg_labels = @fcat.graph_components(@fcat.Graph::{ n, edges, })
  let semiring_labels = match
    federation_closure_partition_labels(undirected_adjacency) {
    Some(labels) => labels
    None => return invalid_finite_category_report(c.nobj, c.nmor)
  }
  let mut components_ok = finalg_labels.length() == n &&
    federation_same_partition(finalg_labels, semiring_labels)
  for label in finalg_labels {
    if label < 0 {
      components_ok = false
    }
  }
  let iso_labels = @catmath.iso_classes(catmath_category)
  let skeleton = @catmath.category_skeleton(catmath_category)
  let iso_class_count = if iso_labels.length() == n {
    federation_unique_count(iso_labels)
  } else {
    0
  }
  let skeleton_ok = iso_labels.length() == n &&
    skeleton.n_obj == iso_class_count &&
    @catmath.check_laws(skeleton)
  let catmath_laws_ok = @catmath.check_laws(catmath_category)
  let finalg_laws_ok = fincat_finalg_category_laws(c)
  let hom_count_charpoly = if n == 0 {
    @exactalg.qpoly_one()
  } else {
    @exactalg.qmat_charpoly(@exactalg.qmat_from_int_rows(hom_counts))
  }
  let valid = catmath_laws_ok &&
    finalg_laws_ok &&
    hom_counts_ok &&
    skeleton_ok &&
    reachability_ok &&
    components_ok
  {
    valid,
    n_objects: n,
    n_morphisms: c.nmor,
    iso_class_count,
    skeleton_object_count: skeleton.n_obj,
    underlying_component_count: federation_unique_count(finalg_labels),
    hom_count_matrix: hom_counts,
    directed_reachability,
    hom_count_charpoly,
    catmath_laws_ok,
    finalg_laws_ok,
    hom_counts_ok,
    skeleton_ok,
    reachability_ok,
    components_ok,
  }
}

///|
/// Whether the finite-category translations above all commute on
/// the given table.
pub fn check_finite_category_federation(c : @sym.FinCat) -> Bool {
  finite_category_federation_report(c).valid
}

///|
fn federation_average_perm_projector(
  images : Array[Array[Int32]],
  n : Int32,
) -> (Int32, Bool) {
  guard n >= 0 && images.length() > 0 else { return (0, n == 0) }
  for image in images {
    guard image.length() == n else { return (0, false) }
    for y in image {
      guard y >= 0 && y < n else { return (0, false) }
    }
  }
  if n == 0 {
    return (0, true)
  }
  let counts = Array::makei(n, fn(_i) { Array::make(n, 0) })
  for image in images {
    for x in 0..<n {
      let y = image[x]
      counts[y][x] = counts[y][x] + 1
    }
  }
  let rows : Array[Array[@exactalg.Rat]] = []
  for y in 0..<n {
    let row : Array[@exactalg.Rat] = []
    for x in 0..<n {
      row.push(@exactalg.rat_make(counts[y][x], images.length()))
    }
    rows.push(row)
  }
  let projector = @exactalg.qmat_from_rows(rows)
  (
    @exactalg.qmat_rank(projector),
    @exactalg.qmat_eq(@exactalg.qmat_mul(projector, projector), projector),
  )
}

///|
/// Cross-member report for one finite Cayley table.
pub(all) struct FiniteGroupFederationReport {
  valid : Bool
  order : Int32
  center_size : Int32
  conjugacy_class_count : Int32
  abelianization_order : Int32
  abelianization_invariants : Array[Int32]
  regular_projector_rank : Int32
  catmath_group_ok : Bool
  cayley_embedding_ok : Bool
  regular_action_ok : Bool
  finalg_equiv_ok : Bool
  projector_ok : Bool
  /// catmath's `group_as_category` and `abelianization` use the
  /// label convention `e = 0`; this records that side condition.
  zero_identity_supported : Bool
  delooping_ok : Bool
  abelianization_ok : Bool
}

///|
fn invalid_finite_group_report(order : Int32) -> FiniteGroupFederationReport {
  {
    valid: false,
    order,
    center_size: 0,
    conjugacy_class_count: 0,
    abelianization_order: 0,
    abelianization_invariants: [],
    regular_projector_rank: 0,
    catmath_group_ok: false,
    cayley_embedding_ok: false,
    regular_action_ok: false,
    finalg_equiv_ok: false,
    projector_ok: false,
    zero_identity_supported: false,
    delooping_ok: false,
    abelianization_ok: false,
  }
}

///|
/// Build the finite-group commuting diagram.
///
/// `cap` bounds the explicit symlib element enumeration used by
/// the delooping comparison.  The Cayley-homomorphism clause is
/// checked with the original labels, before any enumeration order
/// is chosen.  The exact projector clause is Maschke averaging for
/// the regular representation: averaging all left translations
/// gives the constant matrix divided by `|G|`, hence an idempotent
/// of rank one.
pub fn finite_group_federation_report(
  g : @catmath.FinGroup,
  cap : Int32,
) -> FiniteGroupFederationReport {
  guard fin_group_shape_ok(g) && cap >= g.order else {
    return invalid_finite_group_report(g.order)
  }
  let catmath_group_ok = @catmath.check_group(g)
  guard catmath_group_ok else { return invalid_finite_group_report(g.order) }
  let embedded = match catmath_fin_group_to_symlib_perm_group(g) {
    Some(group) => group
    None => return invalid_finite_group_report(g.order)
  }
  let left_images : Array[Array[Int32]] = []
  let left_perms : Array[@sym.Perm] = []
  for a in 0..<g.order {
    let image : Array[Int32] = []
    for x in 0..<g.order {
      image.push(g.mul[a][x])
    }
    left_images.push(image)
    left_perms.push(@sym.Perm::from_img(image))
  }
  let mut cayley_embedding_ok = embedded.order() == g.order.to_int64()
  for a in 0..<g.order {
    if !embedded.contains(left_perms[a]) {
      cayley_embedding_ok = false
    }
    for b in 0..<g.order {
      if !left_perms[a].compose(left_perms[b]).equal(left_perms[g.mul[a][b]]) {
        cayley_embedding_ok = false
      }
    }
  }
  let regular_action_ok = embedded.is_transitive() &&
    embedded.stabilizer(0).order() == 1L
  let elements = Array::makei(g.order, fn(i) { i })
  let mut finalg_equiv_ok = true
  for a in 0..<g.order {
    let equiv : @fhott.Equiv[Int32, Int32] = @fhott.Equiv::{
      fwd: fn(x : Int32) { g.mul[a][x] },
      bwd: fn(x : Int32) { g.mul[g.inv[a]][x] },
    }
    if !@fhott.Equiv::is_equiv_finite(
        equiv,
        fn(x : Int32, y : Int32) { x == y },
        fn(x : Int32, y : Int32) { x == y },
        elements,
        elements,
      ) {
      finalg_equiv_ok = false
    }
  }
  let (projector_rank, projector_idempotent) = federation_average_perm_projector(
    left_images,
    g.order,
  )
  let projector_ok = projector_idempotent && projector_rank == 1
  let zero_identity_supported = g.e == 0
  let mut delooping_ok = false
  let mut abelianization_order = 0
  let mut abelianization_invariants : Array[Int32] = []
  let mut abelianization_ok = false
  if zero_identity_supported {
    let delooped_table = @catmath.group_as_category(g)
    let catmath_deloop_ok = match catmath_category_to_fincat(delooped_table) {
      Some(table) => finite_category_federation_report(table).valid
      None => false
    }
    let symlib_deloop = @sym.cat_group(embedded, cap)
    let symlib_deloop_ok = finite_category_federation_report(symlib_deloop).valid &&
      symlib_deloop.nobj == 1 &&
      symlib_deloop.nmor == g.order
    delooping_ok = catmath_deloop_ok && symlib_deloop_ok
    let abelianized = @catmath.abelianization(g)
    abelianization_order = abelianized.order
    abelianization_invariants = @catmath.abelian_invariant_factors(abelianized)
    let mut invariant_product = 1
    for factor in abelianization_invariants {
      invariant_product = invariant_product * factor
    }
    abelianization_ok = @catmath.check_group(abelianized) &&
      @catmath.center(abelianized).length() == abelianization_order &&
      invariant_product == abelianization_order
  }
  let valid = cayley_embedding_ok &&
    regular_action_ok &&
    finalg_equiv_ok &&
    projector_ok &&
    (!zero_identity_supported || (delooping_ok && abelianization_ok))
  {
    valid,
    order: g.order,
    center_size: @catmath.center(g).length(),
    conjugacy_class_count: @catmath.conjugacy_classes(g).length(),
    abelianization_order,
    abelianization_invariants,
    regular_projector_rank: projector_rank,
    catmath_group_ok,
    cayley_embedding_ok,
    regular_action_ok,
    finalg_equiv_ok,
    projector_ok,
    zero_identity_supported,
    delooping_ok,
    abelianization_ok,
  }
}

///|
/// Whether all applicable finite-group translations commute.  The
/// report itself records whether catmath's `e = 0` constructor
/// fragments were applicable.
pub fn check_finite_group_federation(
  g : @catmath.FinGroup,
  cap : Int32,
) -> Bool {
  finite_group_federation_report(g, cap).valid
}

///|
fn catmath_gset_shape_ok(gx : @catmath.GSet) -> Bool {
  guard fin_group_shape_ok(gx.group) else { return false }
  guard gx.elements >= 0 else { return false }
  guard gx.action.length() == gx.group.order else { return false }
  for row in gx.action {
    guard row.length() == gx.elements else { return false }
    for y in row {
      guard y >= 0 && y < gx.elements else { return false }
    }
  }
  true
}

///|
/// Read a catmath finite G-set as symlib's table G-set.  symlib's
/// orbit and Burnside algorithms use only the set of permutation
/// rows, so no relabelling of group elements is hidden here.
pub fn catmath_gset_to_symlib_gsetof(gx : @catmath.GSet) -> @sym.GSetOf? {
  guard catmath_gset_shape_ok(gx) else { return None }
  guard @catmath.check_group(gx.group) && @catmath.check_gset(gx) else {
    return None
  }
  let imgs : Array[Array[Int32]] = []
  for row in gx.action {
    imgs.push(row.copy())
  }
  Some(@sym.GSetOf::{ x: gx.elements, imgs, })
}

///|
/// Read a symlib table G-set as a catmath G-set, under the explicit
/// premise that `gs.imgs[i]` is the action of
/// `group.elements(cap)[i]` (as produced by `gset_from_action`).
/// The resulting table is rechecked by catmath's own G-set axiom
/// checker in that same element order.
pub fn symlib_gsetof_to_catmath_gset_with_element_order(
  gs : @sym.GSetOf,
  group : @sym.PermGroup,
  cap : Int32,
) -> @catmath.GSet? {
  guard gs.x >= 0 else { return None }
  for row in gs.imgs {
    guard row.length() == gs.x else { return None }
    for y in row {
      guard y >= 0 && y < gs.x else { return None }
    }
  }
  let table = match symlib_perm_group_to_catmath_fin_group(group, cap) {
    Some(table) => table
    None => return None
  }
  guard gs.imgs.length() == table.order else { return None }
  let action : Array[Array[Int32]] = []
  for row in gs.imgs {
    action.push(row.copy())
  }
  let gx = @catmath.gset_of(table, gs.x, action)
  guard @catmath.check_gset(gx) else { return None }
  Some(gx)
}

///|
/// Cross-member report for one finite G-set.
pub(all) struct FiniteGSetFederationReport {
  valid : Bool
  group_order : Int32
  set_size : Int32
  orbit_count : Int32
  orbit_sizes : Array[Int32]
  burnside_average : Int32
  averaged_projector_rank : Int32
  transitive : Bool
  catmath_action_ok : Bool
  symlib_orbits_ok : Bool
  burnside_ok : Bool
  semiring_orbit_closure_ok : Bool
  finalg_equiv_ok : Bool
  projector_ok : Bool
}

///|
fn invalid_finite_gset_report(
  group_order : Int32,
  set_size : Int32,
) -> FiniteGSetFederationReport {
  {
    valid: false,
    group_order,
    set_size,
    orbit_count: 0,
    orbit_sizes: [],
    burnside_average: 0,
    averaged_projector_rank: 0,
    transitive: false,
    catmath_action_ok: false,
    symlib_orbits_ok: false,
    burnside_ok: false,
    semiring_orbit_closure_ok: false,
    finalg_equiv_ok: false,
    projector_ok: false,
  }
}

///|
/// Build the finite G-set commuting diagram: catmath's action
/// axioms and orbits, symlib's independent orbit/Burnside engine,
/// the Boolean closure of the action graph, finalg finite
/// equivalences for every group element, and the standard theorem
/// that the averaged permutation representation projects exactly
/// to orbit-constant vectors (rank = number of orbits).
pub fn finite_gset_federation_report(
  gx : @catmath.GSet,
) -> FiniteGSetFederationReport {
  let symlib_gset = match catmath_gset_to_symlib_gsetof(gx) {
    Some(gs) => gs
    None => return invalid_finite_gset_report(gx.group.order, gx.elements)
  }
  let catmath_orbits = @catmath.gset_orbits(gx)
  let symlib_orbits = @sym.gset_orbits(symlib_gset)
  let catmath_labels = federation_partition_labels(catmath_orbits, gx.elements)
  let symlib_labels = federation_partition_labels(symlib_orbits, gx.elements)
  let symlib_orbits_ok = catmath_orbits.length() == symlib_orbits.length() &&
    federation_same_partition(catmath_labels, symlib_labels)
  let catmath_sizes : Array[Int32] = []
  for orbit in catmath_orbits {
    catmath_sizes.push(orbit.length())
  }
  let orbit_sizes = federation_sorted_copy(catmath_sizes)
  let (burnside_orbits, burnside_average) = @sym.gset_burnside(symlib_gset)
  let burnside_ok = burnside_orbits == catmath_orbits.length() &&
    burnside_average == catmath_orbits.length()
  let action_adjacency = Array::makei(gx.elements, fn(_i) {
    Array::make(gx.elements, false)
  })
  for row in gx.action {
    for x in 0..<gx.elements {
      action_adjacency[x][row[x]] = true
    }
  }
  let closure_labels = match
    federation_closure_partition_labels(action_adjacency) {
    Some(labels) => labels
    None => return invalid_finite_gset_report(gx.group.order, gx.elements)
  }
  let semiring_orbit_closure_ok = federation_same_partition(
    catmath_labels, closure_labels,
  )
  let points = Array::makei(gx.elements, fn(i) { i })
  let mut finalg_equiv_ok = true
  for a in 0..<gx.group.order {
    let inverse = gx.group.inv[a]
    let equiv : @fhott.Equiv[Int32, Int32] = @fhott.Equiv::{
      fwd: fn(x : Int32) { gx.action[a][x] },
      bwd: fn(x : Int32) { gx.action[inverse][x] },
    }
    if !@fhott.Equiv::is_equiv_finite(
        equiv,
        fn(x : Int32, y : Int32) { x == y },
        fn(x : Int32, y : Int32) { x == y },
        points,
        points,
      ) {
      finalg_equiv_ok = false
    }
  }
  let (projector_rank, projector_idempotent) = federation_average_perm_projector(
    gx.action,
    gx.elements,
  )
  let projector_ok = projector_idempotent &&
    projector_rank == catmath_orbits.length()
  let valid = symlib_orbits_ok &&
    burnside_ok &&
    semiring_orbit_closure_ok &&
    finalg_equiv_ok &&
    projector_ok
  {
    valid,
    group_order: gx.group.order,
    set_size: gx.elements,
    orbit_count: catmath_orbits.length(),
    orbit_sizes,
    burnside_average,
    averaged_projector_rank: projector_rank,
    transitive: @catmath.is_transitive(gx),
    catmath_action_ok: true,
    symlib_orbits_ok,
    burnside_ok,
    semiring_orbit_closure_ok,
    finalg_equiv_ok,
    projector_ok,
  }
}

///|
/// Whether every finite G-set translation above commutes.
pub fn check_finite_gset_federation(gx : @catmath.GSet) -> Bool {
  finite_gset_federation_report(gx).valid
}
