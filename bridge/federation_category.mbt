///|
/// Bridges between the three finite-category representations in the
/// federation:
///
/// * symlib `FinCat`: flat composition table, `comp[f*nmor+g] = f∘g`;
/// * catmath `Category`: nested option table, `comp[a][b] = b∘a`;
/// * finalg/cat `Category[Obj, Hom]`: a closure dictionary.
///
/// The first two are exactly interconvertible.  A table category can
/// also be presented through finalg's closure dictionary.  No general
/// reverse conversion from an arbitrary closure category is claimed:
/// its object and morphism types need not be finitely enumerable.

///|
fn federation_index_ok(x : Int32, n : Int32) -> Bool {
  x >= 0 && x < n
}

///|
fn fincat_shape_ok(c : @sym.FinCat) -> Bool {
  guard c.nobj >= 0 && c.nmor >= 0 else { return false }
  guard c.dom.length() == c.nmor && c.cod.length() == c.nmor else {
    return false
  }
  guard c.id.length() == c.nobj else { return false }
  guard c.comp.length() == c.nmor * c.nmor else { return false }
  for mor in 0..<c.nmor {
    guard federation_index_ok(c.dom[mor], c.nobj) else { return false }
    guard federation_index_ok(c.cod[mor], c.nobj) else { return false }
  }
  for obj in 0..<c.nobj {
    guard federation_index_ok(c.id[obj], c.nmor) else { return false }
  }
  for entry in c.comp {
    guard entry == -1 || federation_index_ok(entry, c.nmor) else {
      return false
    }
  }
  true
}

///|
fn catmath_category_shape_ok(c : @catmath.Category) -> Bool {
  let nmor = c.arrows.length()
  guard c.n_obj >= 0 else { return false }
  guard c.id_of_obj.length() == c.n_obj else { return false }
  guard c.comp.length() == nmor else { return false }
  for arrow in c.arrows {
    guard federation_index_ok(arrow.from, c.n_obj) else { return false }
    guard federation_index_ok(arrow.to, c.n_obj) else { return false }
  }
  for identity in c.id_of_obj {
    guard federation_index_ok(identity, nmor) else { return false }
  }
  for row in c.comp {
    guard row.length() == nmor else { return false }
    for entry in row {
      match entry {
        None => ()
        Some(mor) => if !federation_index_ok(mor, nmor) { return false }
      }
    }
  }
  true
}

///|
/// Structural equality of two symlib finite-category tables.
pub fn fincat_tables_equal(a : @sym.FinCat, b : @sym.FinCat) -> Bool {
  guard a.nobj == b.nobj && a.nmor == b.nmor else { return false }
  guard a.dom.length() == b.dom.length() else { return false }
  guard a.cod.length() == b.cod.length() else { return false }
  guard a.id.length() == b.id.length() else { return false }
  guard a.comp.length() == b.comp.length() else { return false }
  for i in 0..<a.dom.length() {
    guard a.dom[i] == b.dom[i] else { return false }
  }
  for i in 0..<a.cod.length() {
    guard a.cod[i] == b.cod[i] else { return false }
  }
  for i in 0..<a.id.length() {
    guard a.id[i] == b.id[i] else { return false }
  }
  for i in 0..<a.comp.length() {
    guard a.comp[i] == b.comp[i] else { return false }
  }
  true
}

///|
/// Convert a symlib table category to catmath's table category.
///
/// The only non-obvious step is transposing the composition table:
/// symlib stores `comp[f*nmor+g] = f∘g`, whereas catmath stores
/// `comp[a][b] = b∘a`.  Hence `catmath[a][b] = symlib[b*nmor+a]`.
pub fn fincat_to_catmath_category(c : @sym.FinCat) -> @catmath.Category? {
  guard fincat_shape_ok(c) else { return None }
  let arrows : Array[@catmath.Arrow] = []
  for mor in 0..<c.nmor {
    arrows.push(@catmath.arrow_of(c.dom[mor], c.cod[mor]))
  }
  let comp : Array[Array[Int32?]] = []
  for a in 0..<c.nmor {
    let row : Array[Int32?] = []
    for b in 0..<c.nmor {
      let composite = c.comp[b * c.nmor + a]
      row.push(if composite < 0 { None } else { Some(composite) })
    }
    comp.push(row)
  }
  Some(@catmath.make_category(c.nobj, arrows, comp, c.id.copy()))
}

///|
/// Convert a catmath table category to symlib's flat table category.
pub fn catmath_category_to_fincat(c : @catmath.Category) -> @sym.FinCat? {
  guard catmath_category_shape_ok(c) else { return None }
  let nmor = c.arrows.length()
  let dom : Array[Int32] = []
  let cod : Array[Int32] = []
  for arrow in c.arrows {
    dom.push(arrow.from)
    cod.push(arrow.to)
  }
  let comp = Array::make(nmor * nmor, -1)
  for f in 0..<nmor {
    for g in 0..<nmor {
      // symlib entry (f,g) is f∘g; catmath entry [g][f] is also f∘g.
      comp[f * nmor + g] = match c.comp[g][f] {
        Some(composite) => composite
        None => -1
      }
    }
  }
  Some({ nobj: c.n_obj, nmor, dom, cod, id: c.id_of_obj.copy(), comp, })
}

///|
/// Present a symlib table category through finalg/cat's generic
/// closure-dictionary category interface, using object and morphism
/// indices as the two carrier types.
///
/// finalg's `compose` field is a total MoonBit function, so calling it
/// on a non-composable pair aborts.  This matches the documented
/// caller obligation of finalg's `assoc_ok`: only type-correct pairs
/// may be composed.
pub fn fincat_to_finalg_category(
  c : @sym.FinCat,
) -> @fcat.Category[Int32, Int32]? {
  guard fincat_shape_ok(c) else { return None }
  Some(
    @fcat.category_of(
      fn(obj : Int32) {
        guard federation_index_ok(obj, c.nobj) else {
          abort("fincat_to_finalg_category: object out of range")
        }
        c.id[obj]
      },
      fn(mor : Int32) {
        guard federation_index_ok(mor, c.nmor) else {
          abort("fincat_to_finalg_category: morphism out of range")
        }
        c.dom[mor]
      },
      fn(mor : Int32) {
        guard federation_index_ok(mor, c.nmor) else {
          abort("fincat_to_finalg_category: morphism out of range")
        }
        c.cod[mor]
      },
      fn(g : Int32, f : Int32) {
        guard federation_index_ok(g, c.nmor) && federation_index_ok(f, c.nmor) else {
          abort("fincat_to_finalg_category: morphism out of range")
        }
        guard c.cod[f] == c.dom[g] else {
          abort("fincat_to_finalg_category: morphisms are not composable")
        }
        let composite = c.comp[g * c.nmor + f]
        guard composite >= 0 else {
          abort("fincat_to_finalg_category: composition table is incomplete")
        }
        composite
      },
      fn(a : Int32, b : Int32) { a == b },
    ),
  )
}

///|
/// Present a catmath table category through finalg/cat's closure
/// interface, by way of the exact symlib table conversion.
pub fn catmath_category_to_finalg_category(
  c : @catmath.Category,
) -> @fcat.Category[Int32, Int32]? {
  match catmath_category_to_fincat(c) {
    Some(table) => fincat_to_finalg_category(table)
    None => None
  }
}

///|
/// Exhaustively check finalg's associativity and unit predicates for
/// the closure-category presentation of one finite table category.
/// Cost is cubic in the number of morphisms.
pub fn fincat_finalg_category_laws(c : @sym.FinCat) -> Bool {
  let category = match fincat_to_finalg_category(c) {
    Some(category) => category
    None => return false
  }
  for f in 0..<c.nmor {
    guard @fcat.unit_ok(category, f) else { return false }
  }
  for f in 0..<c.nmor {
    for g in 0..<c.nmor {
      for h in 0..<c.nmor {
        if c.cod[f] == c.dom[g] && c.cod[g] == c.dom[h] {
          guard @fcat.assoc_ok(category, f, g, h) else { return false }
        }
      }
    }
  }
  true
}
