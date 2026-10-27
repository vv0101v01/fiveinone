/// 同倫類型論（HoTT）的符號計算。
///
/// 定義（圓 S¹）：高層歸納類型，由 base : S¹ 與
///   loop : base = base 生成。
/// 定理（編碼-解碼）：對 x : S¹，
///   code(x) 為類型族，code(base) = ℤ，且
///   transport^{code}(loop, n) = n + 1；
///   encode : (base = x) → code(x)，encode(p) = transport(code, p, 0)；
///   decode : code(x) → (base = x)，decode(n) = loop^n。
///   encode 與 decode 互逆 ⟹ π₁(S¹, base) ≅ ℤ。
/// 定理（單值性 univalence）：(A ≃ B) ≃ (A = B)——
///   此處僅作文件記述（需要具單值性的宇宙，超出符號求值器範圍）。

///|
/// S¹ 的路徑：loop^n（n ∈ ℤ）
pub struct S1Path {
  n : Int32
}

///|
/// refl_base
pub fn refl_s1() -> S1Path {
  S1Path::{ n: 0, }
}

///|
/// loop 生成元
pub fn loop_s1() -> S1Path {
  S1Path::{ n: 1, }
}

///|
/// 路徑連接（加法）
pub fn concat_s1(p : S1Path, q : S1Path) -> S1Path {
  S1Path::{ n: p.n + q.n, }
}

///|
/// 路徑逆
pub fn inverse_s1(p : S1Path) -> S1Path {
  S1Path::{ n: -p.n, }
}

///|
/// 路徑代數 ≅ ℤ：驗證群公理
pub fn verify_path_group() -> Bool {
  for a in -3..<=3 {
    for b in -3..<=3 {
      for c in -3..<=3 {
        let p = S1Path::{ n: a, }
        let q = S1Path::{ n: b, }
        let r = S1Path::{ n: c, }
        // 結合律
        let lhs = concat_s1(concat_s1(p, q), r)
        let rhs = concat_s1(p, concat_s1(q, r))
        if lhs.n != rhs.n {
          return false
        }
        // 單位律
        if concat_s1(p, refl_s1()).n != a {
          return false
        }
        if concat_s1(refl_s1(), p).n != a {
          return false
        }
        // 逆元律
        if concat_s1(p, inverse_s1(p)).n != 0 {
          return false
        }
      }
    }
  }
  true
}

///|
/// 編碼族：code(base) = ℤ，沿 loop 的 transport 為 +1
pub fn transport_code(p : S1Path, n : Int32) -> Int32 {
  n + p.n
}

///|
/// encode : (base = x) → code(x)
pub fn encode_s1(p : S1Path) -> Int32 {
  transport_code(p, 0)
}

///|
/// decode : code(x) → (base = x)，decode(n) = loop^n
pub fn decode_s1(n : Int32) -> S1Path {
  S1Path::{ n, }
}

///|
/// 編碼-解碼定理：encode ∘ decode = id，decode ∘ encode = id
pub fn verify_encode_decode() -> Bool {
  for n in -5..<=5 {
    // encode(decode(n)) = n
    if encode_s1(decode_s1(n)) != n {
      return false
    }
    // decode(encode(p)) = p
    for a in -5..<=5 {
      let p = S1Path::{ n: a, }
      if decode_s1(encode_s1(p)).n != a {
        return false
      }
    }
  }
  true
}

///|
/// J 消除子（路徑的萬有性質）：
///   J(x, y, p, C, c) : C(x, y, p)，滿足計算規則
///   J(x, x, refl, C, c) = c。
/// 符號實作：J(p, c) = transport^C(p, c)。
pub fn j_elim(p : S1Path, c : Int32) -> Int32 {
  transport_code(p, c)
}

///|
/// 驗證 J 的計算規則：J(refl, c) = c
pub fn verify_j_computation() -> Bool {
  for c in -3..<=3 {
    if j_elim(refl_s1(), c) != c {
      return false
    }
  }
  true
}

///|
/// 對稱性：若 p : x = y 則 p⁻¹ : y = x
pub fn verify_path_sym() -> Bool {
  for a in -3..<=3 {
    let p = S1Path::{ n: a, }
    if concat_s1(p, inverse_s1(p)).n != 0 {
      return false
    }
  }
  true
}

///|
/// 傳送函子（congruence）：f(x) = f(y) 若 x = y
pub fn congruence_s1(f : Int32, p : S1Path) -> S1Path {
  // f : S¹ → S¹ 為 loop^k 的幂映射；congruence(f, p) = f(p)
  S1Path::{ n: f * p.n, }
}

///|
/// π₁(S¹, base) ≅ ℤ：loop^n ↦ n 為群同構
/// （單射：loop^n = loop^m ⟹ n = m；滿射：顯然）
pub fn verify_pi1_circle() -> Bool {
  // 單射性：n ≠ m ⟹ loop^n ≠ loop^m（符號層面：路徑編號不同）
  for n in -4..<=4 {
    for m in -4..<=4 {
      if n != m {
        let pn = loop_pow(n)
        let pm = loop_pow(m)
        if pn.n == pm.n {
          return false
        }
      }
    }
  }
  // 群同態：loop^{n+m} = loop^n · loop^m
  for n in -4..<=4 {
    for m in -4..<=4 {
      if concat_s1(loop_pow(n), loop_pow(m)).n != n + m {
        return false
      }
    }
  }
  true
}

///|
/// loop^n（符號冪）
pub fn loop_pow(n : Int32) -> S1Path {
  S1Path::{ n, }
}

///|
/// 單值性（univalence）的文件記述：
///   (A ≃ B) ≃ (A = B)
///   等價類型之間的等價與類型間等號一一對應。
/// 此處僅以公式記述，不於符號求值器中實作
/// （需要具單值性的宇宙層級）。
pub fn univalence_statement() -> String {
  "univalence: (A ≃ B) ≃ (A = B)"
}
