///|
/// The finite Heyting algebra of observable predicates on a
/// finite Alexandrov space.
///
/// The logical role used here is deliberately the finite,
/// executable shadow of a standard categorical fact: in a topos,
/// subobjects of an object form a Heyting algebra, and for a
/// topological space the opens form a complete Heyting algebra
/// with implication `U ⇒ V = int((X \ U) ∪ V)`.  A finite topology
/// is Alexandrov: its opens are the upward-closed sets for the
/// specialization preorder.
///
/// Those opens are also our finite model of *logical*
/// subtyping.  A refinement subtype is an upward-closed
/// (observable) predicate `U`, and `U <: V` means inclusion.
/// Meet and join are intersection and union, while implication
/// is the Heyting residual, not in general Boolean negation.
/// This does not claim that either native STLC has acquired a
/// general subtyping system; it isolates the finite semantic
/// subtype lattice on which such an extension would have to be
/// interpreted.

///|
fn heyting_universe_mask(n : Int32) -> Int32? {
  guard n >= 0 && n <= 16 else { return None }
  let total = match federation_pow2_checked(n) {
    Some(total) => total
    None => return None
  }
  Some(total - 1)
}

///|
fn heyting_mask_valid(tt : @catmath.FinTop, mask : Int32) -> Bool {
  guard fintop_shape_ok(tt) else { return false }
  match heyting_universe_mask(tt.n) {
    Some(universe) => mask >= 0 && mask <= universe
    None => false
  }
}

///|
fn heyting_subset(a : Int32, b : Int32) -> Bool {
  (a & b) == a
}

///|
fn heyting_mask_to_bools(n : Int32, mask : Int32) -> Array[Bool] {
  Array::makei(n, fn(x) { federation_bit(mask, x) })
}

///|
fn heyting_bools_to_mask(row : Array[Bool]) -> Int32? {
  guard row.length() <= 16 else { return None }
  let mut mask = 0
  for x in 0..<row.length() {
    if row[x] {
      mask = mask | (1 << x)
    }
  }
  Some(mask)
}

///|
fn heyting_is_open_mask(tt : @catmath.FinTop, mask : Int32) -> Bool {
  guard heyting_mask_valid(tt, mask) else { return false }
  for x in 0..<tt.n {
    if federation_bit(mask, x) {
      for y in 0..<tt.n {
        if tt.le[x][y] && !federation_bit(mask, y) {
          return false
        }
      }
    }
  }
  true
}

///|
/// All open subsets of a small finite topology, as bit masks in
/// increasing mask order.  This is the carrier of the finite
/// Heyting algebra and of the observable refinement-subtype
/// lattice.  Enumeration is exponential; the public fragment is
/// bounded to sixteen points.
pub fn fintop_open_masks(tt : @catmath.FinTop) -> Array[Int32]? {
  guard fintop_shape_ok(tt) && @catmath.check_preorder(tt) else { return None }
  let total = match federation_pow2_checked(tt.n) {
    Some(total) => total
    None => return None
  }
  guard tt.n <= 16 else { return None }
  let opens : Array[Int32] = []
  for mask in 0..<total {
    if heyting_is_open_mask(tt, mask) {
      opens.push(mask)
    }
  }
  Some(opens)
}

///|
/// Interior of an arbitrary small subset, computed directly as
/// `{x | ↑x ⊆ S}`.  In an Alexandrov space this is the largest
/// open subset of `S`; the report below compares it mask by mask
/// with catmath's closure-complement interior.
pub fn fintop_interior_mask(tt : @catmath.FinTop, mask : Int32) -> Int32? {
  guard heyting_mask_valid(tt, mask) && @catmath.check_preorder(tt) else {
    return None
  }
  let mut interior = 0
  for x in 0..<tt.n {
    let mut principal_upset_inside = true
    for y in 0..<tt.n {
      if tt.le[x][y] && !federation_bit(mask, y) {
        principal_upset_inside = false
      }
    }
    if principal_upset_inside {
      interior = interior | (1 << x)
    }
  }
  Some(interior)
}

///|
/// Semantic subtyping for open refinement predicates:
/// `subtype <: supertype` exactly when both masks are open and
/// the first is included in the second.
pub fn fintop_open_subtype_of(
  tt : @catmath.FinTop,
  subtype : Int32,
  supertype : Int32,
) -> Bool {
  heyting_is_open_mask(tt, subtype) &&
  heyting_is_open_mask(tt, supertype) &&
  heyting_subset(subtype, supertype)
}

///|
/// Meet of two open refinement subtypes.
pub fn fintop_heyting_meet(
  tt : @catmath.FinTop,
  a : Int32,
  b : Int32,
) -> Int32? {
  guard heyting_is_open_mask(tt, a) && heyting_is_open_mask(tt, b) else {
    return None
  }
  Some(a & b)
}

///|
/// Join of two open refinement subtypes.
pub fn fintop_heyting_join(
  tt : @catmath.FinTop,
  a : Int32,
  b : Int32,
) -> Int32? {
  guard heyting_is_open_mask(tt, a) && heyting_is_open_mask(tt, b) else {
    return None
  }
  Some(a | b)
}

///|
/// Heyting implication `a ⇒ b = int((X \ a) ∪ b)` for opens.
/// It is the largest open `w` with `w ∩ a ⊆ b`; the report
/// checks both the formula and that universal property.
pub fn fintop_heyting_implication(
  tt : @catmath.FinTop,
  antecedent : Int32,
  consequent : Int32,
) -> Int32? {
  guard heyting_is_open_mask(tt, antecedent) &&
    heyting_is_open_mask(tt, consequent) else {
    return None
  }
  let universe = match heyting_universe_mask(tt.n) {
    Some(universe) => universe
    None => return None
  }
  fintop_interior_mask(tt, (universe ^ antecedent) | consequent)
}

///|
/// Pseudocomplement `¬a = a ⇒ ∅`, the largest open disjoint
/// from `a`.  It need not be the set-theoretic complement.
pub fn fintop_heyting_negation(tt : @catmath.FinTop, a : Int32) -> Int32? {
  fintop_heyting_implication(tt, a, 0)
}

///|
/// Cross-member report for the finite Heyting algebra of opens.
///
/// The exhaustive subtype/implication clauses are cubic in the
/// number of opens, so the complete report is marked supported
/// only for at most twelve points and at most 64 opens.  The
/// pointwise operations above remain available up to sixteen
/// points.
pub(all) struct FiniteHeytingTopologyReport {
  valid : Bool
  supported : Bool
  n_points : Int32
  universe_mask : Int32
  open_masks : Array[Int32]
  open_count : Int32
  boolean : Bool
  complemented_open_count : Int32
  regular_open_count : Int32
  topology_bridge_ok : Bool
  semiring_closure_ok : Bool
  catmath_open_sets_ok : Bool
  interior_ok : Bool
  lattice_ok : Bool
  subtype_bounds_ok : Bool
  implication_formula_ok : Bool
  adjunction_ok : Bool
  modus_ponens_ok : Bool
  pseudocomplement_ok : Bool
  boolean_characterization_ok : Bool
}

///|
fn invalid_finite_heyting_report(
  tt : @catmath.FinTop,
) -> FiniteHeytingTopologyReport {
  {
    valid: false,
    supported: false,
    n_points: tt.n,
    universe_mask: 0,
    open_masks: [],
    open_count: 0,
    boolean: false,
    complemented_open_count: 0,
    regular_open_count: 0,
    topology_bridge_ok: false,
    semiring_closure_ok: false,
    catmath_open_sets_ok: false,
    interior_ok: false,
    lattice_ok: false,
    subtype_bounds_ok: false,
    implication_formula_ok: false,
    adjunction_ok: false,
    modus_ponens_ok: false,
    pseudocomplement_ok: false,
    boolean_characterization_ok: false,
  }
}

///|
/// Build and exhaustively verify the finite Heyting report.
pub fn finite_heyting_topology_report(
  tt : @catmath.FinTop,
) -> FiniteHeytingTopologyReport {
  guard fintop_shape_ok(tt) && @catmath.check_preorder(tt) else {
    return invalid_finite_heyting_report(tt)
  }
  let universe = match heyting_universe_mask(tt.n) {
    Some(universe) => universe
    None => return invalid_finite_heyting_report(tt)
  }
  let opens = match fintop_open_masks(tt) {
    Some(opens) => opens
    None => return invalid_finite_heyting_report(tt)
  }
  let topology = finite_topology_federation_report(tt)
  let closure = match federation_bool_closure(tt.le) {
    Some(closure) => closure
    None => return invalid_finite_heyting_report(tt)
  }
  let semiring_closure_ok = bool_matrices_equal(closure, tt.le)
  let supported = tt.n <= 12 && opens.length() <= 64

  let catmath_masks : Array[Int32] = []
  let mut catmath_open_sets_ok = true
  for row in @catmath.open_sets(tt) {
    match heyting_bools_to_mask(row) {
      Some(mask) => catmath_masks.push(mask)
      None => catmath_open_sets_ok = false
    }
  }
  catmath_open_sets_ok = catmath_open_sets_ok &&
    int_arrays_equal(catmath_masks, opens) &&
    opens.length() == topology.open_set_count

  let total = match federation_pow2_checked(tt.n) {
    Some(total) => total
    None => return invalid_finite_heyting_report(tt)
  }
  let mut interior_ok = true
  for mask in 0..<total {
    let direct = match fintop_interior_mask(tt, mask) {
      Some(direct) => direct
      None => return invalid_finite_heyting_report(tt)
    }
    let native_row = @catmath.interior(tt, heyting_mask_to_bools(tt.n, mask))
    let native = match heyting_bools_to_mask(native_row) {
      Some(native) => native
      None => return invalid_finite_heyting_report(tt)
    }
    if direct != native ||
      !heyting_is_open_mask(tt, direct) ||
      !heyting_subset(direct, mask) {
      interior_ok = false
    }
    // Interior is greatest: every open below the subset is below it.
    for open in opens {
      if heyting_subset(open, mask) && !heyting_subset(open, direct) {
        interior_ok = false
      }
    }
  }

  let mut lattice_ok = true
  let mut subtype_bounds_ok = true
  let mut implication_formula_ok = true
  let mut adjunction_ok = true
  let mut modus_ponens_ok = true
  let mut pseudocomplement_ok = true
  if supported {
    for a in opens {
      for b in opens {
        if !heyting_is_open_mask(tt, a & b) || !heyting_is_open_mask(tt, a | b) {
          lattice_ok = false
        }
        let implication = match fintop_heyting_implication(tt, a, b) {
          Some(implication) => implication
          None => return invalid_finite_heyting_report(tt)
        }
        if !heyting_subset(a & implication, b) {
          modus_ponens_ok = false
        }
        // The implication is also the union of all opens whose
        // meet with `a` is below `b`.
        let mut greatest = 0
        for w in opens {
          if heyting_subset(w & a, b) {
            greatest = greatest | w
          }
        }
        if greatest != implication {
          implication_formula_ok = false
        }
        for w in opens {
          if heyting_subset(w, a & b) !=
            (heyting_subset(w, a) && heyting_subset(w, b)) {
            subtype_bounds_ok = false
          }
          if heyting_subset(a | b, w) !=
            (heyting_subset(a, w) && heyting_subset(b, w)) {
            subtype_bounds_ok = false
          }
          if heyting_subset(w & a, b) != heyting_subset(w, implication) {
            adjunction_ok = false
          }
        }
      }
      let negation = match fintop_heyting_negation(tt, a) {
        Some(negation) => negation
        None => return invalid_finite_heyting_report(tt)
      }
      if (a & negation) != 0 {
        pseudocomplement_ok = false
      }
      for w in opens {
        if (w & a) == 0 && !heyting_subset(w, negation) {
          pseudocomplement_ok = false
        }
      }
    }
  }

  let mut complemented_open_count = 0
  let mut regular_open_count = 0
  for open in opens {
    if heyting_is_open_mask(tt, universe ^ open) {
      complemented_open_count = complemented_open_count + 1
    }
    let negation = match fintop_heyting_negation(tt, open) {
      Some(negation) => negation
      None => return invalid_finite_heyting_report(tt)
    }
    let double_negation = match fintop_heyting_negation(tt, negation) {
      Some(double_negation) => double_negation
      None => return invalid_finite_heyting_report(tt)
    }
    if double_negation == open {
      regular_open_count = regular_open_count + 1
    }
  }
  let boolean = complemented_open_count == opens.length()
  let boolean_characterization_ok = boolean ==
    (regular_open_count == opens.length())
  let valid = supported &&
    topology.valid &&
    semiring_closure_ok &&
    catmath_open_sets_ok &&
    interior_ok &&
    lattice_ok &&
    subtype_bounds_ok &&
    implication_formula_ok &&
    adjunction_ok &&
    modus_ponens_ok &&
    pseudocomplement_ok &&
    boolean_characterization_ok
  {
    valid,
    supported,
    n_points: tt.n,
    universe_mask: universe,
    open_masks: opens,
    open_count: opens.length(),
    boolean,
    complemented_open_count,
    regular_open_count,
    topology_bridge_ok: topology.valid,
    semiring_closure_ok,
    catmath_open_sets_ok,
    interior_ok,
    lattice_ok,
    subtype_bounds_ok,
    implication_formula_ok,
    adjunction_ok,
    modus_ponens_ok,
    pseudocomplement_ok,
    boolean_characterization_ok,
  }
}

///|
/// Whether the finite topology's opens pass every applicable
/// Heyting/subtype clause in the exhaustive report.
pub fn check_finite_heyting_topology(tt : @catmath.FinTop) -> Bool {
  finite_heyting_topology_report(tt).valid
}
