///|
/// Integration-owned narrow constructors for the typed NbE STLC
/// fragment.
///
/// `LTy` and `Term` remain ordinary `pub` (read-only across
/// packages), not `pub(all)`.  These functions expose only the
/// constructors needed by `bridge/` to build the common STLC
/// fragment; coercion terms are intentionally not exposed here.

///|
pub fn lty_bool_ctor() -> LTy {
  LBool
}

///|
pub fn lty_unit_ctor() -> LTy {
  LUnit
}

///|
pub fn lty_prod_ctor(a : LTy, b : LTy) -> LTy {
  LProd(a, b)
}

///|
pub fn lty_fun_ctor(a : LTy, b : LTy) -> LTy {
  LFun(a, b)
}

///|
pub fn tm_var_ctor(i : Int32) -> Term {
  TmVar(i)
}

///|
pub fn tm_lam_ctor(body : Term) -> Term {
  TmLam(body)
}

///|
pub fn tm_app_ctor(f : Term, a : Term) -> Term {
  TmApp(f, a)
}

///|
pub fn tm_pair_ctor(a : Term, b : Term) -> Term {
  TmPair(a, b)
}

///|
pub fn tm_fst_ctor(t : Term) -> Term {
  TmFst(t)
}

///|
pub fn tm_snd_ctor(t : Term) -> Term {
  TmSnd(t)
}

///|
pub fn tm_unit_ctor() -> Term {
  TmUnit
}
