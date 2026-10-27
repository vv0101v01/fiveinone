///|
/// Sieves on representables and their finite Heyting algebras.
///
/// For a finite category `C` and an object `c`, subobjects of the
/// representable presheaf `y(c) = Hom(-, c)` are sieves on `c`:
/// sets of arrows into `c` closed under precomposition.  This file
/// makes that standard finite fragment executable directly on
/// symlib's `FinCat` tables.
///
/// A sieve is encoded as a morphism-index bitmask.  Intersection
/// and union are meet and join.  Implication is computed by the
/// usual local formula
///
/// ```text
/// f ∈ (S ⇒ T)  iff  ∀g, f∘g ∈ S implies f∘g ∈ T.
/// ```
///
/// Pullback along `h : d → c` is `h*S = { g | h∘g ∈ S }`.  The
/// report checks the Heyting adjunction and pullback preservation
/// by exhaustive enumeration on the supported finite fragment.
/// The Alexandrov comparison uses the opposite thin category:
/// at `c`, sieve domains are up-sets contained in `↑c`.

///|
fn sieve_incoming(c : @sym.FinCat, object : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for mor in 0..<c.nmor {
    if c.cod[mor] == object {
      out.push(mor)
    }
  }
  out
}

///|
fn sieve_supported(c : @sym.FinCat, object : Int32) -> Bool {
  fincat_shape_ok(c) &&
  federation_index_ok(object, c.nobj) &&
  c.nmor <= 30 &&
  sieve_incoming(c, object).length() <= 16
}

///|
fn sieve_mask_shape_ok(c : @sym.FinCat, object : Int32, mask : Int32) -> Bool {
  guard mask >= 0 else { return false }
  for mor in 0..<31 {
    if federation_bit(mask, mor) {
      guard mor < c.nmor && c.cod[mor] == object else { return false }
    }
  }
  true
}

///|
fn sieve_subset(a : Int32, b : Int32) -> Bool {
  (a & b) == a
}

///|
fn sieve_contains(values : Array[Int32], value : Int32) -> Bool {
  for x in values {
    if x == value {
      return true
    }
  }
  false
}

///|
/// Whether `mask` is a sieve on `object`: every selected arrow
/// into `object` remains selected after every possible
/// precomposition.
pub fn fincat_is_sieve_on(
  c : @sym.FinCat,
  object : Int32,
  mask : Int32,
) -> Bool {
  guard sieve_supported(c, object) && sieve_mask_shape_ok(c, object, mask) else {
    return false
  }
  for f in sieve_incoming(c, object) {
    if federation_bit(mask, f) {
      for g in 0..<c.nmor {
        if c.cod[g] == c.dom[f] {
          let composite = c.comp[f * c.nmor + g]
          guard composite >= 0 && federation_bit(mask, composite) else {
            return false
          }
        }
      }
    }
  }
  true
}

///|
/// Enumerate all sieves on one object.  The supported fragment has
/// at most 30 morphisms in the whole category and at most 16
/// arrows into the chosen object.
pub fn fincat_sieves_on(c : @sym.FinCat, object : Int32) -> Array[Int32]? {
  guard sieve_supported(c, object) else { return None }
  let incoming = sieve_incoming(c, object)
  let count = match federation_pow2_checked(incoming.length()) {
    Some(count) => count
    None => return None
  }
  let out : Array[Int32] = []
  for subset in 0..<count {
    let mut mask = 0
    for i in 0..<incoming.length() {
      if federation_bit(subset, i) {
        mask = mask | (1 << incoming[i])
      }
    }
    if fincat_is_sieve_on(c, object, mask) {
      out.push(mask)
    }
  }
  Some(out)
}

///|
/// Heyting implication of sieves by the local precomposition
/// formula.
pub fn fincat_sieve_implication(
  c : @sym.FinCat,
  object : Int32,
  s : Int32,
  t : Int32,
) -> Int32? {
  guard fincat_is_sieve_on(c, object, s) && fincat_is_sieve_on(c, object, t) else {
    return None
  }
  let mut out = 0
  for f in sieve_incoming(c, object) {
    let mut ok = true
    for g in 0..<c.nmor {
      if c.cod[g] == c.dom[f] {
        let composite = c.comp[f * c.nmor + g]
        if composite < 0 ||
          (federation_bit(s, composite) && !federation_bit(t, composite)) {
          ok = false
        }
      }
    }
    if ok {
      out = out | (1 << f)
    }
  }
  Some(out)
}

///|
/// Pseudocomplement `s ⇒ ⊥`.
pub fn fincat_sieve_negation(
  c : @sym.FinCat,
  object : Int32,
  s : Int32,
) -> Int32? {
  fincat_sieve_implication(c, object, s, 0)
}

///|
/// Pull a sieve on `cod(h)` back to a sieve on `dom(h)`.
pub fn fincat_sieve_pullback(
  c : @sym.FinCat,
  sieve : Int32,
  h : Int32,
) -> Int32? {
  guard fincat_shape_ok(c) && federation_index_ok(h, c.nmor) else {
    return None
  }
  let target = c.cod[h]
  let source = c.dom[h]
  guard fincat_is_sieve_on(c, target, sieve) && sieve_supported(c, source) else {
    return None
  }
  let mut out = 0
  for g in sieve_incoming(c, source) {
    let composite = c.comp[h * c.nmor + g]
    guard composite >= 0 else { return None }
    if federation_bit(sieve, composite) {
      out = out | (1 << g)
    }
  }
  Some(out)
}

///|
pub(all) struct FinitePresheafSieveReport {
  valid : Bool
  supported : Bool
  nobj : Int32
  nmor : Int32
  object : Int32
  incoming_count : Int32
  sieves : Array[Int32]
  sieve_count : Int32
  category_ok : Bool
  lattice_closure_ok : Bool
  implication_is_sieve_ok : Bool
  implication_adjunction_ok : Bool
  negation_ok : Bool
  pullback_ok : Bool
  pullback_preserves_operations_ok : Bool
  is_Boolean : Bool
}

///|
fn invalid_presheaf_sieve_report(
  c : @sym.FinCat,
  object : Int32,
) -> FinitePresheafSieveReport {
  {
    valid: false,
    supported: false,
    nobj: c.nobj,
    nmor: c.nmor,
    object,
    incoming_count: 0,
    sieves: [],
    sieve_count: 0,
    category_ok: false,
    lattice_closure_ok: false,
    implication_is_sieve_ok: false,
    implication_adjunction_ok: false,
    negation_ok: false,
    pullback_ok: false,
    pullback_preserves_operations_ok: false,
    is_Boolean: false,
  }
}

///|
/// Exhaustive report for `Sub(y(object))` in a finite presheaf
/// category, represented by sieves.
pub fn finite_presheaf_sieve_report(
  c : @sym.FinCat,
  object : Int32,
) -> FinitePresheafSieveReport {
  let sieves = match fincat_sieves_on(c, object) {
    Some(values) => values
    None => return invalid_presheaf_sieve_report(c, object)
  }
  let category_ok = @sym.is_category(c)
  let mut lattice_closure_ok = true
  let mut implication_is_sieve_ok = true
  let mut implication_adjunction_ok = true
  let mut negation_ok = true
  let mut is_Boolean = true
  for s in sieves {
    let negation = fincat_sieve_negation(c, object, s)
    match negation {
      Some(ns) => {
        if !sieve_contains(sieves, ns) || (s & ns) != 0 {
          negation_ok = false
        }
        match fincat_sieve_negation(c, object, ns) {
          Some(nns) => {
            if !sieve_subset(s, nns) {
              negation_ok = false
            }
            if nns != s {
              is_Boolean = false
            }
            match fincat_sieve_negation(c, object, nns) {
              Some(nnns) => if nnns != ns { negation_ok = false }
              None => negation_ok = false
            }
          }
          None => negation_ok = false
        }
      }
      None => negation_ok = false
    }
    for t in sieves {
      if !sieve_contains(sieves, s & t) || !sieve_contains(sieves, s | t) {
        lattice_closure_ok = false
      }
      let implication = match fincat_sieve_implication(c, object, s, t) {
        Some(value) => value
        None => {
          implication_is_sieve_ok = false
          0
        }
      }
      if !sieve_contains(sieves, implication) {
        implication_is_sieve_ok = false
      }
      for w in sieves {
        if sieve_subset(w & s, t) != sieve_subset(w, implication) {
          implication_adjunction_ok = false
        }
      }
    }
  }
  let mut pullback_ok = true
  let mut pullback_preserves_operations_ok = true
  for h in sieve_incoming(c, object) {
    let source = c.dom[h]
    for s in sieves {
      let pulled_s = fincat_sieve_pullback(c, s, h)
      match pulled_s {
        Some(value) =>
          if !fincat_is_sieve_on(c, source, value) {
            pullback_ok = false
          }
        None => pullback_ok = false
      }
      for t in sieves {
        let pulled_t = fincat_sieve_pullback(c, t, h)
        let pulled_meet = fincat_sieve_pullback(c, s & t, h)
        let pulled_join = fincat_sieve_pullback(c, s | t, h)
        let implication = fincat_sieve_implication(c, object, s, t)
        let pulled_implication = match implication {
          Some(value) => fincat_sieve_pullback(c, value, h)
          None => None
        }
        let source_implication = match (pulled_s, pulled_t) {
          (Some(ps), Some(pt)) => fincat_sieve_implication(c, source, ps, pt)
          _ => None
        }
        match
          (
            pulled_s, pulled_t, pulled_meet, pulled_join, pulled_implication, source_implication,
          ) {
          (Some(ps), Some(pt), Some(pm), Some(pj), Some(pi), Some(si)) =>
            if pm != (ps & pt) || pj != (ps | pt) || pi != si {
              pullback_preserves_operations_ok = false
            }
          _ => pullback_preserves_operations_ok = false
        }
        if sieve_subset(s, t) {
          match (pulled_s, pulled_t) {
            (Some(ps), Some(pt)) =>
              if !sieve_subset(ps, pt) {
                pullback_preserves_operations_ok = false
              }
            _ => pullback_preserves_operations_ok = false
          }
        }
      }
    }
  }
  let valid = category_ok &&
    lattice_closure_ok &&
    implication_is_sieve_ok &&
    implication_adjunction_ok &&
    negation_ok &&
    pullback_ok &&
    pullback_preserves_operations_ok
  {
    valid,
    supported: true,
    nobj: c.nobj,
    nmor: c.nmor,
    object,
    incoming_count: sieve_incoming(c, object).length(),
    sieves: sieves.copy(),
    sieve_count: sieves.length(),
    category_ok,
    lattice_closure_ok,
    implication_is_sieve_ok,
    implication_adjunction_ok,
    negation_ok,
    pullback_ok,
    pullback_preserves_operations_ok,
    is_Boolean,
  }
}

///|
pub fn check_finite_presheaf_sieves(c : @sym.FinCat, object : Int32) -> Bool {
  finite_presheaf_sieve_report(c, object).valid
}

///|
fn fintop_opposite_fincat(tt : @catmath.FinTop) -> @sym.FinCat? {
  guard fintop_shape_ok(tt) && @catmath.check_preorder(tt) else { return None }
  let pairs : Array[(Int32, Int32)] = []
  for a in 0..<tt.n {
    for b in 0..<tt.n {
      if tt.le[b][a] {
        pairs.push((a, b))
      }
    }
  }
  Some(@sym.cat_poset(tt.n, pairs))
}

///|
pub(all) struct FinitePresheafAlexandrovReport {
  valid : Bool
  supported : Bool
  n : Int32
  open_count : Int32
  sieve_counts_by_object : Array[Int32]
  total_local_sieves : Int32
  opposite_category_ok : Bool
  heyting_reports_ok : Bool
  open_restrictions_are_sieves_ok : Bool
  sieve_domains_are_open_ok : Bool
}

///|
fn invalid_presheaf_alexandrov_report(
  n : Int32,
) -> FinitePresheafAlexandrovReport {
  {
    valid: false,
    supported: false,
    n,
    open_count: 0,
    sieve_counts_by_object: [],
    total_local_sieves: 0,
    opposite_category_ok: false,
    heyting_reports_ok: false,
    open_restrictions_are_sieves_ok: false,
    sieve_domains_are_open_ok: false,
  }
}

///|
/// Compare sieves in the opposite thin category of a finite
/// Alexandrov preorder with its open up-sets.
///
/// For an object `c` of the opposite category, an open `U`
/// restricts to the sieve of arrows `y → c` with `y ∈ U`.
/// Conversely, the domains of any such sieve form an open set.
/// This is the exact thin/Alexandrov degeneration of the general
/// sieve construction; it does not identify arbitrary subobjects
/// of representables with global opens.
pub fn finite_presheaf_alexandrov_report(
  tt : @catmath.FinTop,
) -> FinitePresheafAlexandrovReport {
  let opposite = match fintop_opposite_fincat(tt) {
    Some(value) => value
    None => return invalid_presheaf_alexandrov_report(tt.n)
  }
  let opens = match fintop_open_masks(tt) {
    Some(values) => values
    None => return invalid_presheaf_alexandrov_report(tt.n)
  }
  let opposite_category_ok = @sym.is_category(opposite)
  let sieve_counts_by_object : Array[Int32] = []
  let mut total_local_sieves = 0
  let mut heyting_reports_ok = true
  let mut open_restrictions_are_sieves_ok = true
  let mut sieve_domains_are_open_ok = true
  for object in 0..<tt.n {
    let report = finite_presheaf_sieve_report(opposite, object)
    if !report.valid {
      heyting_reports_ok = false
    }
    sieve_counts_by_object.push(report.sieve_count)
    total_local_sieves = total_local_sieves + report.sieve_count
    let incoming = sieve_incoming(opposite, object)
    for open_mask in opens {
      let mut sieve = 0
      for mor in incoming {
        if federation_bit(open_mask, opposite.dom[mor]) {
          sieve = sieve | (1 << mor)
        }
      }
      if !fincat_is_sieve_on(opposite, object, sieve) {
        open_restrictions_are_sieves_ok = false
      }
    }
    for sieve in report.sieves {
      let mut domains = 0
      for mor in incoming {
        if federation_bit(sieve, mor) {
          domains = domains | (1 << opposite.dom[mor])
        }
      }
      if !sieve_contains(opens, domains) {
        sieve_domains_are_open_ok = false
      }
      // Re-restricting the domain open recovers the sieve.
      let mut recovered = 0
      for mor in incoming {
        if federation_bit(domains, opposite.dom[mor]) {
          recovered = recovered | (1 << mor)
        }
      }
      if recovered != sieve {
        sieve_domains_are_open_ok = false
      }
    }
  }
  let valid = opposite_category_ok &&
    heyting_reports_ok &&
    open_restrictions_are_sieves_ok &&
    sieve_domains_are_open_ok
  {
    valid,
    supported: true,
    n: tt.n,
    open_count: opens.length(),
    sieve_counts_by_object,
    total_local_sieves,
    opposite_category_ok,
    heyting_reports_ok,
    open_restrictions_are_sieves_ok,
    sieve_domains_are_open_ok,
  }
}

///|
pub fn check_finite_presheaf_alexandrov(tt : @catmath.FinTop) -> Bool {
  finite_presheaf_alexandrov_report(tt).valid
}
