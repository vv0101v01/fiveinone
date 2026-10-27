///|
/// Finite Boolean relations as a quantale.
///
/// A relation on an `n`-point set is an `n × n` Boolean matrix.
/// Joins are unions, composition is the usual relational product,
/// and the two residuals are the two Galois right adjoints to
/// composition:
///
/// - `residual_after(r, t)` is the greatest `x` with `r ; x ⊆ t`;
/// - `residual_before(t, s)` is the greatest `x` with `x ; s ⊆ t`.
///
/// The formulas used here are the pointwise universal formulas.
/// The exhaustive report also reconstructs both residuals by taking
/// the union of *all* feasible matrices, so the bridge does not
/// merely assert the standard formulas.  Relational star is
/// compared with the semiring member's Boolean matrix closure.

///|
fn relation_shape_n(relation : Array[Array[Bool]]) -> Int32? {
  let n = relation.length()
  guard n >= 1 && n <= 16 else { return None }
  for row in relation {
    guard row.length() == n else { return None }
  }
  Some(n)
}

///|
fn relation_empty(n : Int32) -> Array[Array[Bool]] {
  Array::makei(n, fn(_) { Array::make(n, false) })
}

///|
fn relation_identity(n : Int32) -> Array[Array[Bool]] {
  Array::makei(n, fn(i) { Array::makei(n, fn(j) { i == j }) })
}

///|
fn relation_subset(a : Array[Array[Bool]], b : Array[Array[Bool]]) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard a[i].length() == b[i].length() else { return false }
    for j in 0..<a[i].length() {
      if a[i][j] && !b[i][j] {
        return false
      }
    }
  }
  true
}

///|
fn relation_from_mask(n : Int32, mask : Int32) -> Array[Array[Bool]] {
  let out = relation_empty(n)
  for i in 0..<n {
    for j in 0..<n {
      out[i][j] = federation_bit(mask, i * n + j)
    }
  }
  out
}

///|
/// Pointwise union (the quantale join).
pub fn bool_relation_join(
  a : Array[Array[Bool]],
  b : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(a) {
    Some(n) => n
    None => return None
  }
  guard relation_shape_n(b) == Some(n) else { return None }
  let out = relation_empty(n)
  for i in 0..<n {
    for j in 0..<n {
      out[i][j] = a[i][j] || b[i][j]
    }
  }
  Some(out)
}

///|
/// Pointwise intersection (the finite meet).
pub fn bool_relation_meet(
  a : Array[Array[Bool]],
  b : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(a) {
    Some(n) => n
    None => return None
  }
  guard relation_shape_n(b) == Some(n) else { return None }
  let out = relation_empty(n)
  for i in 0..<n {
    for j in 0..<n {
      out[i][j] = a[i][j] && b[i][j]
    }
  }
  Some(out)
}

///|
/// Relational composition `a ; b`: `(i,k)` is present when some
/// intermediate point `j` has `a[i][j]` and `b[j][k]`.
pub fn bool_relation_compose(
  a : Array[Array[Bool]],
  b : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(a) {
    Some(n) => n
    None => return None
  }
  guard relation_shape_n(b) == Some(n) else { return None }
  let out = relation_empty(n)
  for i in 0..<n {
    for j in 0..<n {
      if a[i][j] {
        for k in 0..<n {
          if b[j][k] {
            out[i][k] = true
          }
        }
      }
    }
  }
  Some(out)
}

///|
/// The greatest `x` such that `r ; x ⊆ t`.
///
/// Pointwise, `x[j][k]` holds exactly when every `i` with
/// `r[i][j]` also has `t[i][k]`.
pub fn bool_relation_residual_after(
  r : Array[Array[Bool]],
  t : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(r) {
    Some(n) => n
    None => return None
  }
  guard relation_shape_n(t) == Some(n) else { return None }
  let out = relation_empty(n)
  for j in 0..<n {
    for k in 0..<n {
      let mut ok = true
      for i in 0..<n {
        if r[i][j] && !t[i][k] {
          ok = false
        }
      }
      out[j][k] = ok
    }
  }
  Some(out)
}

///|
/// The greatest `x` such that `x ; s ⊆ t`.
///
/// Pointwise, `x[i][j]` holds exactly when every `k` with
/// `s[j][k]` also has `t[i][k]`.
pub fn bool_relation_residual_before(
  t : Array[Array[Bool]],
  s : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(t) {
    Some(n) => n
    None => return None
  }
  guard relation_shape_n(s) == Some(n) else { return None }
  let out = relation_empty(n)
  for i in 0..<n {
    for j in 0..<n {
      let mut ok = true
      for k in 0..<n {
        if s[j][k] && !t[i][k] {
          ok = false
        }
      }
      out[i][j] = ok
    }
  }
  Some(out)
}

///|
/// Reflexive-transitive closure computed inside the relation
/// quantale as the least fixed point `μx. I ∨ r ∨ (x ; r)`.
pub fn bool_relation_star(relation : Array[Array[Bool]]) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(relation) {
    Some(n) => n
    None => return None
  }
  let mut current = match bool_relation_join(relation_identity(n), relation) {
    Some(value) => value
    None => return None
  }
  // At most n*n strict increases are possible.
  for _step in 0..<(n * n + 1) {
    let extended = match bool_relation_compose(current, relation) {
      Some(value) => value
      None => return None
    }
    let next = match bool_relation_join(current, extended) {
      Some(value) => value
      None => return None
    }
    if bool_matrices_equal(next, current) {
      return Some(next)
    }
    current = next
  }
  None
}

///|
fn relation_brute_residual_after(
  r : Array[Array[Bool]],
  t : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(r) {
    Some(n) => n
    None => return None
  }
  guard n <= 3 && relation_shape_n(t) == Some(n) else { return None }
  let count = match federation_pow2_checked(n * n) {
    Some(count) => count
    None => return None
  }
  let mut greatest = relation_empty(n)
  for mask in 0..<count {
    let x = relation_from_mask(n, mask)
    let composed = match bool_relation_compose(r, x) {
      Some(value) => value
      None => return None
    }
    if relation_subset(composed, t) {
      greatest = match bool_relation_join(greatest, x) {
        Some(value) => value
        None => return None
      }
    }
  }
  Some(greatest)
}

///|
fn relation_brute_residual_before(
  t : Array[Array[Bool]],
  s : Array[Array[Bool]],
) -> Array[Array[Bool]]? {
  let n = match relation_shape_n(t) {
    Some(n) => n
    None => return None
  }
  guard n <= 3 && relation_shape_n(s) == Some(n) else { return None }
  let count = match federation_pow2_checked(n * n) {
    Some(count) => count
    None => return None
  }
  let mut greatest = relation_empty(n)
  for mask in 0..<count {
    let x = relation_from_mask(n, mask)
    let composed = match bool_relation_compose(x, s) {
      Some(value) => value
      None => return None
    }
    if relation_subset(composed, t) {
      greatest = match bool_relation_join(greatest, x) {
        Some(value) => value
        None => return None
      }
    }
  }
  Some(greatest)
}

///|
/// Exhaustive/triple report for finite Boolean relation quantales.
///
/// `exhaustive_laws_ok` is supported for `n ≤ 2`, where all
/// `2^(n²)` relations are enumerated.  The residual universal
/// properties for the displayed triple are additionally checked
/// against brute-force greatest feasible matrices for `n ≤ 3`.
pub(all) struct FiniteRelationQuantaleReport {
  valid : Bool
  supported : Bool
  n : Int32
  relation_count : Int32
  exhaustive_supported : Bool
  lattice_ok : Bool
  composition_associative_ok : Bool
  identity_ok : Bool
  join_distributivity_ok : Bool
  residual_after : Array[Array[Bool]]
  residual_before : Array[Array[Bool]]
  residual_formula_ok : Bool
  residual_adjunction_ok : Bool
  star_relation : Array[Array[Bool]]
  star_fixed_point_ok : Bool
  semiring_closure_ok : Bool
}

///|
fn invalid_relation_quantale_report(n : Int32) -> FiniteRelationQuantaleReport {
  {
    valid: false,
    supported: false,
    n,
    relation_count: 0,
    exhaustive_supported: false,
    lattice_ok: false,
    composition_associative_ok: false,
    identity_ok: false,
    join_distributivity_ok: false,
    residual_after: [],
    residual_before: [],
    residual_formula_ok: false,
    residual_adjunction_ok: false,
    star_relation: [],
    star_fixed_point_ok: false,
    semiring_closure_ok: false,
  }
}

///|
pub fn finite_relation_quantale_report(
  r : Array[Array[Bool]],
  s : Array[Array[Bool]],
  t : Array[Array[Bool]],
) -> FiniteRelationQuantaleReport {
  let n = match relation_shape_n(r) {
    Some(n) => n
    None => return invalid_relation_quantale_report(r.length())
  }
  guard relation_shape_n(s) == Some(n) && relation_shape_n(t) == Some(n) else {
    return invalid_relation_quantale_report(n)
  }
  let residual_after = match bool_relation_residual_after(r, t) {
    Some(value) => value
    None => return invalid_relation_quantale_report(n)
  }
  let residual_before = match bool_relation_residual_before(t, s) {
    Some(value) => value
    None => return invalid_relation_quantale_report(n)
  }
  let mut residual_formula_ok = false
  if n <= 3 {
    let brute_after = relation_brute_residual_after(r, t)
    let brute_before = relation_brute_residual_before(t, s)
    residual_formula_ok = match (brute_after, brute_before) {
      (Some(after), Some(before)) =>
        bool_matrices_equal(after, residual_after) &&
        bool_matrices_equal(before, residual_before)
      _ => false
    }
  }
  let mut residual_adjunction_ok = true
  let after_composed = bool_relation_compose(r, residual_after)
  let before_composed = bool_relation_compose(residual_before, s)
  residual_adjunction_ok = match (after_composed, before_composed) {
    (Some(a), Some(b)) => relation_subset(a, t) && relation_subset(b, t)
    _ => false
  }
  if n <= 3 {
    let count = match federation_pow2_checked(n * n) {
      Some(count) => count
      None => return invalid_relation_quantale_report(n)
    }
    for mask in 0..<count {
      let x = relation_from_mask(n, mask)
      let lhs_after = match bool_relation_compose(r, x) {
        Some(value) => relation_subset(value, t)
        None => false
      }
      let lhs_before = match bool_relation_compose(x, s) {
        Some(value) => relation_subset(value, t)
        None => false
      }
      if lhs_after != relation_subset(x, residual_after) ||
        lhs_before != relation_subset(x, residual_before) {
        residual_adjunction_ok = false
      }
    }
  }
  let star_relation = match bool_relation_star(r) {
    Some(value) => value
    None => return invalid_relation_quantale_report(n)
  }
  let star_fixed_point_ok = match bool_relation_compose(star_relation, r) {
    Some(step) =>
      match bool_relation_join(relation_identity(n), step) {
        Some(rhs) => bool_matrices_equal(star_relation, rhs)
        None => false
      }
    None => false
  }
  let semiring_closure_ok = match federation_bool_closure(r) {
    Some(closed) => bool_matrices_equal(closed, star_relation)
    None => false
  }
  let exhaustive_supported = n <= 2
  let relation_count = match federation_pow2_checked(n * n) {
    Some(count) => count
    None => 0
  }
  let mut lattice_ok = false
  let mut composition_associative_ok = false
  let mut identity_ok = false
  let mut join_distributivity_ok = false
  if exhaustive_supported {
    lattice_ok = true
    composition_associative_ok = true
    identity_ok = true
    join_distributivity_ok = true
    let empty = relation_empty(n)
    let identity = relation_identity(n)
    for mask_a in 0..<relation_count {
      let a = relation_from_mask(n, mask_a)
      let id_left = bool_relation_compose(identity, a)
      let id_right = bool_relation_compose(a, identity)
      let zero_left = bool_relation_compose(empty, a)
      let zero_right = bool_relation_compose(a, empty)
      match (id_left, id_right, zero_left, zero_right) {
        (Some(l), Some(rr), Some(zl), Some(zr)) =>
          if !bool_matrices_equal(l, a) ||
            !bool_matrices_equal(rr, a) ||
            !bool_matrices_equal(zl, empty) ||
            !bool_matrices_equal(zr, empty) {
            identity_ok = false
          }
        _ => identity_ok = false
      }
      for mask_b in 0..<relation_count {
        let b = relation_from_mask(n, mask_b)
        let join = bool_relation_join(a, b)
        let meet = bool_relation_meet(a, b)
        match (join, meet) {
          (Some(j), Some(m)) => {
            if !relation_subset(a, j) ||
              !relation_subset(b, j) ||
              !relation_subset(m, a) ||
              !relation_subset(m, b) {
              lattice_ok = false
            }
            // j is the least upper bound and m the greatest lower
            // bound among the two displayed candidates' bounds.
            for mask_x in 0..<relation_count {
              let x = relation_from_mask(n, mask_x)
              if relation_subset(a, x) &&
                relation_subset(b, x) &&
                !relation_subset(j, x) {
                lattice_ok = false
              }
              if relation_subset(x, a) &&
                relation_subset(x, b) &&
                !relation_subset(x, m) {
                lattice_ok = false
              }
            }
          }
          _ => lattice_ok = false
        }
        for mask_c in 0..<relation_count {
          let c = relation_from_mask(n, mask_c)
          let ab = bool_relation_compose(a, b)
          let bc = bool_relation_compose(b, c)
          let left_assoc = match ab {
            Some(value) => bool_relation_compose(value, c)
            None => None
          }
          let right_assoc = match bc {
            Some(value) => bool_relation_compose(a, value)
            None => None
          }
          match (left_assoc, right_assoc) {
            (Some(l), Some(rr)) =>
              if !bool_matrices_equal(l, rr) {
                composition_associative_ok = false
              }
            _ => composition_associative_ok = false
          }
          let b_join_c = match bool_relation_join(b, c) {
            Some(value) => value
            None => empty
          }
          let a_join_b = match bool_relation_join(a, b) {
            Some(value) => value
            None => empty
          }
          let ac = bool_relation_compose(a, c)
          let bc2 = bool_relation_compose(b, c)
          let left_dist = bool_relation_compose(a, b_join_c)
          let right_dist = match (ab, ac) {
            (Some(x), Some(y)) => bool_relation_join(x, y)
            _ => None
          }
          let left_dist2 = bool_relation_compose(a_join_b, c)
          let right_dist2 = match (ac, bc2) {
            (Some(x), Some(y)) => bool_relation_join(x, y)
            _ => None
          }
          match (left_dist, right_dist, left_dist2, right_dist2) {
            (Some(a1), Some(a2), Some(b1), Some(b2)) =>
              if !bool_matrices_equal(a1, a2) || !bool_matrices_equal(b1, b2) {
                join_distributivity_ok = false
              }
            _ => join_distributivity_ok = false
          }
        }
      }
    }
  }
  let valid = (n > 3 || residual_formula_ok) &&
    residual_adjunction_ok &&
    star_fixed_point_ok &&
    semiring_closure_ok &&
    (
      !exhaustive_supported ||
      (
        lattice_ok &&
        composition_associative_ok &&
        identity_ok &&
        join_distributivity_ok
      )
    )
  {
    valid,
    supported: true,
    n,
    relation_count,
    exhaustive_supported,
    lattice_ok,
    composition_associative_ok,
    identity_ok,
    join_distributivity_ok,
    residual_after,
    residual_before,
    residual_formula_ok,
    residual_adjunction_ok,
    star_relation,
    star_fixed_point_ok,
    semiring_closure_ok,
  }
}

///|
pub fn check_finite_relation_quantale(
  r : Array[Array[Bool]],
  s : Array[Array[Bool]],
  t : Array[Array[Bool]],
) -> Bool {
  finite_relation_quantale_report(r, s, t).valid
}

///|
/// Bounded nonnegative tropical matrices.
///
/// The second finite quantale in this file is the matrix quantale
/// over `N ∪ {∞}` with join `min` and composition `min-plus`.
/// Its quantale order is the reverse numeric order:
/// `a ⊑ b` iff `a ⊕ b = b`, i.e. `b ≤ a` entrywise as integers.
/// Consequently residual formulas are lower-bound formulas:
///
/// - the greatest `x` (in quantale order, hence numerically
///   least) with `a ⊗ x ⊑ t` has
///   `x[j][k] = max_i(t[i][k] - a[i][j])`, clamped below by `0`;
/// - the greatest `x` with `x ⊗ s ⊑ t` has
///   `x[i][j] = max_k(t[i][k] - s[j][k])`, clamped below by `0`.
///
/// Here a difference is omitted when the subtracted entry is `∞`
/// (that summand imposes no finite constraint), and is `∞` when
/// the target entry is `∞` while the subtracted entry is finite.
/// Inputs are displayed matrices with finite entries in
/// `[0, bound]` or the semiring `trop_inf` sentinel.  Composition
/// is still the ordinary min-plus composition and may produce
/// finite entries above the display bound.

///|
fn tropical_matrix_shape_n(
  matrix : Array[Array[Int32]],
  bound : Int32,
) -> Int32? {
  let n = matrix.length()
  guard n >= 1 && n <= 8 && bound >= 0 && bound <= 10000 else { return None }
  for row in matrix {
    guard row.length() == n else { return None }
    for entry in row {
      guard entry == @semialg.trop_inf || (entry >= 0 && entry <= bound) else {
        return None
      }
    }
  }
  Some(n)
}

///|
fn tropical_raw_matrix_shape_n(matrix : Array[Array[Int32]]) -> Int32? {
  let n = matrix.length()
  guard n >= 1 && n <= 8 else { return None }
  for row in matrix {
    guard row.length() == n else { return None }
    for entry in row {
      guard entry >= 0 && entry <= @semialg.trop_inf else { return None }
    }
  }
  Some(n)
}

///|
fn tropical_matrix_equal(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard int_arrays_equal(a[i], b[i]) else { return false }
  }
  true
}

///|
fn tropical_matrix_filled(n : Int32, value : Int32) -> Array[Array[Int32]] {
  Array::makei(n, fn(_) { Array::make(n, value) })
}

///|
fn tropical_matrix_identity(n : Int32) -> Array[Array[Int32]] {
  Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { if i == j { 0 } else { @semialg.trop_inf } })
  })
}

///|
fn tropical_matrix_join_raw(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
) -> Array[Array[Int32]]? {
  let n = match tropical_raw_matrix_shape_n(a) {
    Some(value) => value
    None => return None
  }
  guard tropical_raw_matrix_shape_n(b) == Some(n) else { return None }
  let out = tropical_matrix_filled(n, @semialg.trop_inf)
  for i in 0..<n {
    for j in 0..<n {
      out[i][j] = if a[i][j] < b[i][j] { a[i][j] } else { b[i][j] }
    }
  }
  Some(out)
}

///|
fn tropical_matrix_compose_raw(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
) -> Array[Array[Int32]]? {
  let n = match tropical_raw_matrix_shape_n(a) {
    Some(value) => value
    None => return None
  }
  guard tropical_raw_matrix_shape_n(b) == Some(n) else { return None }
  let out = tropical_matrix_filled(n, @semialg.trop_inf)
  for i in 0..<n {
    for j in 0..<n {
      if a[i][j] != @semialg.trop_inf {
        for k in 0..<n {
          if b[j][k] != @semialg.trop_inf {
            let value64 = a[i][j].to_int64() + b[j][k].to_int64()
            let value = if value64 >= @semialg.trop_inf.to_int64() {
              @semialg.trop_inf
            } else {
              value64.to_int()
            }
            if value < out[i][k] {
              out[i][k] = value
            }
          }
        }
      }
    }
  }
  Some(out)
}

///|
fn tropical_quantale_leq(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
) -> Bool {
  guard a.length() == b.length() else { return false }
  for i in 0..<a.length() {
    guard a[i].length() == b[i].length() else { return false }
    for j in 0..<a[i].length() {
      // Quantale order is reverse numeric order.
      guard b[i][j] <= a[i][j] else { return false }
    }
  }
  true
}

///|
/// Min-plus composition of two displayed bounded tropical
/// matrices.
pub fn tropical_matrix_compose_bounded(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
  bound : Int32,
) -> Array[Array[Int32]]? {
  let n = match tropical_matrix_shape_n(a, bound) {
    Some(value) => value
    None => return None
  }
  guard tropical_matrix_shape_n(b, bound) == Some(n) else { return None }
  tropical_matrix_compose_raw(a, b)
}

///|
/// The residual after `a`: greatest in quantale order among
/// nonnegative `x` with `a ⊗ x ⊑ t`.
pub fn tropical_matrix_residual_after_bounded(
  a : Array[Array[Int32]],
  t : Array[Array[Int32]],
  bound : Int32,
) -> Array[Array[Int32]]? {
  let n = match tropical_matrix_shape_n(a, bound) {
    Some(value) => value
    None => return None
  }
  guard tropical_matrix_shape_n(t, bound) == Some(n) else { return None }
  let out = tropical_matrix_filled(n, 0)
  for j in 0..<n {
    for k in 0..<n {
      let mut lower = 0
      for i in 0..<n {
        if a[i][j] == @semialg.trop_inf {
          continue
        }
        if t[i][k] == @semialg.trop_inf {
          lower = @semialg.trop_inf
        } else {
          let difference = t[i][k] - a[i][j]
          if difference > lower && lower != @semialg.trop_inf {
            lower = difference
          }
        }
      }
      out[j][k] = lower
    }
  }
  Some(out)
}

///|
/// The residual before `s`: greatest in quantale order among
/// nonnegative `x` with `x ⊗ s ⊑ t`.
pub fn tropical_matrix_residual_before_bounded(
  t : Array[Array[Int32]],
  s : Array[Array[Int32]],
  bound : Int32,
) -> Array[Array[Int32]]? {
  let n = match tropical_matrix_shape_n(t, bound) {
    Some(value) => value
    None => return None
  }
  guard tropical_matrix_shape_n(s, bound) == Some(n) else { return None }
  let out = tropical_matrix_filled(n, 0)
  for i in 0..<n {
    for j in 0..<n {
      let mut lower = 0
      for k in 0..<n {
        if s[j][k] == @semialg.trop_inf {
          continue
        }
        if t[i][k] == @semialg.trop_inf {
          lower = @semialg.trop_inf
        } else {
          let difference = t[i][k] - s[j][k]
          if difference > lower && lower != @semialg.trop_inf {
            lower = difference
          }
        }
      }
      out[i][j] = lower
    }
  }
  Some(out)
}

///|
/// Nonnegative tropical matrix star, computed as the entrywise
/// minimum of `I, a, a², …, aⁿ`.  Nonnegativity means there are
/// no negative cycles, so this is the usual shortest-path closure
/// on the displayed finite matrix.
pub fn tropical_matrix_star_bounded(
  a : Array[Array[Int32]],
  bound : Int32,
) -> Array[Array[Int32]]? {
  let n = match tropical_matrix_shape_n(a, bound) {
    Some(value) => value
    None => return None
  }
  let mut star = match
    tropical_matrix_join_raw(tropical_matrix_identity(n), a) {
    Some(value) => value
    None => return None
  }
  let mut power = a
  for _step in 2..<=n {
    power = match tropical_matrix_compose_raw(power, a) {
      Some(value) => value
      None => return None
    }
    star = match tropical_matrix_join_raw(star, power) {
      Some(value) => value
      None => return None
    }
  }
  Some(star)
}

///|
fn tropical_candidate_count(n : Int32, bound : Int32) -> Int32? {
  guard bound >= 0 && bound <= 8 else { return None }
  let domain = bound + 2
  let exponent = n * n
  guard federation_power_at_most(domain, exponent, 4096) else { return None }
  let mut count = 1
  for _i in 0..<exponent {
    count = count * domain
  }
  Some(count)
}

///|
fn tropical_matrix_from_candidate(
  n : Int32,
  bound : Int32,
  index0 : Int32,
) -> Array[Array[Int32]] {
  let domain = bound + 2
  let mut index = index0
  let out = tropical_matrix_filled(n, 0)
  for i in 0..<n {
    for j in 0..<n {
      let digit = index % domain
      index = index / domain
      out[i][j] = if digit > bound { @semialg.trop_inf } else { digit }
    }
  }
  out
}

///|
fn tropical_brute_residual_after(
  a : Array[Array[Int32]],
  t : Array[Array[Int32]],
  bound : Int32,
) -> Array[Array[Int32]]? {
  let n = match tropical_matrix_shape_n(a, bound) {
    Some(value) => value
    None => return None
  }
  let count = match tropical_candidate_count(n, bound) {
    Some(value) => value
    None => return None
  }
  let mut greatest = tropical_matrix_filled(n, @semialg.trop_inf)
  let mut found = false
  for index in 0..<count {
    let candidate = tropical_matrix_from_candidate(n, bound, index)
    let composed = match tropical_matrix_compose_raw(a, candidate) {
      Some(value) => value
      None => return None
    }
    if tropical_quantale_leq(composed, t) {
      found = true
      greatest = match tropical_matrix_join_raw(greatest, candidate) {
        Some(value) => value
        None => return None
      }
    }
  }
  if found {
    Some(greatest)
  } else {
    None
  }
}

///|
fn tropical_brute_residual_before(
  t : Array[Array[Int32]],
  s : Array[Array[Int32]],
  bound : Int32,
) -> Array[Array[Int32]]? {
  let n = match tropical_matrix_shape_n(t, bound) {
    Some(value) => value
    None => return None
  }
  let count = match tropical_candidate_count(n, bound) {
    Some(value) => value
    None => return None
  }
  let mut greatest = tropical_matrix_filled(n, @semialg.trop_inf)
  let mut found = false
  for index in 0..<count {
    let candidate = tropical_matrix_from_candidate(n, bound, index)
    let composed = match tropical_matrix_compose_raw(candidate, s) {
      Some(value) => value
      None => return None
    }
    if tropical_quantale_leq(composed, t) {
      found = true
      greatest = match tropical_matrix_join_raw(greatest, candidate) {
        Some(value) => value
        None => return None
      }
    }
  }
  if found {
    Some(greatest)
  } else {
    None
  }
}

///|
fn tropical_to_semiring_matrix(
  matrix : Array[Array[Int32]],
) -> @smat.Mat[@semialg.Trop]? {
  let n = match tropical_raw_matrix_shape_n(matrix) {
    Some(value) => value
    None => return None
  }
  let out = @smat.Mat::new(n, n, @semialg.Trop::inf())
  for i in 0..<n {
    for j in 0..<n {
      let value = if matrix[i][j] == @semialg.trop_inf {
        @semialg.Trop::inf()
      } else {
        @semialg.Trop::new(matrix[i][j])
      }
      out.set(i, j, value)
    }
  }
  Some(out)
}

///|
fn tropical_from_semiring_matrix(
  matrix : @smat.Mat[@semialg.Trop],
  n : Int32,
) -> Array[Array[Int32]] {
  let out = tropical_matrix_filled(n, @semialg.trop_inf)
  for i in 0..<n {
    for j in 0..<n {
      let value = matrix.get(i, j)
      out[i][j] = if value.is_inf() { @semialg.trop_inf } else { value.value() }
    }
  }
  out
}

///|
pub(all) struct FiniteTropicalMatrixQuantaleReport {
  valid : Bool
  supported : Bool
  n : Int32
  bound : Int32
  candidate_count : Int32
  exhaustive_supported : Bool
  residual_after : Array[Array[Int32]]
  residual_before : Array[Array[Int32]]
  residual_formula_ok : Bool
  residual_adjunction_ok : Bool
  semiring_compose_ok : Bool
  star_matrix : Array[Array[Int32]]
  star_fixed_point_ok : Bool
  semiring_closure_ok : Bool
  support_reachability_ok : Bool
}

///|
fn invalid_tropical_matrix_quantale_report(
  n : Int32,
  bound : Int32,
) -> FiniteTropicalMatrixQuantaleReport {
  {
    valid: false,
    supported: false,
    n,
    bound,
    candidate_count: 0,
    exhaustive_supported: false,
    residual_after: [],
    residual_before: [],
    residual_formula_ok: false,
    residual_adjunction_ok: false,
    semiring_compose_ok: false,
    star_matrix: [],
    star_fixed_point_ok: false,
    semiring_closure_ok: false,
    support_reachability_ok: false,
  }
}

///|
/// Report for bounded nonnegative tropical matrix residuals.
///
/// Exhaustive brute-force/greatest-element and adjunction checks
/// are enabled only when the finite candidate domain
/// `{0,…,bound,∞}^(n²)` has at most 4096 matrices.  Outside that
/// fragment the formulas are still compared with semiring's
/// native min-plus multiplication and closure, and the support of
/// the star is compared with the Boolean relation star above.
pub fn finite_tropical_matrix_quantale_report(
  a : Array[Array[Int32]],
  s : Array[Array[Int32]],
  t : Array[Array[Int32]],
  bound : Int32,
) -> FiniteTropicalMatrixQuantaleReport {
  let n = match tropical_matrix_shape_n(a, bound) {
    Some(value) => value
    None => return invalid_tropical_matrix_quantale_report(a.length(), bound)
  }
  guard tropical_matrix_shape_n(s, bound) == Some(n) &&
    tropical_matrix_shape_n(t, bound) == Some(n) else {
    return invalid_tropical_matrix_quantale_report(n, bound)
  }
  let residual_after = match
    tropical_matrix_residual_after_bounded(a, t, bound) {
    Some(value) => value
    None => return invalid_tropical_matrix_quantale_report(n, bound)
  }
  let residual_before = match
    tropical_matrix_residual_before_bounded(t, s, bound) {
    Some(value) => value
    None => return invalid_tropical_matrix_quantale_report(n, bound)
  }
  let candidate_count = match tropical_candidate_count(n, bound) {
    Some(value) => value
    None => 0
  }
  let exhaustive_supported = candidate_count > 0
  let mut residual_formula_ok = false
  let mut residual_adjunction_ok = true
  match
    (
      tropical_matrix_compose_raw(a, residual_after),
      tropical_matrix_compose_raw(residual_before, s),
    ) {
    (Some(left), Some(right)) =>
      residual_adjunction_ok = tropical_quantale_leq(left, t) &&
        tropical_quantale_leq(right, t)
    _ => residual_adjunction_ok = false
  }
  if exhaustive_supported {
    residual_formula_ok = match
      (
        tropical_brute_residual_after(a, t, bound),
        tropical_brute_residual_before(t, s, bound),
      ) {
      (Some(after), Some(before)) =>
        tropical_matrix_equal(after, residual_after) &&
        tropical_matrix_equal(before, residual_before)
      _ => false
    }
    for index in 0..<candidate_count {
      let candidate = tropical_matrix_from_candidate(n, bound, index)
      let after_ok = match tropical_matrix_compose_raw(a, candidate) {
        Some(value) => tropical_quantale_leq(value, t)
        None => false
      }
      let before_ok = match tropical_matrix_compose_raw(candidate, s) {
        Some(value) => tropical_quantale_leq(value, t)
        None => false
      }
      if after_ok != tropical_quantale_leq(candidate, residual_after) ||
        before_ok != tropical_quantale_leq(candidate, residual_before) {
        residual_adjunction_ok = false
      }
    }
  }
  let semiring_compose_ok = match
    (
      tropical_to_semiring_matrix(a),
      tropical_to_semiring_matrix(residual_after),
      tropical_matrix_compose_raw(a, residual_after),
    ) {
    (Some(left), Some(right), Some(expected)) =>
      tropical_matrix_equal(
        tropical_from_semiring_matrix(@smat.mul_trop(left, right), n),
        expected,
      )
    _ => false
  }
  let star_matrix = match tropical_matrix_star_bounded(a, bound) {
    Some(value) => value
    None => return invalid_tropical_matrix_quantale_report(n, bound)
  }
  let star_fixed_point_ok = match tropical_matrix_compose_raw(star_matrix, a) {
    Some(step) =>
      match tropical_matrix_join_raw(tropical_matrix_identity(n), step) {
        Some(rhs) => tropical_matrix_equal(star_matrix, rhs)
        None => false
      }
    None => false
  }
  let semiring_closure_ok = match tropical_to_semiring_matrix(a) {
    Some(matrix) =>
      tropical_matrix_equal(
        tropical_from_semiring_matrix(@smat.closure_fw_inplace(matrix), n),
        star_matrix,
      )
    None => false
  }
  let support_relation : Array[Array[Bool]] = []
  for i in 0..<n {
    let row : Array[Bool] = []
    for j in 0..<n {
      row.push(a[i][j] != @semialg.trop_inf)
    }
    support_relation.push(row)
  }
  let support_reachability_ok = match bool_relation_star(support_relation) {
    Some(reachable) => {
      let mut ok = true
      for i in 0..<n {
        for j in 0..<n {
          if reachable[i][j] != (star_matrix[i][j] != @semialg.trop_inf) {
            ok = false
          }
        }
      }
      ok
    }
    None => false
  }
  let valid = (!exhaustive_supported || residual_formula_ok) &&
    residual_adjunction_ok &&
    semiring_compose_ok &&
    star_fixed_point_ok &&
    semiring_closure_ok &&
    support_reachability_ok
  {
    valid,
    supported: true,
    n,
    bound,
    candidate_count,
    exhaustive_supported,
    residual_after,
    residual_before,
    residual_formula_ok,
    residual_adjunction_ok,
    semiring_compose_ok,
    star_matrix,
    star_fixed_point_ok,
    semiring_closure_ok,
    support_reachability_ok,
  }
}

///|
pub fn check_finite_tropical_matrix_quantale(
  a : Array[Array[Int32]],
  s : Array[Array[Int32]],
  t : Array[Array[Int32]],
  bound : Int32,
) -> Bool {
  finite_tropical_matrix_quantale_report(a, s, t, bound).valid
}
