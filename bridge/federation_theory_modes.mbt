///|
/// Executable finite theory morphisms and federation modes.
///
/// This file intentionally separates three different things:
///
/// 1. a small registry of native modes (which member owns which
///    native fragment and which bridge checker is its canonical
///    finite comparison);
/// 2. finite algebraic theory presentations (operations, arities
///    and named laws); and
/// 3. executable model restriction/reflection reports for two
///    theory morphisms:
///
/// ```text
/// Monoid ──include──> Group
/// BoundedLattice ──include──> HeytingAlgebra
/// ```
///
/// Restricting a group along the first morphism forgets inverses
/// and is checked against catmath's finite monoid/free-monoid
/// machinery.  A general finite monoid reflects back to a group
/// exactly when every element is a unit; the report returns a
/// nonunit witness when it does not.  Restricting a finite
/// topology's Heyting algebra forgets implication.  A general
/// finite lattice reflects exactly when the pointwise greatest
/// residual exists for every pair; the diamond lattice `M3` is the
/// standard finite counterexample.
///
/// The mode registry is governance metadata, not a proof.  The
/// mathematical content is in the restriction/reflection reports.

///|
pub(all) struct FiniteTheoryPresentation {
  id : String
  operation_names : Array[String]
  operation_arities : Array[Int32]
  law_names : Array[String]
}

///|
pub(all) struct FiniteTheoryMorphism {
  id : String
  source_theory : String
  target_theory : String
  /// For each source operation, the index of its image operation
  /// in the target presentation.
  operation_map : Array[Int32]
}

///|
pub(all) struct FederationMode {
  id : String
  owner_member : String
  native_fragment : String
  canonical_checker : String
}

///|
/// The executable algebraic presentations used by the bridge.
/// These are finite presentations, not a claim that every member
/// theory (dependent cubical types, finite categories, schemes)
/// is a one-sorted Lawvere theory.
pub fn federation_theory_presentations() -> Array[FiniteTheoryPresentation] {
  [
    {
      id: "monoid",
      operation_names: ["unit", "multiply"],
      operation_arities: [0, 2],
      law_names: ["left-unit", "right-unit", "associativity"],
    },
    {
      id: "group",
      operation_names: ["unit", "multiply", "inverse"],
      operation_arities: [0, 2, 1],
      law_names: [
        "left-unit", "right-unit", "associativity", "left-inverse", "right-inverse",
      ],
    },
    {
      id: "bounded-lattice",
      operation_names: ["bottom", "top", "meet", "join"],
      operation_arities: [0, 0, 2, 2],
      law_names: [
        "meet-idempotent", "join-idempotent", "meet-commutative", "join-commutative",
        "meet-associative", "join-associative", "absorption", "bounded",
      ],
    },
    {
      id: "heyting-algebra",
      operation_names: ["bottom", "top", "meet", "join", "implication"],
      operation_arities: [0, 0, 2, 2, 2],
      law_names: ["bounded-lattice", "implication-adjunction", "modus-ponens"],
    },
    {
      id: "semiring",
      operation_names: ["zero", "one", "add", "multiply"],
      operation_arities: [0, 0, 2, 2],
      law_names: [
        "additive-commutative-monoid", "multiplicative-monoid", "distributivity",
        "zero-absorption",
      ],
    },
  ]
}

///|
pub fn federation_theory_morphisms() -> Array[FiniteTheoryMorphism] {
  [
    {
      id: "monoid-to-group",
      source_theory: "monoid",
      target_theory: "group",
      operation_map: [0, 1],
    },
    {
      id: "bounded-lattice-to-heyting",
      source_theory: "bounded-lattice",
      target_theory: "heyting-algebra",
      operation_map: [0, 1, 2, 3],
    },
  ]
}

///|
/// Native working modes of the federation.  A mode records the
/// member that owns a native semantics; it does not collapse that
/// semantics into the bridge's finite common fragment.
pub fn federation_modes() -> Array[FederationMode] {
  [
    {
      id: "cubical-dependent",
      owner_member: "cubical-hermitian",
      native_fragment: "cubical dependent types, faces and exact rational algebra",
      canonical_checker: "check_federation_polynomial_bridge",
    },
    {
      id: "finite-symmetry-category",
      owner_member: "symlib",
      native_fragment: "permutation groups, graph symmetry and finite categories",
      canonical_checker: "check_federation_category_bridge",
    },
    {
      id: "ordered-semiring-path",
      owner_member: "semiring",
      native_fragment: "semiring matrices, algebraic paths and tropical geometry",
      canonical_checker: "check_relation_quantale_unification_bridge",
    },
    {
      id: "finite-field-geometry",
      owner_member: "finalg",
      native_fragment: "finite fields, ideals, spectra and finite HoTT syntax",
      canonical_checker: "check_finite_spec_federation",
    },
    {
      id: "finite-categorical-logic",
      owner_member: "catmath",
      native_fragment: "finite categories, groups, topology, homology and STLC models",
      canonical_checker: "check_federation_group_bridge",
    },
    {
      id: "finite-common-bridge",
      owner_member: "bridge",
      native_fragment: "explicit finite common fragments and cross-member certificates",
      canonical_checker: "check_federation_grand_unification_construction",
    },
  ]
}

///|
fn theory_presentation_by_id(id : String) -> FiniteTheoryPresentation? {
  for theory in federation_theory_presentations() {
    if theory.id == id {
      return Some(theory)
    }
  }
  None
}

///|
fn theory_string_in(values : Array[String], value : String) -> Bool {
  for x in values {
    if x == value {
      return true
    }
  }
  false
}

///|
fn theory_morphism_shape_ok(morphism : FiniteTheoryMorphism) -> Bool {
  let source = match theory_presentation_by_id(morphism.source_theory) {
    Some(value) => value
    None => return false
  }
  let target = match theory_presentation_by_id(morphism.target_theory) {
    Some(value) => value
    None => return false
  }
  guard morphism.operation_map.length() == source.operation_names.length() else {
    return false
  }
  for i in 0..<morphism.operation_map.length() {
    let image = morphism.operation_map[i]
    guard image >= 0 && image < target.operation_names.length() else {
      return false
    }
    guard source.operation_arities[i] == target.operation_arities[image] else {
      return false
    }
  }
  true
}

///|
pub(all) struct FederationTheoryModeReport {
  valid : Bool
  mode_count : Int32
  theory_count : Int32
  morphism_count : Int32
  covered_member_count : Int32
  unique_mode_ids_ok : Bool
  owners_ok : Bool
  presentations_ok : Bool
  morphisms_ok : Bool
  bridge_mode_ok : Bool
}

///|
pub fn federation_theory_mode_report() -> FederationTheoryModeReport {
  let modes = federation_modes()
  let theories = federation_theory_presentations()
  let morphisms = federation_theory_morphisms()
  let member_ids = federation_member_ids()
  let mut unique_mode_ids_ok = true
  let mut owners_ok = true
  let mut bridge_mode_ok = false
  let covered : Array[String] = []
  for i in 0..<modes.length() {
    for j in (i + 1)..<modes.length() {
      if modes[i].id == modes[j].id {
        unique_mode_ids_ok = false
      }
    }
    if modes[i].owner_member == "bridge" {
      bridge_mode_ok = true
    } else if theory_string_in(member_ids, modes[i].owner_member) {
      if !theory_string_in(covered, modes[i].owner_member) {
        covered.push(modes[i].owner_member)
      }
    } else {
      owners_ok = false
    }
    if modes[i].native_fragment == "" || modes[i].canonical_checker == "" {
      owners_ok = false
    }
  }
  if covered.length() != member_ids.length() {
    owners_ok = false
  }
  let mut presentations_ok = true
  for i in 0..<theories.length() {
    if theories[i].operation_names.length() !=
      theories[i].operation_arities.length() ||
      theories[i].operation_names.length() == 0 ||
      theories[i].law_names.length() == 0 {
      presentations_ok = false
    }
    for arity in theories[i].operation_arities {
      if arity < 0 || arity > 8 {
        presentations_ok = false
      }
    }
    for j in (i + 1)..<theories.length() {
      if theories[i].id == theories[j].id {
        presentations_ok = false
      }
    }
  }
  let mut morphisms_ok = morphisms.length() > 0
  for morphism in morphisms {
    if !theory_morphism_shape_ok(morphism) {
      morphisms_ok = false
    }
  }
  let valid = unique_mode_ids_ok &&
    owners_ok &&
    presentations_ok &&
    morphisms_ok &&
    bridge_mode_ok
  {
    valid,
    mode_count: modes.length(),
    theory_count: theories.length(),
    morphism_count: morphisms.length(),
    covered_member_count: covered.length(),
    unique_mode_ids_ok,
    owners_ok,
    presentations_ok,
    morphisms_ok,
    bridge_mode_ok,
  }
}

///|
fn theory_table_shape_ok(
  n : Int32,
  table : Array[Array[Int32]],
  e : Int32,
) -> Bool {
  guard n >= 1 && n <= 64 && table.length() == n else { return false }
  guard e >= 0 && e < n else { return false }
  for row in table {
    guard row.length() == n else { return false }
    for value in row {
      guard value >= 0 && value < n else { return false }
    }
  }
  true
}

///|
fn theory_monoid_laws_ok(monoid : @catmath.FinMonoid) -> Bool {
  guard theory_table_shape_ok(monoid.order, monoid.mul, monoid.e) else {
    return false
  }
  for a in 0..<monoid.order {
    if monoid.mul[monoid.e][a] != a || monoid.mul[a][monoid.e] != a {
      return false
    }
    for b in 0..<monoid.order {
      for c in 0..<monoid.order {
        if monoid.mul[monoid.mul[a][b]][c] != monoid.mul[a][monoid.mul[b][c]] {
          return false
        }
      }
    }
  }
  true
}

///|
/// Restrict a finite group model along `monoid → group` by
/// forgetting its inverse operation.
pub fn finite_group_restrict_to_monoid(
  group : @catmath.FinGroup,
) -> @catmath.FinMonoid? {
  guard fin_group_shape_ok(group) && @catmath.check_group(group) else {
    return None
  }
  Some(
    @catmath.fin_monoid_of(group.order, group.mul, group.e, group.name + "|Mon"),
  )
}

///|
pub(all) struct FiniteGroupTheoryRestrictionReport {
  valid : Bool
  supported : Bool
  theory_morphism : String
  order : Int32
  group_ok : Bool
  restricted_monoid_ok : Bool
  operation_preserved_ok : Bool
  free_monoid_adjunction_ok : Bool
}

///|
pub fn finite_group_theory_restriction_report(
  group : @catmath.FinGroup,
) -> FiniteGroupTheoryRestrictionReport {
  let invalid : FiniteGroupTheoryRestrictionReport = {
    valid: false,
    supported: false,
    theory_morphism: "monoid-to-group",
    order: group.order,
    group_ok: false,
    restricted_monoid_ok: false,
    operation_preserved_ok: false,
    free_monoid_adjunction_ok: false,
  }
  let group_ok = fin_group_shape_ok(group) && @catmath.check_group(group)
  let restricted = match finite_group_restrict_to_monoid(group) {
    Some(value) => value
    None => return invalid
  }
  let restricted_monoid_ok = theory_monoid_laws_ok(restricted)
  let mut operation_preserved_ok = restricted.order == group.order &&
    restricted.e == group.e
  if operation_preserved_ok {
    for a in 0..<group.order {
      for b in 0..<group.order {
        if restricted.mul[a][b] != group.mul[a][b] {
          operation_preserved_ok = false
        }
      }
      if group.mul[group.inv[a]][a] != group.e ||
        group.mul[a][group.inv[a]] != group.e {
        operation_preserved_ok = false
      }
    }
  }
  let free_monoid_adjunction_ok = group.order <= 8 &&
    @catmath.verify_adjunction_monoid(1, restricted)
  let valid = group_ok &&
    restricted_monoid_ok &&
    operation_preserved_ok &&
    free_monoid_adjunction_ok
  {
    valid,
    supported: true,
    theory_morphism: "monoid-to-group",
    order: group.order,
    group_ok,
    restricted_monoid_ok,
    operation_preserved_ok,
    free_monoid_adjunction_ok,
  }
}

///|
pub(all) struct FiniteMonoidGroupReflectionReport {
  valid : Bool
  supported : Bool
  theory_morphism : String
  order : Int32
  monoid_ok : Bool
  expands_to_group : Bool
  inverses : Array[Int32]
  nonunit_witness : Int32
  reconstructed_group_ok : Bool
}

///|
/// Decide whether a finite monoid model lifts through
/// `monoid → group` with the same carrier, unit and multiplication.
/// This is a same-presentation expansion decision, not the
/// Grothendieck group completion (which changes the carrier).
pub fn finite_monoid_group_reflection_report(
  monoid : @catmath.FinMonoid,
) -> FiniteMonoidGroupReflectionReport {
  let monoid_ok = theory_monoid_laws_ok(monoid)
  let inverses = Array::make(if monoid_ok { monoid.order } else { 0 }, -1)
  let mut nonunit_witness = -1
  if monoid_ok {
    for a in 0..<monoid.order {
      for b in 0..<monoid.order {
        if monoid.mul[a][b] == monoid.e && monoid.mul[b][a] == monoid.e {
          inverses[a] = b
        }
      }
      if inverses[a] < 0 && nonunit_witness < 0 {
        nonunit_witness = a
      }
    }
  }
  let expands_to_group = monoid_ok && nonunit_witness < 0
  let reconstructed_group_ok = if expands_to_group {
    let group = @catmath.fin_group_of(
      monoid.order,
      monoid.mul,
      inverses.copy(),
      monoid.e,
      monoid.name + "|Grp",
    )
    @catmath.check_group(group)
  } else {
    false
  }
  let valid = monoid_ok && expands_to_group == reconstructed_group_ok
  {
    valid,
    supported: monoid_ok,
    theory_morphism: "monoid-to-group",
    order: monoid.order,
    monoid_ok,
    expands_to_group,
    inverses,
    nonunit_witness,
    reconstructed_group_ok,
  }
}

///|
pub(all) struct FiniteLatticeModel {
  n : Int32
  bottom : Int32
  top : Int32
  meet : Array[Array[Int32]]
  join : Array[Array[Int32]]
}

///|
fn theory_lattice_tables_shape_ok(model : FiniteLatticeModel) -> Bool {
  theory_table_shape_ok(model.n, model.meet, model.bottom) &&
  theory_table_shape_ok(model.n, model.join, model.top) &&
  model.bottom != model.top
}

///|
fn theory_lattice_le(model : FiniteLatticeModel, a : Int32, b : Int32) -> Bool {
  model.meet[a][b] == a
}

///|
pub(all) struct FiniteLatticeTheoryReport {
  valid : Bool
  supported : Bool
  theory_morphism : String
  n : Int32
  lattice_ok : Bool
  distributive : Bool
  implication : Array[Array[Int32]]
  expands_to_heyting : Bool
  heyting_adjunction_ok : Bool
}

///|
fn invalid_lattice_theory_report(n : Int32) -> FiniteLatticeTheoryReport {
  {
    valid: false,
    supported: false,
    theory_morphism: "bounded-lattice-to-heyting",
    n,
    lattice_ok: false,
    distributive: false,
    implication: [],
    expands_to_heyting: false,
    heyting_adjunction_ok: false,
  }
}

///|
/// Check a finite bounded-lattice model and decide whether it
/// expands through `bounded-lattice → heyting-algebra` by a
/// greatest-residual implication on the same carrier.
pub fn finite_lattice_theory_report(
  model : FiniteLatticeModel,
) -> FiniteLatticeTheoryReport {
  guard theory_lattice_tables_shape_ok(model) && model.n <= 16 else {
    return invalid_lattice_theory_report(model.n)
  }
  let mut lattice_ok = true
  let mut distributive = true
  for a in 0..<model.n {
    if model.meet[a][a] != a ||
      model.join[a][a] != a ||
      model.meet[model.bottom][a] != model.bottom ||
      model.meet[a][model.bottom] != model.bottom ||
      model.meet[model.top][a] != a ||
      model.meet[a][model.top] != a ||
      model.join[model.bottom][a] != a ||
      model.join[a][model.bottom] != a ||
      model.join[model.top][a] != model.top ||
      model.join[a][model.top] != model.top {
      lattice_ok = false
    }
    for b in 0..<model.n {
      if model.meet[a][b] != model.meet[b][a] ||
        model.join[a][b] != model.join[b][a] ||
        model.meet[a][model.join[a][b]] != a ||
        model.join[a][model.meet[a][b]] != a ||
        theory_lattice_le(model, a, b) != (model.join[a][b] == b) {
        lattice_ok = false
      }
      for c in 0..<model.n {
        if model.meet[model.meet[a][b]][c] != model.meet[a][model.meet[b][c]] ||
          model.join[model.join[a][b]][c] != model.join[a][model.join[b][c]] {
          lattice_ok = false
        }
        if model.meet[a][model.join[b][c]] !=
          model.join[model.meet[a][b]][model.meet[a][c]] ||
          model.join[a][model.meet[b][c]] !=
          model.meet[model.join[a][b]][model.join[a][c]] {
          distributive = false
        }
      }
    }
  }
  let implication = Array::makei(model.n, fn(_) { Array::make(model.n, -1) })
  let mut expands_to_heyting = lattice_ok
  if lattice_ok {
    for a in 0..<model.n {
      for b in 0..<model.n {
        let mut greatest = -1
        for x in 0..<model.n {
          if theory_lattice_le(model, model.meet[a][x], b) {
            let mut is_greatest = true
            for y in 0..<model.n {
              if theory_lattice_le(model, model.meet[a][y], b) &&
                !theory_lattice_le(model, y, x) {
                is_greatest = false
              }
            }
            if is_greatest {
              if greatest >= 0 && greatest != x {
                greatest = -2
              } else if greatest >= 0 || greatest == -1 {
                greatest = x
              }
            }
          }
        }
        if greatest < 0 {
          expands_to_heyting = false
        } else {
          implication[a][b] = greatest
        }
      }
    }
  }
  let mut heyting_adjunction_ok = false
  if expands_to_heyting {
    heyting_adjunction_ok = true
    for a in 0..<model.n {
      for b in 0..<model.n {
        for x in 0..<model.n {
          let lhs = theory_lattice_le(model, model.meet[x][a], b)
          let rhs = theory_lattice_le(model, x, implication[a][b])
          if lhs != rhs {
            heyting_adjunction_ok = false
          }
        }
      }
    }
    if !heyting_adjunction_ok {
      expands_to_heyting = false
    }
  }
  let valid = lattice_ok && expands_to_heyting == heyting_adjunction_ok
  {
    valid,
    supported: true,
    theory_morphism: "bounded-lattice-to-heyting",
    n: model.n,
    lattice_ok,
    distributive,
    implication,
    expands_to_heyting,
    heyting_adjunction_ok,
  }
}

///|
/// The diamond lattice `M3`: bottom, three incomparable atoms and
/// top.  It is a finite bounded lattice but is not distributive
/// and has no Heyting implication on the same carrier.
pub fn finite_diamond_lattice_model() -> FiniteLatticeModel {
  let meet = Array::makei(5, fn(a) {
    Array::makei(5, fn(b) {
      if a == 0 || b == 0 {
        0
      } else if a == 4 {
        b
      } else if b == 4 {
        a
      } else if a == b {
        a
      } else {
        0
      }
    })
  })
  let join = Array::makei(5, fn(a) {
    Array::makei(5, fn(b) {
      if a == 4 || b == 4 {
        4
      } else if a == 0 {
        b
      } else if b == 0 {
        a
      } else if a == b {
        a
      } else {
        4
      }
    })
  })
  { n: 5, bottom: 0, top: 4, meet, join, }
}

///|
/// The bounded lattice underlying a finite topology's open sets.
pub fn finite_lattice_model_of_fintop_opens(
  tt : @catmath.FinTop,
) -> FiniteLatticeModel? {
  let opens = match fintop_open_masks(tt) {
    Some(values) => values
    None => return None
  }
  let n = opens.length()
  guard n >= 2 && n <= 16 else { return None }
  let position = fn(mask : Int32) -> Int32 {
    for i in 0..<n {
      if opens[i] == mask {
        return i
      }
    }
    -1
  }
  let universe = match federation_pow2_checked(tt.n) {
    Some(value) => value - 1
    None => return None
  }
  let bottom = position(0)
  let top = position(universe)
  guard bottom >= 0 && top >= 0 && bottom != top else { return None }
  let meet : Array[Array[Int32]] = []
  let join : Array[Array[Int32]] = []
  for a in 0..<n {
    let meet_row : Array[Int32] = []
    let join_row : Array[Int32] = []
    for b in 0..<n {
      let met = position(opens[a] & opens[b])
      let joined = position(opens[a] | opens[b])
      guard met >= 0 && joined >= 0 else { return None }
      meet_row.push(met)
      join_row.push(joined)
    }
    meet.push(meet_row)
    join.push(join_row)
  }
  Some({ n, bottom, top, meet, join, })
}

///|
pub(all) struct FiniteHeytingTheoryRestrictionReport {
  valid : Bool
  supported : Bool
  theory_morphism : String
  point_count : Int32
  open_count : Int32
  underlying_lattice_ok : Bool
  distributive : Bool
  implication_agrees_ok : Bool
}

///|
/// Restrict a finite topology's Heyting algebra of opens to its
/// bounded lattice and compare the reconstructed residual with the
/// bridge's existing interior-based Heyting implication.
pub fn finite_heyting_theory_restriction_report(
  tt : @catmath.FinTop,
) -> FiniteHeytingTheoryRestrictionReport {
  let invalid : FiniteHeytingTheoryRestrictionReport = {
    valid: false,
    supported: false,
    theory_morphism: "bounded-lattice-to-heyting",
    point_count: tt.n,
    open_count: 0,
    underlying_lattice_ok: false,
    distributive: false,
    implication_agrees_ok: false,
  }
  let opens = match fintop_open_masks(tt) {
    Some(values) => values
    None => return invalid
  }
  let model = match finite_lattice_model_of_fintop_opens(tt) {
    Some(value) => value
    None => return invalid
  }
  let report = finite_lattice_theory_report(model)
  let mut underlying_lattice_ok = report.valid && report.expands_to_heyting
  let mut implication_agrees_ok = underlying_lattice_ok
  for a in 0..<opens.length() {
    for b in 0..<opens.length() {
      let existing_meet = fintop_heyting_meet(tt, opens[a], opens[b])
      let existing_join = fintop_heyting_join(tt, opens[a], opens[b])
      if existing_meet != Some(opens[model.meet[a][b]]) ||
        existing_join != Some(opens[model.join[a][b]]) {
        underlying_lattice_ok = false
      }
      if report.implication.length() == model.n &&
        report.implication[a][b] >= 0 &&
        report.implication[a][b] < opens.length() {
        let reconstructed = opens[report.implication[a][b]]
        if fintop_heyting_implication(tt, opens[a], opens[b]) !=
          Some(reconstructed) {
          implication_agrees_ok = false
        }
      } else {
        implication_agrees_ok = false
      }
    }
  }
  let valid = underlying_lattice_ok && implication_agrees_ok
  {
    valid,
    supported: true,
    theory_morphism: "bounded-lattice-to-heyting",
    point_count: tt.n,
    open_count: opens.length(),
    underlying_lattice_ok,
    distributive: report.distributive,
    implication_agrees_ok,
  }
}

///|
pub fn check_finite_theory_morphisms() -> Bool {
  guard federation_theory_mode_report().valid else { return false }
  guard finite_group_theory_restriction_report(@catmath.cyclic_group(4)).valid else {
    return false
  }
  let and_monoid = @catmath.fin_monoid_of(2, [[0, 0], [0, 1]], 1, "Bool-and")
  let reflection = finite_monoid_group_reflection_report(and_monoid)
  guard reflection.valid &&
    !reflection.expands_to_group &&
    reflection.nonunit_witness == 0 else {
    return false
  }
  let z2_monoid = @catmath.fin_monoid_of(2, [[0, 1], [1, 0]], 0, "Z2-as-monoid")
  let z2_reflection = finite_monoid_group_reflection_report(z2_monoid)
  guard z2_reflection.valid && z2_reflection.expands_to_group else {
    return false
  }
  let chain = @catmath.make_top(3, [
    [true, true, true],
    [false, true, true],
    [false, false, true],
  ])
  guard finite_heyting_theory_restriction_report(chain).valid else {
    return false
  }
  let diamond = finite_lattice_theory_report(finite_diamond_lattice_model())
  diamond.valid &&
  diamond.lattice_ok &&
  !diamond.distributive &&
  !diamond.expands_to_heyting
}
