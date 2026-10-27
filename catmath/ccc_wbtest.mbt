///|
/// CCC 與 STLC 白盒測試。
test "ccc_terminal" {
  assert_eq(verify_terminal_universal(3), true)
  assert_eq(ccc_terminal(), 1)
}

///|
test "ccc_product_universal" {
  assert_eq(verify_product_universal(2, 2), true)
  assert_eq(ccc_product(2, 3), 6)
  assert_eq(ccc_fst(2, 3, 5), 1)
  assert_eq(ccc_snd(2, 3, 5), 2)
}

///|
test "ccc_exponential_universal" {
  // 柯里化同構 Hom(Z×A, B) ≅ Hom(Z, B^A)
  assert_eq(verify_exponential_universal(2, 2, 2), true)
  assert_eq(verify_exponential_universal(2, 3, 1), true)
  assert_eq(ccc_exponential(2, 2), 4)
  // eval 驗證：編碼 3 = 函數 (0↦1, 1↦1)，在 1 處取值
  assert_eq(ccc_eval(2, 2, 3, 1), 1)
}

///|
test "stlc_typecheck" {
  let ctx : Array[SType] = []
  // λx:SAtom. x : SAtom → SAtom
  let id = SLam(SAtom, SVar(0))
  let ok1 = match stlc_infer(ctx, id) {
    Some(SArrow(SAtom, SAtom)) => true
    _ => false
  }
  assert_eq(ok1, true)
  // K = λx. λy. x : A → (A → A)
  let kk = SLam(SAtom, SLam(SAtom, SVar(1)))
  let ok2 = match stlc_infer(ctx, kk) {
    Some(SArrow(SAtom, SArrow(SAtom, SAtom))) => true
    _ => false
  }
  assert_eq(ok2, true)
  // 單位
  let ok3 = match stlc_infer(ctx, SUnit) {
    Some(SOne) => true
    _ => false
  }
  assert_eq(ok3, true)
  // 配對
  let pr = STerm::SPair(SVar(0), SUnit)
  let ok4 = match stlc_infer([SAtom], pr) {
    Some(SPair(SAtom, SOne)) => true
    _ => false
  }
  assert_eq(ok4, true)
  // 錯誤項：λx. x 應用於單位（類型不匹配）
  let bad = SApp(SLam(SAtom, SVar(0)), SUnit)
  let ok5 = match stlc_infer(ctx, bad) {
    Some(_) => false
    None => true
  }
  assert_eq(ok5, true)
}

///|
test "stlc_eval_beta" {
  assert_eq(verify_beta(), true)
  assert_eq(verify_beta_const(), true)
  // (λx. x) (λy. y) ≡ λy. y
  let id = SLam(SAtom, SVar(0))
  let ok1 = match stlc_eval(SApp(id, id)) {
    SLam(_, body) =>
      match body {
        SVar(0) => true
        _ => false
      }
    _ => false
  }
  assert_eq(ok1, true)
}

///|
test "stlc_eval_pair" {
  // fst ⟨a, b⟩ ≡ a
  let pr = STerm::SPair(SVar(0), SUnit)
  let ok1 = match stlc_eval(SFst(pr)) {
    SVar(0) => true
    _ => false
  }
  assert_eq(ok1, true)
}
