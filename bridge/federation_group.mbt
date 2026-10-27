///|
/// Finite-group bridges between catmath Cayley tables and symlib
/// permutation groups.
///
/// The Cayley embedding sends a group element `a` to left
/// multiplication `L_a(x) = a*x`.  With symlib's convention
/// `p.compose(q) = p∘q`, this is a homomorphism:
/// `L_a ∘ L_b = L_(a*b)`.

///|
fn fin_group_shape_ok(g : @catmath.FinGroup) -> Bool {
  guard g.order > 0 else { return false }
  guard g.mul.length() == g.order else { return false }
  guard g.inv.length() == g.order else { return false }
  guard g.e >= 0 && g.e < g.order else { return false }
  for row in g.mul {
    guard row.length() == g.order else { return false }
    for entry in row {
      guard entry >= 0 && entry < g.order else { return false }
    }
  }
  for entry in g.inv {
    guard entry >= 0 && entry < g.order else { return false }
  }
  true
}

///|
fn perm_index_of(elems : Array[@sym.Perm], needle : @sym.Perm) -> Int32 {
  for i in 0..<elems.length() {
    if elems[i].equal(needle) {
      return i
    }
  }
  -1
}

///|
/// Cayley-embed a catmath finite group as a symlib permutation group
/// on its own underlying set.  The input table is first checked with
/// catmath's exhaustive group-axiom checker.
pub fn catmath_fin_group_to_symlib_perm_group(
  g : @catmath.FinGroup,
) -> @sym.PermGroup? {
  guard fin_group_shape_ok(g) else { return None }
  guard @catmath.check_group(g) else { return None }
  let generators : Array[@sym.Perm] = []
  for a in 0..<g.order {
    let image : Array[Int32] = []
    for x in 0..<g.order {
      image.push(g.mul[a][x])
    }
    generators.push(@sym.Perm::from_img(image))
  }
  let embedded = @sym.PermGroup::new(g.order, generators)
  guard embedded.order() == g.order.to_int64() else { return None }
  Some(embedded)
}

///|
/// Enumerate a small symlib permutation group and return its Cayley
/// table as a catmath finite group.  `cap` bounds the group order;
/// larger groups return `None` rather than being silently truncated.
///
/// The table operation is permutation composition in symlib's order:
/// entry `(i,j)` is the index of `elements[i] ∘ elements[j]`.
pub fn symlib_perm_group_to_catmath_fin_group(
  group : @sym.PermGroup,
  cap : Int32,
) -> @catmath.FinGroup? {
  guard cap > 0 else { return None }
  guard group.order() <= cap.to_int64() else { return None }
  let elems = group.elements(cap)
  guard elems.length().to_int64() == group.order() else { return None }
  let mut identity = -1
  for i in 0..<elems.length() {
    if elems[i].is_identity() {
      identity = i
    }
  }
  guard identity >= 0 else { return None }
  let mul : Array[Array[Int32]] = []
  for i in 0..<elems.length() {
    let row : Array[Int32] = []
    for j in 0..<elems.length() {
      let product = elems[i].compose(elems[j])
      let index = perm_index_of(elems, product)
      guard index >= 0 else { return None }
      row.push(index)
    }
    mul.push(row)
  }
  let inv : Array[Int32] = []
  for elem in elems {
    let index = perm_index_of(elems, elem.inverse())
    guard index >= 0 else { return None }
    inv.push(index)
  }
  let table = @catmath.fin_group_of(
    elems.length(),
    mul,
    inv,
    identity,
    "PermGroup(n=\{group.size()}, order=\{elems.length()})",
  )
  guard @catmath.check_group(table) else { return None }
  Some(table)
}
