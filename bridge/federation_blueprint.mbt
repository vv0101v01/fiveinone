///|
/// A minimal executable finite blueprint fragment.
///
/// A finite blueprint here is the finite shadow of the usual
/// blueprint idea: a finite commutative multiplicative monoid with
/// distinguished `0` and `1`, together with additive relations
/// between formal finite sums.  The relations are presented by
/// optional pairwise reductions `a + b ↦ c`; `None` means that the
/// displayed pair does not reduce to a single carrier element.
/// Deleting zeroes and repeatedly applying pair reductions gives a
/// normal form for a formal sum in this finite presentation.
///
/// This is deliberately not a general blueprint/band scheme
/// implementation.  Its purpose is the smallest executable common
/// language in which the federation can compare:
///
/// - a free multiplicative monoid with no nontrivial pair sums;
/// - finite fields and finite `F_p`-algebras from finalg;
/// - the Boolean semiring;
/// - a bounded tropical semiring fragment;
/// - finite open-set lattices, including finite spectra after the
///   existing topology conversion.
///
/// The report checks the monoid laws, symmetry of pair reductions,
/// local confluence on triples, and additive/multiplicative
/// congruence of the induced relation on small formal sums.

///|
pub(all) struct FiniteBlueprint {
  n : Int32
  zero : Int32
  one : Int32
  mul : Array[Array[Int32]]
  pair_sum : Array[Array[Int32?]]
}

///|
fn blueprint_index_ok(bp : FiniteBlueprint, x : Int32) -> Bool {
  x >= 0 && x < bp.n
}

///|
fn blueprint_shape_ok(bp : FiniteBlueprint) -> Bool {
  guard bp.n >= 2 && bp.n <= 32 else { return false }
  guard blueprint_index_ok(bp, bp.zero) && blueprint_index_ok(bp, bp.one) else {
    return false
  }
  guard bp.zero != bp.one else { return false }
  guard bp.mul.length() == bp.n && bp.pair_sum.length() == bp.n else {
    return false
  }
  for i in 0..<bp.n {
    guard bp.mul[i].length() == bp.n && bp.pair_sum[i].length() == bp.n else {
      return false
    }
    for j in 0..<bp.n {
      guard blueprint_index_ok(bp, bp.mul[i][j]) else { return false }
      match bp.pair_sum[i][j] {
        None => ()
        Some(value) => if !blueprint_index_ok(bp, value) { return false }
      }
    }
  }
  true
}

///|
fn blueprint_counts_of_sum(
  bp : FiniteBlueprint,
  sum : Array[Int32],
) -> Array[Int32]? {
  guard blueprint_shape_ok(bp) && sum.length() <= 128 else { return None }
  let counts = Array::make(bp.n, 0)
  for x in sum {
    guard blueprint_index_ok(bp, x) else { return None }
    counts[x] = counts[x] + 1
  }
  Some(counts)
}

///|
fn blueprint_counts_total(counts : Array[Int32]) -> Int32 {
  let mut total = 0
  for count in counts {
    total = total + count
  }
  total
}

///|
fn blueprint_expand_counts(counts : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in 0..<counts.length() {
    for _i in 0..<counts[x] {
      out.push(x)
    }
  }
  out
}

///|
fn blueprint_reduce_counts(
  bp : FiniteBlueprint,
  input : Array[Int32],
) -> Array[Int32]? {
  guard blueprint_shape_ok(bp) && input.length() == bp.n else { return None }
  for count in input {
    guard count >= 0 else { return None }
  }
  guard blueprint_counts_total(input) <= 128 else { return None }
  let counts = input.copy()
  counts[bp.zero] = 0
  // Every pair reduction lowers the total count by one, so this
  // bounded loop is a genuine termination argument for the finite
  // presentation rather than a heuristic fuel bound.
  for _step in 0..<(blueprint_counts_total(input) + 2) {
    let mut applied = false
    for a in 0..<bp.n {
      if applied || a == bp.zero || counts[a] == 0 {
        continue
      }
      for b in a..<bp.n {
        if applied || b == bp.zero {
          continue
        }
        let enough = if a == b {
          counts[a] >= 2
        } else {
          counts[a] > 0 && counts[b] > 0
        }
        if enough {
          match bp.pair_sum[a][b] {
            Some(result) => {
              counts[a] = counts[a] - 1
              counts[b] = counts[b] - 1
              if result != bp.zero {
                counts[result] = counts[result] + 1
              }
              counts[bp.zero] = 0
              applied = true
            }
            None => ()
          }
        }
      }
    }
    if !applied {
      return Some(counts)
    }
  }
  None
}

///|
/// Normalize a formal sum (a multiset of carrier elements) by
/// deleting zeroes and applying the pairwise additive relations.
/// The result is a count vector in carrier-index order.
pub fn finite_blueprint_normalize_sum(
  bp : FiniteBlueprint,
  sum : Array[Int32],
) -> Array[Int32]? {
  let counts = match blueprint_counts_of_sum(bp, sum) {
    Some(value) => value
    None => return None
  }
  blueprint_reduce_counts(bp, counts)
}

///|
/// The carrier element represented by a formal sum, when its
/// normal form is empty (`zero`) or a singleton.
pub fn finite_blueprint_sum_element(
  bp : FiniteBlueprint,
  sum : Array[Int32],
) -> Int32? {
  let counts = match finite_blueprint_normalize_sum(bp, sum) {
    Some(value) => value
    None => return None
  }
  if blueprint_counts_total(counts) == 0 {
    return Some(bp.zero)
  }
  guard blueprint_counts_total(counts) == 1 else { return None }
  for x in 0..<bp.n {
    if counts[x] == 1 {
      return Some(x)
    }
  }
  None
}

///|
/// Binary addition induced by the additive relation, when the sum
/// normalizes to one carrier element.
pub fn finite_blueprint_add(
  bp : FiniteBlueprint,
  a : Int32,
  b : Int32,
) -> Int32? {
  finite_blueprint_sum_element(bp, [a, b])
}

///|
/// The underlying multiplicative monoid operation.
pub fn finite_blueprint_mul(
  bp : FiniteBlueprint,
  a : Int32,
  b : Int32,
) -> Int32? {
  guard blueprint_shape_ok(bp) &&
    blueprint_index_ok(bp, a) &&
    blueprint_index_ok(bp, b) else {
    return None
  }
  Some(bp.mul[a][b])
}

///|
fn blueprint_small_sums(n : Int32, max_len : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = [[]]
  let mut level : Array[Array[Int32]] = [[]]
  for _len in 0..<max_len {
    let next : Array[Array[Int32]] = []
    for sum in level {
      for x in 0..<n {
        let extended = sum.copy()
        extended.push(x)
        next.push(extended.copy())
        out.push(extended)
      }
    }
    level = next
  }
  out
}

///|
fn blueprint_normal_forms_equal(
  bp : FiniteBlueprint,
  a : Array[Int32],
  b : Array[Int32],
) -> Bool {
  match
    (
      finite_blueprint_normalize_sum(bp, a),
      finite_blueprint_normalize_sum(bp, b),
    ) {
    (Some(x), Some(y)) => int_arrays_equal(x, y)
    _ => false
  }
}

///|
fn blueprint_scale_sum(
  bp : FiniteBlueprint,
  scalar : Int32,
  sum : Array[Int32],
) -> Array[Int32]? {
  guard blueprint_shape_ok(bp) && blueprint_index_ok(bp, scalar) else {
    return None
  }
  let out : Array[Int32] = []
  for x in sum {
    guard blueprint_index_ok(bp, x) else { return None }
    out.push(bp.mul[scalar][x])
  }
  Some(out)
}

///|
pub(all) struct FiniteBlueprintReport {
  valid : Bool
  supported : Bool
  n : Int32
  complete_pair_sums : Bool
  small_sum_count : Int32
  small_relation_class_count : Int32
  multiplicative_monoid_ok : Bool
  pair_sum_symmetric_ok : Bool
  singleton_separation_ok : Bool
  zero_congruence_ok : Bool
  local_confluence_ok : Bool
  additive_congruence_ok : Bool
  multiplicative_congruence_ok : Bool
  semiring_shadow_supported : Bool
  semiring_shadow_ok : Bool
}

///|
fn invalid_blueprint_report(n : Int32) -> FiniteBlueprintReport {
  {
    valid: false,
    supported: false,
    n,
    complete_pair_sums: false,
    small_sum_count: 0,
    small_relation_class_count: 0,
    multiplicative_monoid_ok: false,
    pair_sum_symmetric_ok: false,
    singleton_separation_ok: false,
    zero_congruence_ok: false,
    local_confluence_ok: false,
    additive_congruence_ok: false,
    multiplicative_congruence_ok: false,
    semiring_shadow_supported: false,
    semiring_shadow_ok: false,
  }
}

///|
/// Exhaustive small-sum report for a finite blueprint presentation.
/// Supported for carriers of size at most six.
pub fn finite_blueprint_report(bp : FiniteBlueprint) -> FiniteBlueprintReport {
  guard blueprint_shape_ok(bp) && bp.n <= 6 else {
    return invalid_blueprint_report(bp.n)
  }
  let mut multiplicative_monoid_ok = true
  for a in 0..<bp.n {
    if bp.mul[bp.zero][a] != bp.zero ||
      bp.mul[a][bp.zero] != bp.zero ||
      bp.mul[bp.one][a] != a ||
      bp.mul[a][bp.one] != a {
      multiplicative_monoid_ok = false
    }
    for b in 0..<bp.n {
      if bp.mul[a][b] != bp.mul[b][a] {
        multiplicative_monoid_ok = false
      }
      for c in 0..<bp.n {
        if bp.mul[bp.mul[a][b]][c] != bp.mul[a][bp.mul[b][c]] {
          multiplicative_monoid_ok = false
        }
      }
    }
  }
  let mut pair_sum_symmetric_ok = true
  let mut complete_pair_sums = true
  for a in 0..<bp.n {
    for b in 0..<bp.n {
      if bp.pair_sum[a][b] != bp.pair_sum[b][a] {
        pair_sum_symmetric_ok = false
      }
      match bp.pair_sum[a][b] {
        Some(_) => ()
        None => complete_pair_sums = false
      }
    }
  }
  let sums2 = blueprint_small_sums(bp.n, 2)
  let sums3 = blueprint_small_sums(bp.n, 3)
  let mut singleton_separation_ok = true
  for a in 0..<bp.n {
    match finite_blueprint_normalize_sum(bp, [a]) {
      Some(counts) =>
        if a == bp.zero {
          if blueprint_counts_total(counts) != 0 {
            singleton_separation_ok = false
          }
        } else if blueprint_counts_total(counts) != 1 || counts[a] != 1 {
          singleton_separation_ok = false
        }
      None => singleton_separation_ok = false
    }
  }
  let mut zero_congruence_ok = true
  for a in 0..<bp.n {
    match bp.pair_sum[a][bp.zero] {
      Some(value) => if value != a { zero_congruence_ok = false }
      None => ()
    }
    match bp.pair_sum[bp.zero][a] {
      Some(value) => if value != a { zero_congruence_ok = false }
      None => ()
    }
  }
  for sum in sums3 {
    let with_zero = sum.copy()
    with_zero.push(bp.zero)
    if !blueprint_normal_forms_equal(bp, sum, with_zero) {
      zero_congruence_ok = false
    }
  }
  let mut local_confluence_ok = true
  for a in 0..<bp.n {
    for b in 0..<bp.n {
      for c in 0..<bp.n {
        let full = finite_blueprint_normalize_sum(bp, [a, b, c])
        let check_candidate = fn(candidate : Array[Int32]) -> Bool {
          match (full, finite_blueprint_normalize_sum(bp, candidate)) {
            (Some(x), Some(y)) => int_arrays_equal(x, y)
            _ => false
          }
        }
        match bp.pair_sum[a][b] {
          Some(x) => if !check_candidate([x, c]) { local_confluence_ok = false }
          None => ()
        }
        match bp.pair_sum[b][c] {
          Some(y) => if !check_candidate([a, y]) { local_confluence_ok = false }
          None => ()
        }
        match bp.pair_sum[a][c] {
          Some(z) => if !check_candidate([z, b]) { local_confluence_ok = false }
          None => ()
        }
      }
    }
  }
  let mut additive_congruence_ok = true
  for left in sums2 {
    for right in sums2 {
      let direct = left.copy()
      for x in right {
        direct.push(x)
      }
      let via_normal = match
        (
          finite_blueprint_normalize_sum(bp, left),
          finite_blueprint_normalize_sum(bp, right),
        ) {
        (Some(l), Some(r)) => {
          let joined = blueprint_expand_counts(l)
          for x in blueprint_expand_counts(r) {
            joined.push(x)
          }
          Some(joined)
        }
        _ => None
      }
      match via_normal {
        Some(joined) =>
          if !blueprint_normal_forms_equal(bp, direct, joined) {
            additive_congruence_ok = false
          }
        None => additive_congruence_ok = false
      }
    }
  }
  let normal_forms3 : Array[Array[Int32]?] = []
  for sum in sums3 {
    normal_forms3.push(finite_blueprint_normalize_sum(bp, sum))
  }
  let mut multiplicative_congruence_ok = true
  for scalar in 0..<bp.n {
    let scaled_normal_forms : Array[Array[Int32]?] = []
    for sum in sums3 {
      let scaled_normal = match blueprint_scale_sum(bp, scalar, sum) {
        Some(scaled) => finite_blueprint_normalize_sum(bp, scaled)
        None => None
      }
      scaled_normal_forms.push(scaled_normal)
    }
    for i in 0..<sums3.length() {
      for j in 0..<sums3.length() {
        let same_normal = match (normal_forms3[i], normal_forms3[j]) {
          (Some(left), Some(right)) => int_arrays_equal(left, right)
          _ => false
        }
        if same_normal {
          let same_scaled = match
            (scaled_normal_forms[i], scaled_normal_forms[j]) {
            (Some(left), Some(right)) => int_arrays_equal(left, right)
            _ => false
          }
          if !same_scaled {
            multiplicative_congruence_ok = false
          }
        }
      }
    }
  }
  let normal_classes : Array[Array[Int32]] = []
  for sum in sums2 {
    match finite_blueprint_normalize_sum(bp, sum) {
      Some(normal) => {
        let mut seen = false
        for old in normal_classes {
          if int_arrays_equal(old, normal) {
            seen = true
          }
        }
        if !seen {
          normal_classes.push(normal)
        }
      }
      None => ()
    }
  }
  let semiring_shadow_supported = complete_pair_sums
  let mut semiring_shadow_ok = false
  if semiring_shadow_supported {
    semiring_shadow_ok = multiplicative_monoid_ok
    for a in 0..<bp.n {
      for b in 0..<bp.n {
        let ab = finite_blueprint_add(bp, a, b)
        let ba = finite_blueprint_add(bp, b, a)
        if ab != ba {
          semiring_shadow_ok = false
        }
        for c in 0..<bp.n {
          let left = match ab {
            Some(value) => finite_blueprint_add(bp, value, c)
            None => None
          }
          let right = match finite_blueprint_add(bp, b, c) {
            Some(value) => finite_blueprint_add(bp, a, value)
            None => None
          }
          let distributed_left = match finite_blueprint_add(bp, b, c) {
            Some(value) => Some(bp.mul[a][value])
            None => None
          }
          let distributed_right = finite_blueprint_add(
            bp,
            bp.mul[a][b],
            bp.mul[a][c],
          )
          if left != right || distributed_left != distributed_right {
            semiring_shadow_ok = false
          }
        }
      }
      if finite_blueprint_add(bp, a, bp.zero) != Some(a) ||
        finite_blueprint_add(bp, bp.zero, a) != Some(a) {
        semiring_shadow_ok = false
      }
    }
  }
  let valid = multiplicative_monoid_ok &&
    pair_sum_symmetric_ok &&
    singleton_separation_ok &&
    zero_congruence_ok &&
    local_confluence_ok &&
    additive_congruence_ok &&
    multiplicative_congruence_ok &&
    (!semiring_shadow_supported || semiring_shadow_ok)
  {
    valid,
    supported: true,
    n: bp.n,
    complete_pair_sums,
    small_sum_count: sums3.length(),
    small_relation_class_count: normal_classes.length(),
    multiplicative_monoid_ok,
    pair_sum_symmetric_ok,
    singleton_separation_ok,
    zero_congruence_ok,
    local_confluence_ok,
    additive_congruence_ok,
    multiplicative_congruence_ok,
    semiring_shadow_supported,
    semiring_shadow_ok,
  }
}

///|
pub fn check_finite_blueprint(bp : FiniteBlueprint) -> Bool {
  finite_blueprint_report(bp).valid
}

///|
/// The free additive-relation blueprint on a finite multiplicative
/// monoid table: no pair of nonzero elements is identified with a
/// single carrier element.
pub fn finite_blueprint_free_monoid(
  n : Int32,
  zero : Int32,
  one : Int32,
  mul : Array[Array[Int32]],
) -> FiniteBlueprint? {
  let pair_sum = Array::makei(n, fn(_) {
    Array::makei(n, fn(_) -> Int32? { None })
  })
  let bp : FiniteBlueprint = {
    n,
    zero,
    one,
    mul: copy_int_matrix(mul),
    pair_sum,
  }
  guard blueprint_shape_ok(bp) else { return None }
  Some(bp)
}

///|
/// The prime field `F_p` as a complete finite blueprint.
pub fn finite_field_blueprint(p : Int32) -> FiniteBlueprint? {
  guard @fnum.is_prime(p) && p >= 2 && p <= 32 else { return None }
  let mul = Array::makei(p, fn(a) {
    Array::makei(p, fn(b) { @fnum.mul_mod(a, b, p) })
  })
  let pair_sum = Array::makei(p, fn(a) {
    Array::makei(p, fn(b) -> Int32? { Some(@fnum.mod_pos(a + b, p)) })
  })
  Some({ n: p, zero: 0, one: 1, mul, pair_sum, })
}

///|
/// The Boolean semiring `{0,1}` as a complete finite blueprint.
pub fn bool_semiring_blueprint() -> FiniteBlueprint {
  {
    n: 2,
    zero: 0,
    one: 1,
    mul: [[0, 0], [0, 1]],
    pair_sum: [[Some(0), Some(1)], [Some(1), Some(1)]],
  }
}

///|
/// A bounded tropical semiring fragment.
///
/// Carrier element `0` is tropical infinity (the blueprint zero).
/// Element `k+1` encodes finite tropical value `k`, for
/// `0 ≤ k ≤ max_value`.  Blueprint multiplication is truncated
/// ordinary addition of finite values; blueprint addition is min.
pub fn bounded_tropical_blueprint(max_value : Int32) -> FiniteBlueprint? {
  guard max_value >= 0 && max_value <= 29 else { return None }
  let n = max_value + 2
  let mul = Array::makei(n, fn(a) {
    Array::makei(n, fn(b) {
      if a == 0 || b == 0 {
        0
      } else {
        let value = a + b - 1
        if value > n - 1 {
          n - 1
        } else {
          value
        }
      }
    })
  })
  let pair_sum = Array::makei(n, fn(a) {
    Array::makei(n, fn(b) -> Int32? {
      if a == 0 {
        Some(b)
      } else if b == 0 {
        Some(a)
      } else {
        Some(if a < b { a } else { b })
      }
    })
  })
  Some({ n, zero: 0, one: 1, mul, pair_sum, })
}

///|
fn blueprint_find_vector(
  vectors : Array[Array[Int32]],
  target : Array[Int32],
) -> Int32 {
  for i in 0..<vectors.length() {
    if int_arrays_equal(vectors[i], target) {
      return i
    }
  }
  -1
}

///|
/// Read a finite finalg algebra (at most 16 elements) as a complete
/// finite blueprint.  The carrier order is finalg's
/// `all_elements()` order; no ring operation is changed.
pub fn finite_blueprint_of_finalg_alg(
  alg : @ffinite.FinAlg,
) -> FiniteBlueprint? {
  guard @fnum.is_prime(alg.p) &&
    alg.dim >= 1 &&
    alg.dim <= 4 &&
    alg.mult.length() == alg.dim &&
    federation_power_at_most(alg.p, alg.dim, 16) else {
    return None
  }
  let elements = alg.all_elements()
  let n = elements.length()
  guard n >= 2 && n <= 16 else { return None }
  let zero = blueprint_find_vector(elements, alg.zero_elem())
  let one = blueprint_find_vector(elements, alg.one_elem())
  guard zero >= 0 && one >= 0 && zero != one else { return None }
  let mul : Array[Array[Int32]] = []
  let pair_sum : Array[Array[Int32?]] = []
  for a in 0..<n {
    let mul_row : Array[Int32] = []
    let sum_row : Array[Int32?] = []
    for b in 0..<n {
      let product = blueprint_find_vector(
        elements,
        alg.mul_elem(elements[a], elements[b]),
      )
      let sum = blueprint_find_vector(
        elements,
        alg.add_elem(elements[a], elements[b]),
      )
      guard product >= 0 && sum >= 0 else { return None }
      mul_row.push(product)
      sum_row.push(Some(sum))
    }
    mul.push(mul_row)
    pair_sum.push(sum_row)
  }
  let bp : FiniteBlueprint = { n, zero, one, mul, pair_sum, }
  guard blueprint_shape_ok(bp) else { return None }
  Some(bp)
}

///|
/// Read the finite open-set lattice of an Alexandrov space as the
/// distributive-lattice blueprint with multiplication `∪` and
/// additive pair reduction `∩`.  In this presentation blueprint
/// zero is the whole space and blueprint one is the empty open.
///
/// Applying this to `finalg_spec_to_catmath_fintop` gives the
/// finite spectral exemplar; the underlying lattice is not renamed
/// into a general blueprint scheme.
pub fn finite_topology_open_blueprint(tt : @catmath.FinTop) -> FiniteBlueprint? {
  let opens = match fintop_open_masks(tt) {
    Some(values) => values
    None => return None
  }
  let n = opens.length()
  guard n >= 2 && n <= 32 else { return None }
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
  let zero = position(universe)
  let one = position(0)
  guard zero >= 0 && one >= 0 && zero != one else { return None }
  let mul : Array[Array[Int32]] = []
  let pair_sum : Array[Array[Int32?]] = []
  for a in 0..<n {
    let mul_row : Array[Int32] = []
    let sum_row : Array[Int32?] = []
    for b in 0..<n {
      let joined = position(opens[a] | opens[b])
      let met = position(opens[a] & opens[b])
      guard joined >= 0 && met >= 0 else { return None }
      mul_row.push(joined)
      sum_row.push(Some(met))
    }
    mul.push(mul_row)
    pair_sum.push(sum_row)
  }
  let bp : FiniteBlueprint = { n, zero, one, mul, pair_sum, }
  guard blueprint_shape_ok(bp) else { return None }
  Some(bp)
}

///|
/// Read the ideal lattice of a small finalg algebra as a finite
/// blueprint presentation: blueprint multiplication is ideal sum
/// and the additive pair reduction is intersection.  Thus
/// blueprint zero is the unit ideal and blueprint one is the zero
/// ideal.
///
/// This is a presentation, not an unconditional theorem that every
/// ideal lattice is a distributive semiring shadow.  Ideal
/// lattices are modular in general; `finite_blueprint_report`
/// must still pass.  In particular its multiplicative-congruence
/// clause is exactly the finite distributivity condition needed
/// here.  Fields, finite products of fields and the split
/// quadratic example in the aggregate check pass; a
/// nondistributive ideal lattice is correctly rejected rather
/// than renamed into a blueprint by fiat.
pub fn finite_ideal_lattice_blueprint(
  alg : @ffinite.FinAlg,
) -> FiniteBlueprint? {
  guard @fnum.is_prime(alg.p) &&
    alg.dim >= 1 &&
    alg.dim <= 4 &&
    alg.mult.length() == alg.dim &&
    federation_power_at_most(alg.p, alg.dim, 16) else {
    return None
  }
  let ideals = @ffinite.enumerate_ideals(alg)
  let n = ideals.length()
  guard n >= 2 && n <= 32 else { return None }
  let position = fn(target : @ffinite.FinIdeal) -> Int32 {
    for i in 0..<n {
      if ideals[i].eq(target) {
        return i
      }
    }
    -1
  }
  let zero = position(alg.unit_ideal())
  let one = position(alg.zero_ideal())
  guard zero >= 0 && one >= 0 && zero != one else { return None }
  let mul : Array[Array[Int32]] = []
  let pair_sum : Array[Array[Int32?]] = []
  for a in 0..<n {
    let mul_row : Array[Int32] = []
    let sum_row : Array[Int32?] = []
    for b in 0..<n {
      let joined = position(ideals[a].add(ideals[b]))
      let met = position(ideals[a].intersect(ideals[b]))
      guard joined >= 0 && met >= 0 else { return None }
      mul_row.push(joined)
      sum_row.push(Some(met))
    }
    mul.push(mul_row)
    pair_sum.push(sum_row)
  }
  let bp : FiniteBlueprint = { n, zero, one, mul, pair_sum, }
  guard blueprint_shape_ok(bp) else { return None }
  Some(bp)
}
