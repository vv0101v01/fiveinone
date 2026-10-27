/// 笛卡爾閉範疇（CCC）與 STLC。
///
/// 定義（CCC）：具終對象、二元積、指數對象的範疇，
///   滿足 λ-抽象的萬有性質：Hom(A×B, C) ≅ Hom(A, C^B)（柯里化同構）。
/// 定理（Curry–Howard–Lambek）：STLC 類型論 ⟷ CCC 語義對應；
///   βη-等價的項在 CCC 釋義下相等。
/// 實作：有限集合範疇 FinSet 的 CCC 結構（終對象 = 單點集，
///   積 = 笛卡爾積，指數 = 函數集），並以窮舉驗證萬有性質。

/// 有限集合以大小表示；映射以陣列表示（f[i] = 像）
/// 函數集 B^A 的元素編碼：混合進位制 code = Σ f(i)·|B|^i

///|
/// 終對象：單點集
pub fn ccc_terminal() -> Int32 {
  1
}

///|
/// 積：A × B（元素編碼 i·|B| + j）
pub fn ccc_product(aa : Int32, bb : Int32) -> Int32 {
  aa * bb
}

///|
/// 積的投影
pub fn ccc_fst(_aa : Int32, bb : Int32, p : Int32) -> Int32 {
  p / bb
}

///|
pub fn ccc_snd(_aa : Int32, bb : Int32, p : Int32) -> Int32 {
  p % bb
}

///|
/// 配對：⟨f, g⟩(z) = (f(z), g(z))
pub fn ccc_pair(
  _aa : Int32,
  bb : Int32,
  ff : Array[Int32],
  gg : Array[Int32],
) -> Array[Int32] {
  Array::makei(ff.length(), fn(z) { ff[z] * bb + gg[z] })
}

///|
/// 驗證積的萬有性質：對任意 h = ⟨f, g⟩，fst∘h = f，snd∘h = g，
///   且 h 是唯一滿足者（有限集上窮舉驗證）
pub fn verify_product_universal(aa : Int32, bb : Int32) -> Bool {
  let pp = ccc_product(aa, bb)
  // 投影
  let pi1 = Array::makei(pp, fn(p) { ccc_fst(aa, bb, p) })
  let pi2 = Array::makei(pp, fn(p) { ccc_snd(aa, bb, p) })
  // 窮舉所有 f : Z → A, g : Z → B（Z = {0,1} 測試物件）
  let zz = 2
  for fcode in 0..<pow_int(aa, zz) {
    for gcode in 0..<pow_int(bb, zz) {
      let ff = decode_ccc(fcode, zz, aa)
      let gg = decode_ccc(gcode, zz, bb)
      let h = ccc_pair(aa, bb, ff, gg)
      // π₁ ∘ h = f
      for z in 0..<zz {
        if pi1[h[z]] != ff[z] {
          return false
        }
        if pi2[h[z]] != gg[z] {
          return false
        }
      }
      // 唯一性：若 k : Z → A×B 滿足 π₁∘k = f 且 π₂∘k = g，則 k = h
      for kcode in 0..<pow_int(pp, zz) {
        let kk = decode_ccc(kcode, zz, pp)
        let mut agrees = true
        for z in 0..<zz {
          if pi1[kk[z]] != ff[z] || pi2[kk[z]] != gg[z] {
            agrees = false
          }
        }
        if agrees && !array_eq_int(kk, h) {
          return false
        }
      }
    }
  }
  true
}

///|
/// 指數：B^A（元素 = 函數 f : A → B 的編碼）
pub fn ccc_exponential(aa : Int32, bb : Int32) -> Int32 {
  pow_int(bb, aa)
}

///|
/// 求值映射 eval : B^A × A → B
pub fn ccc_eval(_aa : Int32, bb : Int32, fa : Int32, a : Int32) -> Int32 {
  fa / pow_int(bb, a) % bb
}

///|
/// 柯里化：f : Z×A → B ↦ λf : Z → B^A
pub fn curry(
  aa : Int32,
  bb : Int32,
  zz : Int32,
  ff : Array[Int32],
) -> Array[Int32] {
  // ff[z·|A| + a] = f(z, a)
  Array::makei(zz, fn(z) {
    let mut code = 0
    for a in 0..<aa {
      code = code + ff[z * aa + a] * pow_int(bb, a)
    }
    code
  })
}

///|
/// 反柯里化：λf : Z → B^A ↦ f : Z×A → B
pub fn uncurry(
  aa : Int32,
  bb : Int32,
  zz : Int32,
  lam : Array[Int32],
) -> Array[Int32] {
  Array::makei(zz * aa, fn(i) {
    let z = i / aa
    let a = i % aa
    ccc_eval(aa, bb, lam[z], a)
  })
}

///|
/// 驗證指數的萬有性質（柯里化同構）：
///   eval ∘ (g × id) = f 且 g 唯一；curry/uncurry 互逆。
pub fn verify_exponential_universal(aa : Int32, bb : Int32, zz : Int32) -> Bool {
  let ee = ccc_exponential(aa, bb)
  // eval : B^A × A → B
  // 窮舉 f : Z×A → B，驗證 curry/uncurry 互逆
  let total = pow_int(bb, zz * aa)
  for fcode in 0..<total {
    let ff = decode_ccc(fcode, zz * aa, bb)
    let lam = curry(aa, bb, zz, ff)
    // λf : Z → B^A 的每個分量必為合法函數編碼
    for z in 0..<zz {
      if lam[z] < 0 || lam[z] >= ee {
        return false
      }
    }
    let back = uncurry(aa, bb, zz, lam)
    if !array_eq_int(back, ff) {
      return false
    }
  }
  // 萬有性質：對每個 f，存在唯一 g = curry(f) 使 eval∘(g×id) = f
  // 且 g 唯一：窮舉所有 g : Z → B^A 檢驗
  for fcode in 0..<total {
    let ff = decode_ccc(fcode, zz * aa, bb)
    let gg = curry(aa, bb, zz, ff)
    let mut count = 0
    for gcode in 0..<pow_int(ee, zz) {
      let cand = decode_ccc(gcode, zz, ee)
      let mut ok = true
      for z in 0..<zz {
        for a in 0..<aa {
          if ccc_eval(aa, bb, cand[z], a) != ff[z * aa + a] {
            ok = false
          }
        }
      }
      if ok {
        count = count + 1
      }
    }
    if count != 1 {
      return false
    }
    // 存在性：curry(f) 本身即為該唯一 g
    for z in 0..<zz {
      for a in 0..<aa {
        if ccc_eval(aa, bb, gg[z], a) != ff[z * aa + a] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 驗證終對象萬有性質：到 1 的映射唯一
pub fn verify_terminal_universal(zz : Int32) -> Bool {
  // Hom(Z, 1) 恰有 1 個元素
  pow_int(1, zz) == 1
}

///|
/// STLC 類型
pub enum SType {
  SAtom
  SOne
  SArrow(SType, SType)
  SPair(SType, SType)
}

///|
/// STLC 項（de Bruijn 指標）
pub enum STerm {
  SVar(Int32)
  SUnit
  SPair(STerm, STerm)
  SFst(STerm)
  SSnd(STerm)
  SLam(SType, STerm)
  SApp(STerm, STerm)
}

///|
/// STLC 類型推導（上下文 ctx : Array[SType]，de Bruijn 指標）
pub fn stlc_infer(ctx : Array[SType], tt : STerm) -> SType? {
  match tt {
    SVar(i) =>
      if i < 0 || i >= ctx.length() {
        None
      } else {
        Some(ctx[ctx.length() - 1 - i])
      }
    SUnit => Some(SOne)
    SPair(t1, t2) =>
      match (stlc_infer(ctx, t1), stlc_infer(ctx, t2)) {
        (Some(a), Some(b)) => Some(SPair(a, b))
        _ => None
      }
    SFst(t) =>
      match stlc_infer(ctx, t) {
        Some(SPair(a, b)) => {
          let _ = b
          Some(a)
        }
        _ => None
      }
    SSnd(t) =>
      match stlc_infer(ctx, t) {
        Some(SPair(a, b)) => {
          let _ = a
          Some(b)
        }
        _ => None
      }
    SLam(pty, body) => {
      let ctx2 = ctx.copy()
      ctx2.push(pty)
      match stlc_infer(ctx2, body) {
        Some(b) => Some(SArrow(pty, b))
        None => None
      }
    }
    SApp(t1, t2) =>
      match (stlc_infer(ctx, t1), stlc_infer(ctx, t2)) {
        (Some(SArrow(a, b)), Some(a2)) =>
          if stype_eq(a, a2) {
            Some(b)
          } else {
            None
          }
        _ => None
      }
  }
}

///|
fn stype_eq(aa : SType, bb : SType) -> Bool {
  match (aa, bb) {
    (SAtom, SAtom) => true
    (SOne, SOne) => true
    (SArrow(a1, b1), SArrow(a2, b2)) => stype_eq(a1, a2) && stype_eq(b1, b2)
    (SPair(a1, b1), SPair(a2, b2)) => stype_eq(a1, a2) && stype_eq(b1, b2)
    _ => false
  }
}

///|
/// STLC 求值（call-by-name，β-歸約）
pub fn stlc_eval(tt : STerm) -> STerm {
  match tt {
    SVar(i) => SVar(i)
    SUnit => SUnit
    SPair(t1, t2) => SPair(stlc_eval(t1), stlc_eval(t2))
    SFst(t) =>
      match stlc_eval(t) {
        SPair(v1, v2) => {
          let _ = v2
          stlc_eval(v1)
        }
        u => SFst(u)
      }
    SSnd(t) =>
      match stlc_eval(t) {
        SPair(v1, v2) => {
          let _ = v1
          stlc_eval(v2)
        }
        u => SSnd(u)
      }
    SLam(pty, body) => SLam(pty, stlc_eval(body))
    SApp(t1, t2) =>
      match stlc_eval(t1) {
        SLam(_, body) => stlc_eval(subst_top(stlc_eval(t2), body))
        u => SApp(u, stlc_eval(t2))
      }
  }
}

///|
/// 頂層替換：(λx. body) v → body[v/x]（de Bruijn 指標）
fn subst_top(s : STerm, tt : STerm) -> STerm {
  shift(subst(0, shift(s, 1), tt), -1)
}

///|
/// 替換：Var(j) ↦ s（j 為目標指標）
fn subst(j : Int32, s : STerm, tt : STerm) -> STerm {
  match tt {
    SVar(k) => if k == j { s } else { SVar(k) }
    SUnit => SUnit
    SPair(t1, t2) => SPair(subst(j, s, t1), subst(j, s, t2))
    SFst(t) => SFst(subst(j, s, t))
    SSnd(t) => SSnd(subst(j, s, t))
    SLam(pty, body) => SLam(pty, subst(j + 1, shift(s, 1), body))
    SApp(t1, t2) => SApp(subst(j, s, t1), subst(j, s, t2))
  }
}

///|
/// 指標移位（cutoff c 以下不動，避免綁定變量）
fn shift_above(tt : STerm, d : Int32, c : Int32) -> STerm {
  match tt {
    SVar(j) => if j >= c { SVar(j + d) } else { SVar(j) }
    SUnit => SUnit
    SPair(t1, t2) => SPair(shift_above(t1, d, c), shift_above(t2, d, c))
    SFst(t) => SFst(shift_above(t, d, c))
    SSnd(t) => SSnd(shift_above(t, d, c))
    SLam(pty, body) => SLam(pty, shift_above(body, d, c + 1))
    SApp(t1, t2) => SApp(shift_above(t1, d, c), shift_above(t2, d, c))
  }
}

///|
fn shift(tt : STerm, d : Int32) -> STerm {
  shift_above(tt, d, 0)
}

///|
/// 驗證 β-歸約：(λx. x) v ≡ v
pub fn verify_beta() -> Bool {
  let id = SLam(SAtom, SVar(0))
  let ctx = [SAtom]
  // (λx. x) 應用於自由變量 y（上下文 [A] 中的 SVar(0)）
  match stlc_eval(SApp(id, SVar(0))) {
    SVar(0) =>
      match stlc_infer(ctx, SApp(id, SVar(0))) {
        Some(SAtom) => true
        _ => false
      }
    _ => false
  }
}

///|
/// 驗證 β-歸約於複合項：(λx. λy. x) a b ≡ a
pub fn verify_beta_const() -> Bool {
  // K = λx. λy. x
  let kk = SLam(SAtom, SLam(SAtom, SVar(1)))
  // K applied to SVar(0), then to SVar(0)
  let term = SApp(SApp(kk, SVar(0)), SVar(0))
  match stlc_eval(term) {
    SVar(0) => true
    _ => false
  }
}

///|
fn decode_ccc(code : Int32, len : Int32, base : Int32) -> Array[Int32] {
  let out = Array::make(len, 0)
  let mut r = code
  let mut i = len - 1
  while i >= 0 {
    out[i] = r % base
    r = r / base
    i = i - 1
  }
  out
}
