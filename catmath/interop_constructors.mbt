///|
/// Integration-owned narrow constructors.
///
/// Most catmath public structs are intentionally only `pub`, not
/// `pub(all)`: other packages may read their fields but cannot use a
/// struct literal to construct them.  These constructors expose just
/// the representations needed by the five-member `bridge/` layer and
/// by `cmd/catmath`; they do not change any catmath algorithm or widen
/// the underlying representations to `pub(all)`.

///|
fn copy_int_rows(rows : Array[Array[Int32]]) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  for row in rows {
    out.push(row.copy())
  }
  out
}

///|
/// Construct one finite-category arrow `from -> to`.
pub fn arrow_of(from : Int32, to : Int32) -> Arrow {
  Arrow::{ from, to, }
}

///|
/// Construct a finite group from an explicit Cayley table.  The table
/// is deep-copied; callers should use `check_group` when the input is
/// not already known to satisfy the group axioms.
pub fn fin_group_of(
  order : Int32,
  mul : Array[Array[Int32]],
  inv : Array[Int32],
  e : Int32,
  name : String,
) -> FinGroup {
  { order, mul: copy_int_rows(mul), inv: inv.copy(), e, name, }
}

///|
/// Construct a finite monoid from an explicit multiplication table.
pub fn fin_monoid_of(
  order : Int32,
  mul : Array[Array[Int32]],
  e : Int32,
  name : String,
) -> FinMonoid {
  { order, mul: copy_int_rows(mul), e, name, }
}

///|
/// Construct the free monoid on `alphabet` generators.
pub fn free_monoid_of(alphabet : Int32) -> FreeMonoid {
  FreeMonoid::{ alphabet, }
}

///|
/// Construct a finite G-set from an explicit action table
/// (`action[g][x] = g·x`).  The table is deep-copied; callers should
/// use `check_gset` when the action axioms are not already known.
pub fn gset_of(
  group : FinGroup,
  elements : Int32,
  action : Array[Array[Int32]],
) -> GSet {
  { group, elements, action: copy_int_rows(action), }
}

///|
/// Construct a chain complex over `F_p` from its differentials
/// (`diff[k] = ∂_{k+1}`).  Every matrix is deep-copied; callers
/// should use `check_chain_complex` for untrusted input.
pub fn chain_complex_of(p : Int32, diff : Array[Mat]) -> ChainComplex {
  let copied : Array[Mat] = []
  for m in diff {
    copied.push({
      rows: m.rows,
      cols: m.cols,
      p: m.p,
      data: copy_int_rows(m.data),
    })
  }
  { p, diff: copied, }
}

///|
/// The atomic STLC type.
pub fn stype_atom() -> SType {
  SAtom
}

///|
/// The unit STLC type.
pub fn stype_one() -> SType {
  SOne
}

///|
/// Construct an STLC function type.
pub fn stype_arrow(dom : SType, cod : SType) -> SType {
  SArrow(dom, cod)
}

///|
/// Construct an STLC product type.
pub fn stype_pair(fst : SType, snd : SType) -> SType {
  SPair(fst, snd)
}

///|
/// Construct an STLC de Bruijn variable.
pub fn sterm_var_of(index : Int32) -> STerm {
  SVar(index)
}

///|
/// The STLC unit term.
pub fn sterm_unit() -> STerm {
  SUnit
}

///|
/// Construct an STLC pair term.
pub fn sterm_pair_of(fst : STerm, snd : STerm) -> STerm {
  SPair(fst, snd)
}

///|
/// Construct an STLC first projection.
pub fn sterm_fst_of(term : STerm) -> STerm {
  SFst(term)
}

///|
/// Construct an STLC second projection.
pub fn sterm_snd_of(term : STerm) -> STerm {
  SSnd(term)
}

///|
/// Construct a domain-annotated STLC lambda term.
pub fn sterm_lam_of(dom : SType, body : STerm) -> STerm {
  SLam(dom, body)
}

///|
/// Construct an STLC application.
pub fn sterm_app_of(fun : STerm, arg : STerm) -> STerm {
  SApp(fun, arg)
}

///|
/// Construct an integer matrix for the Smith-normal-form routines.
/// The data rows are deep-copied because `snf_int` normalizes in place.
pub fn int_mat_of(
  rows : Int32,
  cols : Int32,
  data : Array[Array[Int32]],
) -> IntMat {
  { rows, cols, data: copy_int_rows(data), }
}
