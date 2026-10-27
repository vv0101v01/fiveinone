///|
/// The common simply typed lambda-calculus fragment of the
/// cubical and catmath pillars.
///
/// The correspondence is deliberately narrow:
///
/// * catmath `SAtom` is sent to the one chosen cubical base type
///   `LBool`.  This is an atom-to-atom renaming, not a claim that
///   the atom has Boolean literals; consequently cubical
///   `TmBool` has no catmath counterpart and is rejected on the
///   way back.
/// * `SOne`, products and arrows correspond to `LUnit`, `LProd`
///   and `LFun`.
/// * cubical coercion terms `TmCoeRefl` / `TmCoeUaSwap` are
///   outside catmath STLC and are rejected.
/// * de Bruijn indices agree (0 is the newest binder), but the
///   *context arrays do not*: catmath appends binders, whereas
///   cubical stores the newest binder first.  Contexts are
///   therefore reversed.
/// * catmath's `SLam` carries a domain annotation; cubical
///   `TmLam` does not.  Erasure is used in one direction and a
///   type-directed reconstruction in the other.
///
/// There is also one genuine normal-form difference.  cubical
/// `nf_eta` implements unit η (every term of unit type quotes as
/// `TmUnit`); catmath's `eta_long` expands functions and products
/// but leaves a neutral term of type `SOne` untouched.  The
/// report therefore keeps catmath's raw normal form and a
/// separately named unit-η completion.  Claiming raw equality in
/// all cases would be false.

///|
/// Map a catmath STLC type to the corresponding cubical `LTy`,
/// with `SAtom` sent to the chosen atom `LBool`.
pub fn catmath_stype_to_cubical_lty(ty : @catmath.SType) -> @cub.LTy {
  match ty {
    @catmath.SType::SAtom => @cub.lty_bool_ctor()
    @catmath.SType::SOne => @cub.lty_unit_ctor()
    @catmath.SType::SArrow(a, b) =>
      @cub.lty_fun_ctor(
        catmath_stype_to_cubical_lty(a),
        catmath_stype_to_cubical_lty(b),
      )
    @catmath.SType::SPair(a, b) =>
      @cub.lty_prod_ctor(
        catmath_stype_to_cubical_lty(a),
        catmath_stype_to_cubical_lty(b),
      )
  }
}

///|
/// Map a cubical `LTy` back to catmath, with `LBool` read as the
/// selected atom.
pub fn cubical_lty_to_catmath_stype(ty : @cub.LTy) -> @catmath.SType {
  match ty {
    @cub.LTy::LBool => @catmath.stype_atom()
    @cub.LTy::LUnit => @catmath.stype_one()
    @cub.LTy::LProd(a, b) =>
      @catmath.stype_pair(
        cubical_lty_to_catmath_stype(a),
        cubical_lty_to_catmath_stype(b),
      )
    @cub.LTy::LFun(a, b) =>
      @catmath.stype_arrow(
        cubical_lty_to_catmath_stype(a),
        cubical_lty_to_catmath_stype(b),
      )
  }
}

///|
/// Structural equality of catmath STLC types (catmath's own
/// equality helper is package-private).
pub fn catmath_stype_equal(a : @catmath.SType, b : @catmath.SType) -> Bool {
  match (a, b) {
    (@catmath.SType::SAtom, @catmath.SType::SAtom) => true
    (@catmath.SType::SOne, @catmath.SType::SOne) => true
    (@catmath.SType::SArrow(a1, b1), @catmath.SType::SArrow(a2, b2)) =>
      catmath_stype_equal(a1, a2) && catmath_stype_equal(b1, b2)
    (@catmath.SType::SPair(a1, b1), @catmath.SType::SPair(a2, b2)) =>
      catmath_stype_equal(a1, a2) && catmath_stype_equal(b1, b2)
    _ => false
  }
}

///|
/// Structural equality of catmath STLC terms.
pub fn catmath_sterm_equal(a : @catmath.STerm, b : @catmath.STerm) -> Bool {
  match (a, b) {
    (@catmath.STerm::SVar(i), @catmath.STerm::SVar(j)) => i == j
    (@catmath.STerm::SUnit, @catmath.STerm::SUnit) => true
    (@catmath.STerm::SPair(a1, b1), @catmath.STerm::SPair(a2, b2)) =>
      catmath_sterm_equal(a1, a2) && catmath_sterm_equal(b1, b2)
    (@catmath.STerm::SFst(t1), @catmath.STerm::SFst(t2)) =>
      catmath_sterm_equal(t1, t2)
    (@catmath.STerm::SSnd(t1), @catmath.STerm::SSnd(t2)) =>
      catmath_sterm_equal(t1, t2)
    (@catmath.STerm::SLam(ty1, body1), @catmath.STerm::SLam(ty2, body2)) =>
      catmath_stype_equal(ty1, ty2) && catmath_sterm_equal(body1, body2)
    (@catmath.STerm::SApp(f1, a1), @catmath.STerm::SApp(f2, a2)) =>
      catmath_sterm_equal(f1, f2) && catmath_sterm_equal(a1, a2)
    _ => false
  }
}

///|
fn reverse_catmath_context(
  ctx : Array[@catmath.SType],
) -> Array[@catmath.SType] {
  let out : Array[@catmath.SType] = []
  let mut i = ctx.length() - 1
  while i >= 0 {
    out.push(ctx[i])
    i = i - 1
  }
  out
}

///|
fn cons_catmath_context(
  ty : @catmath.SType,
  ctx : Array[@catmath.SType],
) -> Array[@catmath.SType] {
  let out : Array[@catmath.SType] = [ty]
  for old in ctx {
    out.push(old)
  }
  out
}

///|
/// Convert a catmath context (oldest binder first) to the cubical
/// convention (newest binder first), mapping every type.
pub fn catmath_context_to_cubical_context(
  ctx : Array[@catmath.SType],
) -> Array[@cub.LTy] {
  let out : Array[@cub.LTy] = []
  let mut i = ctx.length() - 1
  while i >= 0 {
    out.push(catmath_stype_to_cubical_lty(ctx[i]))
    i = i - 1
  }
  out
}

///|
/// Erase a catmath STLC term to the common cubical term fragment.
/// Lambda domain annotations are erased; de Bruijn indices are
/// unchanged.
pub fn catmath_sterm_to_cubical_term(term : @catmath.STerm) -> @cub.Term {
  match term {
    @catmath.STerm::SVar(i) => @cub.tm_var_ctor(i)
    @catmath.STerm::SUnit => @cub.tm_unit_ctor()
    @catmath.STerm::SPair(a, b) =>
      @cub.tm_pair_ctor(
        catmath_sterm_to_cubical_term(a),
        catmath_sterm_to_cubical_term(b),
      )
    @catmath.STerm::SFst(t) =>
      @cub.tm_fst_ctor(catmath_sterm_to_cubical_term(t))
    @catmath.STerm::SSnd(t) =>
      @cub.tm_snd_ctor(catmath_sterm_to_cubical_term(t))
    @catmath.STerm::SLam(_ty, body) =>
      @cub.tm_lam_ctor(catmath_sterm_to_cubical_term(body))
    @catmath.STerm::SApp(f, a) =>
      @cub.tm_app_ctor(
        catmath_sterm_to_cubical_term(f),
        catmath_sterm_to_cubical_term(a),
      )
  }
}

///|
fn cubical_neutral_to_catmath(
  term : @cub.Term,
  ctx : Array[@catmath.SType],
) -> (@catmath.STerm, @catmath.SType)? {
  match term {
    @cub.Term::TmVar(i) => {
      guard i >= 0 && i < ctx.length() else { return None }
      Some((@catmath.sterm_var_of(i), ctx[i]))
    }
    @cub.Term::TmApp(f, a) => {
      let (sf, fty) = match cubical_neutral_to_catmath(f, ctx) {
        Some(pair) => pair
        None => return None
      }
      match fty {
        @catmath.SType::SArrow(dom, cod) => {
          let sa = match cubical_eta_to_catmath(a, dom, ctx) {
            Some(arg) => arg
            None => return None
          }
          Some((@catmath.sterm_app_of(sf, sa), cod))
        }
        _ => None
      }
    }
    @cub.Term::TmFst(t) => {
      let (st, ty) = match cubical_neutral_to_catmath(t, ctx) {
        Some(pair) => pair
        None => return None
      }
      match ty {
        @catmath.SType::SPair(a, _b) => Some((@catmath.sterm_fst_of(st), a))
        _ => None
      }
    }
    @cub.Term::TmSnd(t) => {
      let (st, ty) = match cubical_neutral_to_catmath(t, ctx) {
        Some(pair) => pair
        None => return None
      }
      match ty {
        @catmath.SType::SPair(_a, b) => Some((@catmath.sterm_snd_of(st), b))
        _ => None
      }
    }
    @cub.Term::TmUnit => Some((@catmath.sterm_unit(), @catmath.stype_one()))
    @cub.Term::TmAnn(inner, ty) => {
      let expected = cubical_lty_to_catmath_stype(ty)
      match cubical_eta_to_catmath(inner, expected, ctx) {
        Some(st) => Some((st, expected))
        None => None
      }
    }
    _ => None
  }
}

///|
fn cubical_eta_to_catmath(
  term : @cub.Term,
  expected : @catmath.SType,
  ctx : Array[@catmath.SType],
) -> @catmath.STerm? {
  match term {
    @cub.Term::TmAnn(inner, _ty) => cubical_eta_to_catmath(inner, expected, ctx)
    _ =>
      match expected {
        @catmath.SType::SOne =>
          match term {
            @cub.Term::TmUnit => Some(@catmath.sterm_unit())
            _ => None
          }
        @catmath.SType::SArrow(dom, cod) =>
          match term {
            @cub.Term::TmLam(body) =>
              match
                cubical_eta_to_catmath(
                  body,
                  cod,
                  cons_catmath_context(dom, ctx),
                ) {
                Some(sbody) => Some(@catmath.sterm_lam_of(dom, sbody))
                None => None
              }
            _ => None
          }
        @catmath.SType::SPair(a, b) =>
          match term {
            @cub.Term::TmPair(x, y) =>
              match
                (
                  cubical_eta_to_catmath(x, a, ctx),
                  cubical_eta_to_catmath(y, b, ctx),
                ) {
                (Some(sx), Some(sy)) => Some(@catmath.sterm_pair_of(sx, sy))
                _ => None
              }
            _ => None
          }
        @catmath.SType::SAtom =>
          match cubical_neutral_to_catmath(term, ctx) {
            Some((st, ty)) =>
              if catmath_stype_equal(ty, expected) {
                Some(st)
              } else {
                None
              }
            None => None
          }
      }
  }
}

///|
/// Type-directed translation of a cubical η-long normal form (as
/// produced by `nf_eta`) back to catmath STLC.
///
/// `ctx` uses catmath's native order (oldest binder first).
/// Boolean literals and coercion terms are outside the common
/// fragment and yield `None`; a non-η-long term at a function or
/// product type is likewise rejected rather than silently
/// η-expanded by this adapter.
pub fn cubical_eta_long_term_to_catmath(
  term : @cub.Term,
  expected : @catmath.SType,
  ctx : Array[@catmath.SType],
) -> @catmath.STerm? {
  cubical_eta_to_catmath(term, expected, reverse_catmath_context(ctx))
}

///|
fn catmath_neutral_unit_complete(
  term : @catmath.STerm,
  ctx : Array[@catmath.SType],
) -> (@catmath.STerm, @catmath.SType)? {
  match term {
    @catmath.STerm::SVar(i) => {
      guard i >= 0 && i < ctx.length() else { return None }
      Some((term, ctx[i]))
    }
    @catmath.STerm::SApp(f, a) => {
      let (sf, fty) = match catmath_neutral_unit_complete(f, ctx) {
        Some(pair) => pair
        None => return None
      }
      match fty {
        @catmath.SType::SArrow(dom, cod) =>
          match catmath_eta_unit_complete(a, dom, ctx) {
            Some(sa) => Some((@catmath.sterm_app_of(sf, sa), cod))
            None => None
          }
        _ => None
      }
    }
    @catmath.STerm::SFst(t) => {
      let (st, ty) = match catmath_neutral_unit_complete(t, ctx) {
        Some(pair) => pair
        None => return None
      }
      match ty {
        @catmath.SType::SPair(a, _b) => Some((@catmath.sterm_fst_of(st), a))
        _ => None
      }
    }
    @catmath.STerm::SSnd(t) => {
      let (st, ty) = match catmath_neutral_unit_complete(t, ctx) {
        Some(pair) => pair
        None => return None
      }
      match ty {
        @catmath.SType::SPair(_a, b) => Some((@catmath.sterm_snd_of(st), b))
        _ => None
      }
    }
    @catmath.STerm::SUnit => Some((term, @catmath.stype_one()))
    _ => None
  }
}

///|
fn catmath_eta_unit_complete(
  term : @catmath.STerm,
  expected : @catmath.SType,
  ctx : Array[@catmath.SType],
) -> @catmath.STerm? {
  match expected {
    @catmath.SType::SOne => Some(@catmath.sterm_unit())
    @catmath.SType::SArrow(dom, cod) =>
      match term {
        @catmath.STerm::SLam(pty, body) =>
          if catmath_stype_equal(pty, dom) {
            match
              catmath_eta_unit_complete(
                body,
                cod,
                cons_catmath_context(dom, ctx),
              ) {
              Some(sbody) => Some(@catmath.sterm_lam_of(dom, sbody))
              None => None
            }
          } else {
            None
          }
        _ => None
      }
    @catmath.SType::SPair(a, b) =>
      match term {
        @catmath.STerm::SPair(x, y) =>
          match
            (
              catmath_eta_unit_complete(x, a, ctx),
              catmath_eta_unit_complete(y, b, ctx),
            ) {
            (Some(sx), Some(sy)) => Some(@catmath.sterm_pair_of(sx, sy))
            _ => None
          }
        _ => None
      }
    @catmath.SType::SAtom =>
      match catmath_neutral_unit_complete(term, ctx) {
        Some((st, ty)) =>
          if catmath_stype_equal(ty, expected) {
            Some(st)
          } else {
            None
          }
        None => None
      }
  }
}

///|
/// Apply the missing terminal-object η rule to a catmath
/// β/function/product-η long normal form: every subterm whose
/// expected type is `SOne` is replaced by `SUnit`.
///
/// The input is first rechecked with catmath's own inference at
/// `expected` in `ctx` (catmath order).  This is a bridge-level
/// completion of catmath's normal form, not a change to catmath.
pub fn catmath_sterm_unit_eta_complete(
  term : @catmath.STerm,
  expected : @catmath.SType,
  ctx : Array[@catmath.SType],
) -> @catmath.STerm? {
  let inferred = match @catmath.stlc_infer(ctx, term) {
    Some(ty) => ty
    None => return None
  }
  guard catmath_stype_equal(inferred, expected) else { return None }
  catmath_eta_unit_complete(term, expected, reverse_catmath_context(ctx))
}

///|
/// Cross-member report for one catmath STLC term in a context.
pub(all) struct StlcFederationReport {
  valid : Bool
  inferred_type : @catmath.SType
  catmath_normal_form : @catmath.STerm
  catmath_unit_eta_completed_normal_form : @catmath.STerm
  cubical_normal_form : @cub.Term
  cubical_normal_form_in_catmath : @catmath.STerm
  raw_normal_forms_equal : Bool
  unit_eta_completion_needed : Bool
  completed_normal_forms_equal : Bool
  type_preserved_ok : Bool
  cubical_eta_equality_ok : Bool
  catmath_normal_form_idempotent_ok : Bool
}

///|
fn invalid_stlc_federation_report() -> StlcFederationReport {
  {
    valid: false,
    inferred_type: @catmath.stype_one(),
    catmath_normal_form: @catmath.sterm_unit(),
    catmath_unit_eta_completed_normal_form: @catmath.sterm_unit(),
    cubical_normal_form: @cub.tm_unit_ctor(),
    cubical_normal_form_in_catmath: @catmath.sterm_unit(),
    raw_normal_forms_equal: false,
    unit_eta_completion_needed: false,
    completed_normal_forms_equal: false,
    type_preserved_ok: false,
    cubical_eta_equality_ok: false,
    catmath_normal_form_idempotent_ok: false,
  }
}

///|
/// Build the STLC commuting diagram:
///
/// `catmath term --erase--> cubical term --nf_eta--> cubical nf
/// --typed back-translation--> catmath term`
///
/// is compared both with catmath's raw `stlc_beta_eta_nf` and with
/// its unit-η completion.  `ctx` is in catmath's native order.
pub fn stlc_federation_report(
  ctx : Array[@catmath.SType],
  term : @catmath.STerm,
) -> StlcFederationReport {
  let inferred = match @catmath.stlc_infer(ctx, term) {
    Some(ty) => ty
    None => return invalid_stlc_federation_report()
  }
  let catmath_nf = @catmath.stlc_beta_eta_nf(term, inferred)
  let completed_nf = match
    catmath_sterm_unit_eta_complete(catmath_nf, inferred, ctx) {
    Some(nf) => nf
    None => return invalid_stlc_federation_report()
  }
  let cubical_term = catmath_sterm_to_cubical_term(term)
  let cubical_type = catmath_stype_to_cubical_lty(inferred)
  let cubical_ctx = catmath_context_to_cubical_context(ctx)
  let cubical_nf = match @cub.nf_eta(cubical_term, cubical_type, cubical_ctx) {
    Some(nf) => nf
    None => return invalid_stlc_federation_report()
  }
  let back = match cubical_eta_long_term_to_catmath(cubical_nf, inferred, ctx) {
    Some(st) => st
    None => return invalid_stlc_federation_report()
  }
  let raw_equal = catmath_sterm_equal(back, catmath_nf)
  let completed_equal = catmath_sterm_equal(back, completed_nf)
  let completion_needed = !catmath_sterm_equal(catmath_nf, completed_nf)
  let back_type_ok = match @catmath.stlc_infer(ctx, back) {
    Some(ty) => catmath_stype_equal(ty, inferred)
    None => false
  }
  let completed_type_ok = match @catmath.stlc_infer(ctx, completed_nf) {
    Some(ty) => catmath_stype_equal(ty, inferred)
    None => false
  }
  let type_preserved_ok = back_type_ok && completed_type_ok
  let cubical_eta_equality_ok = @cub.def_eq_eta(
    cubical_term, cubical_nf, cubical_type, cubical_ctx,
  )
  let catmath_idempotent_ok = catmath_sterm_equal(
    @catmath.stlc_beta_eta_nf(catmath_nf, inferred),
    catmath_nf,
  )
  let valid = completed_equal &&
    type_preserved_ok &&
    cubical_eta_equality_ok &&
    catmath_idempotent_ok
  {
    valid,
    inferred_type: inferred,
    catmath_normal_form: catmath_nf,
    catmath_unit_eta_completed_normal_form: completed_nf,
    cubical_normal_form: cubical_nf,
    cubical_normal_form_in_catmath: back,
    raw_normal_forms_equal: raw_equal,
    unit_eta_completion_needed: completion_needed,
    completed_normal_forms_equal: completed_equal,
    type_preserved_ok,
    cubical_eta_equality_ok,
    catmath_normal_form_idempotent_ok: catmath_idempotent_ok,
  }
}

///|
/// Whether the two STLC implementations agree on this term after
/// the explicitly recorded unit-η completion of catmath's normal
/// form.
pub fn check_stlc_federation(
  ctx : Array[@catmath.SType],
  term : @catmath.STerm,
) -> Bool {
  stlc_federation_report(ctx, term).valid
}
