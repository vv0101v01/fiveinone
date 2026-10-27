// ==================================================================
// Case-split conversion on discrete (Bool) context variables.
//
// The kernel's semantic conversion compares neutral forms at
// discrete types structurally: `if x then 0 else 0` and `0`
// are not convertible for a neutral Bool variable `x`, even
// though they agree under both substitutions.  Bool is a
// discrete cubical type -- its elements over any cube are
// constants -- so conversion may legitimately case-split on
// Bool *variables*: two terms in a telescope context are
// convertible if they are convertible after substituting
// `true` and after substituting `false` for some Bool
// variable they mention.  This file implements that
// strengthening at the term level (`conv_terms_case_split`):
// it first tries ordinary conversion in the fresh-neutral
// interpretation of the context, then recursively splits on
// Bool variables (dependent types and later context entries
// are substituted along).  Split candidates are guided by
// the quoted normal forms (Phase 13): only Bool variables
// occurring in subterms where the two normal forms actually
// differ are split (falling back to all mentioned Bool
// variables when the difference is empty), which keeps the
// exponential search away from irrelevant hypotheses.
// Variables of other types are never split (Nat would need
// infinitely many cases), and the search is bounded by the
// number of Bool variables in the context, each split
// removing one.
// ==================================================================

///|
fn cs_mentions_var(t : DTerm, index : Int32) -> Bool {
  let mut found = false
  ignore(
    dterm_map_vars_at(t, 0, (v, depth) => {
      if v - depth == index {
        found = true
      }
      DTVar(v)
    }),
  )
  found
}

///|
fn cs_eval_ctx(ctx : Array[DTerm]) -> (DEnv, Array[DValue]) {
  let values : Array[DValue] = []
  let types : Array[DValue] = []
  for i in 0..<ctx.length() {
    types.push(
      force_value(
        deval_dim(ctx[i], denv_extend(values, denv_empty()), ddim_empty()),
      ),
    )
    values.push(DVNeutral(DNVar(i)))
  }
  (denv_extend(values, denv_empty()), types)
}

///|
/// Outcome and search statistics of `conv_terms_case_split`.
pub struct CaseSplitReport {
  holds : Bool
  split_nodes : Int32
  probes : Int32
  root_difference_variables : Int32
}

///|
priv struct CsStats {
  mut split_nodes : Int32
  mut probes : Int32
}

///|
fn cs_collect_bool_vars(
  is_bool : Array[Bool],
  n : Int32,
  t : DTerm,
  acc : Array[Int32],
) -> Unit {
  ignore(
    dterm_map_vars_at(t, 0, (v, depth) => {
      let index = v - depth
      if index >= 0 {
        let lvl = n - 1 - index
        if lvl >= 0 && lvl < n && is_bool[lvl] && !acc.contains(lvl) {
          acc.push(lvl)
        }
      }
      DTVar(v)
    }),
  )
}

///|
fn cs_diff_leaf(
  is_bool : Array[Bool],
  n : Int32,
  a : DTerm,
  b : DTerm,
  acc : Array[Int32],
) -> Unit {
  if a != b {
    cs_collect_bool_vars(is_bool, n, a, acc)
    cs_collect_bool_vars(is_bool, n, b, acc)
  }
}

///|
/// Bool context levels occurring in subterms where the two
/// normal forms differ.  Congruence recursion descends
/// through non-binding constructors; anything else (binders,
/// head mismatch) contributes all Bool variables of both
/// subterms, so the result is a safe over-approximation of
/// the variables a split could need to touch.
fn cs_diff_vars_go(
  is_bool : Array[Bool],
  n : Int32,
  a : DTerm,
  b : DTerm,
  acc : Array[Int32],
) -> Unit {
  if a == b {
    return
  }
  match (a, b) {
    (DApp(f, x), DApp(g, y)) => {
      cs_diff_vars_go(is_bool, n, f, g, acc)
      cs_diff_vars_go(is_bool, n, x, y, acc)
    }
    (DPair(x1, x2), DPair(y1, y2)) => {
      cs_diff_vars_go(is_bool, n, x1, y1, acc)
      cs_diff_vars_go(is_bool, n, x2, y2, acc)
    }
    (DFst(x), DFst(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DSnd(x), DSnd(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DSucc(x), DSucc(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DCons(x1, x2), DCons(y1, y2)) => {
      cs_diff_vars_go(is_bool, n, x1, y1, acc)
      cs_diff_vars_go(is_bool, n, x2, y2, acc)
    }
    (DListTy(x), DListTy(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DAnn(x1, x2), DAnn(y1, y2)) => {
      cs_diff_vars_go(is_bool, n, x1, y1, acc)
      cs_diff_vars_go(is_bool, n, x2, y2, acc)
    }
    (DEquivTy(x1, x2), DEquivTy(y1, y2)) => {
      cs_diff_vars_go(is_bool, n, x1, y1, acc)
      cs_diff_vars_go(is_bool, n, x2, y2, acc)
    }
    (DEquivFwd(x), DEquivFwd(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DEquivBwd(x), DEquivBwd(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DEquivSect(x), DEquivSect(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DEquivRetr(x), DEquivRetr(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DUa(x), DUa(y)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DAppDim(x, _), DAppDim(y, _)) => cs_diff_vars_go(is_bool, n, x, y, acc)
    (DBoolElim(m1, t1, e1, s1), DBoolElim(m2, t2, e2, s2)) => {
      cs_diff_leaf(is_bool, n, m1, m2, acc)
      cs_diff_vars_go(is_bool, n, t1, t2, acc)
      cs_diff_vars_go(is_bool, n, e1, e2, acc)
      cs_diff_vars_go(is_bool, n, s1, s2, acc)
    }
    (DNatElim(m1, z1, st1, s1), DNatElim(m2, z2, st2, s2)) => {
      cs_diff_leaf(is_bool, n, m1, m2, acc)
      cs_diff_leaf(is_bool, n, st1, st2, acc)
      cs_diff_vars_go(is_bool, n, z1, z2, acc)
      cs_diff_vars_go(is_bool, n, s1, s2, acc)
    }
    (DListElim(m1, n1, c1, s1), DListElim(m2, n2, c2, s2)) => {
      cs_diff_leaf(is_bool, n, m1, m2, acc)
      cs_diff_leaf(is_bool, n, c1, c2, acc)
      cs_diff_vars_go(is_bool, n, n1, n2, acc)
      cs_diff_vars_go(is_bool, n, s1, s2, acc)
    }
    (DCircleElim(m1, b1, l1, s1), DCircleElim(m2, b2, l2, s2)) => {
      cs_diff_leaf(is_bool, n, m1, m2, acc)
      cs_diff_vars_go(is_bool, n, b1, b2, acc)
      cs_diff_vars_go(is_bool, n, l1, l2, acc)
      cs_diff_vars_go(is_bool, n, s1, s2, acc)
    }
    _ => cs_diff_leaf(is_bool, n, a, b, acc)
  }
}

///|
fn cs_difference_variables(
  ctx : Array[DTerm],
  types : Array[DValue],
  ty_value : DValue,
  va : DValue,
  vb : DValue,
) -> Array[Int32] {
  let n = ctx.length()
  let is_bool : Array[Bool] = []
  for i in 0..<n {
    is_bool.push(
      match types[i] {
        DVBoolTy => true
        _ => false
      },
    )
  }
  let acc : Array[Int32] = []
  cs_diff_vars_go(
    is_bool,
    n,
    quote_at(n, 0, ty_value, va),
    quote_at(n, 0, ty_value, vb),
    acc,
  )
  // Declaration order.
  let out : Array[Int32] = []
  for i in 0..<n {
    if acc.contains(i) {
      out.push(i)
    }
  }
  out
}

///|
fn cs_conv_go(
  ctx : Array[DTerm],
  ty : DTerm,
  a : DTerm,
  b : DTerm,
  stats : CsStats,
) -> Bool {
  let (env, types) = cs_eval_ctx(ctx)
  let ty_value = deval_dim(ty, env, ddim_empty())
  let va = deval_dim(a, env, ddim_empty())
  let vb = deval_dim(b, env, ddim_empty())
  stats.probes = stats.probes + 1
  if conv_at(ctx.length(), 0, ty_value, va, vb) {
    return true
  }
  // Split candidates: Bool variables in the normal-form
  // difference; if the difference is empty (the failure is
  // not localised in the quoted terms -- e.g. it lives in
  // the type), fall back to every mentioned Bool variable.
  let diff_vars = cs_difference_variables(ctx, types, ty_value, va, vb)
  let candidates : Array[Int32] = []
  if diff_vars.length() > 0 {
    for k in 0..<diff_vars.length() {
      candidates.push(diff_vars[k])
    }
  } else {
    for i in 0..<ctx.length() {
      let is_bool = match types[i] {
        DVBoolTy => true
        _ => false
      }
      if !is_bool {
        continue
      }
      let index = ctx.length() - 1 - i
      if cs_mentions_var(a, index) ||
        cs_mentions_var(b, index) ||
        cs_mentions_var(ty, index) {
        candidates.push(i)
      }
    }
  }
  if candidates.length() == 0 {
    return false
  }
  let i = candidates[0]
  let index = ctx.length() - 1 - i
  stats.split_nodes = stats.split_nodes + 1
  for branch in 0..<2 {
    let lit = DBoolLit(branch == 0)
    let new_ctx : Array[DTerm] = []
    for j in 0..<ctx.length() {
      if j < i {
        new_ctx.push(ctx[j])
      } else if j > i {
        // In entry j's scope the split variable has index
        // j - 1 - i.
        new_ctx.push(dterm_substitute(ctx[j], j - 1 - i, lit))
      }
    }
    if !cs_conv_go(
        new_ctx,
        dterm_substitute(ty, index, lit),
        dterm_substitute(a, index, lit),
        dterm_substitute(b, index, lit),
        stats,
      ) {
      return false
    }
  }
  true
}

///|
/// Conversion of two terms at a (possibly dependent) type in a
/// telescope context, strengthened by case splits on Bool
/// variables.  `ctx` lists the context entry types in
/// declaration order; `ty`, `a`, and `b` are in the full
/// context's scope.  Ordinary conversion is tried first.
pub fn conv_terms_case_split(
  ctx : Array[DTerm],
  ty : DTerm,
  a : DTerm,
  b : DTerm,
) -> Bool {
  cs_conv_go(ctx, ty, a, b, { split_nodes: 0, probes: 0, })
}

///|
/// `conv_terms_case_split` with search statistics: how many
/// split nodes and conversion probes the search used, and how
/// many Bool variables occur in the root normal-form
/// difference (the difference-guided candidate count).
pub fn conv_terms_case_split_report(
  ctx : Array[DTerm],
  ty : DTerm,
  a : DTerm,
  b : DTerm,
) -> CaseSplitReport {
  let (env, types) = cs_eval_ctx(ctx)
  let ty_value = deval_dim(ty, env, ddim_empty())
  let root_diff = cs_difference_variables(
    ctx,
    types,
    ty_value,
    deval_dim(a, env, ddim_empty()),
    deval_dim(b, env, ddim_empty()),
  )
  let stats : CsStats = { split_nodes: 0, probes: 0, }
  let holds = cs_conv_go(ctx, ty, a, b, stats)
  {
    holds,
    split_nodes: stats.split_nodes,
    probes: stats.probes,
    root_difference_variables: root_diff.length(),
  }
}

///|
/// The Bool context levels (declaration order) occurring in
/// subterms where the quoted normal forms of `a` and `b` at
/// `ty` differ -- the difference-guided split candidates of
/// `conv_terms_case_split`, exposed for inspection and tests.
pub fn conv_difference_variables(
  ctx : Array[DTerm],
  ty : DTerm,
  a : DTerm,
  b : DTerm,
) -> Array[Int32] {
  let (env, types) = cs_eval_ctx(ctx)
  cs_difference_variables(
    ctx,
    types,
    deval_dim(ty, env, ddim_empty()),
    deval_dim(a, env, ddim_empty()),
    deval_dim(b, env, ddim_empty()),
  )
}

///|
/// Ordinary (unsplit) conversion in the fresh-neutral
/// interpretation of the same context, for comparison.
pub fn conv_terms_plain(
  ctx : Array[DTerm],
  ty : DTerm,
  a : DTerm,
  b : DTerm,
) -> Bool {
  let (env, _) = cs_eval_ctx(ctx)
  conv_at(
    ctx.length(),
    0,
    deval_dim(ty, env, ddim_empty()),
    deval_dim(a, env, ddim_empty()),
    deval_dim(b, env, ddim_empty()),
  )
}
