///|
/// Integration-owned narrow constructor for the closure-dictionary
/// `Category` representation.
///
/// `Category` is `pub`, not `pub(all)`, so packages outside
/// `finalg/cat` cannot construct it with a struct literal.  The
/// five-member `bridge/` layer uses this constructor to expose a
/// finite table category through the same closure interface as
/// `delooping_zn` and `path_category`, without widening the struct.

///|
pub fn[Obj, Hom] category_of(
  id : (Obj) -> Hom,
  src : (Hom) -> Obj,
  tgt : (Hom) -> Obj,
  compose : (Hom, Hom) -> Hom,
  eq : (Hom, Hom) -> Bool,
) -> Category[Obj, Hom] {
  { id, src, tgt, compose, eq, }
}
