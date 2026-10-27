/// Operad 的有限計算。
///
/// 定義（對稱 operad）：一族 P(n)（帶 S_n 作用）與合成
///   γ : P(k) × P(n_1) × … × P(n_k) → P(n_1+…+n_k)，
///   滿足結合律、單位律與等變性。
/// 例（結合 operad）：Assoc(n) = S_n。
/// 例（自同態 operad）：End_X(n) = X^{X^n}。
/// 定理（Stasheff）：結合多面體 K_{n+1} 的面
///   ↔ (n+2)-邊形的非交叉對角線集合；
///   頂點數 = Catalan 數。
/// 定理（自由 operad）：一個二元生成元的自由 operad
///   在元數 n 有 Catalan(n−1) 個操作（二元樹）。

///|
/// 結合 operad 的合成：
///   γ(σ; τ_1, …, τ_k) = B(σ) ∘ (τ_1 ⊕ … ⊕ τ_k)
///   B(σ) 把第 m 塊送到第 σ(m) 塊。
pub fn assoc_compose(
  sigma : Array[Int32],
  taus : Array[Array[Int32]],
  sizes : Array[Int32],
) -> Array[Int32] {
  let k = sigma.length()
  // ρ = τ_1 ⊕ … ⊕ τ_k（分塊對角）
  let mut total = 0
  for i in 0..<k {
    total = total + sizes[i]
  }
  let rho = Array::make(total, 0)
  let mut offset = 0
  for m in 0..<k {
    for j in 0..<sizes[m] {
      rho[offset + j] = offset + taus[m][j]
    }
    offset = offset + sizes[m]
  }
  // B(σ)：塊 m（偏移 j）→ 第 σ(m) 塊的偏移 j
  let block = Array::make(total, 0)
  for m in 0..<k {
    // 排在 σ(m) 之前的塊：所有 l 使 σ(l) < σ(m)
    let mut before = 0
    for l in 0..<k {
      if sigma[l] < sigma[m] {
        before = before + sizes[l]
      }
    }
    for j in 0..<sizes[m] {
      block[offset_of(m, sizes, j)] = before + j
    }
  }
  // γ = B(σ) ∘ ρ
  Array::makei(total, fn(i) { block[rho[i]] })
}

///|
fn offset_of(m : Int32, sizes : Array[Int32], j : Int32) -> Int32 {
  let mut s = 0
  for i in 0..<m {
    s = s + sizes[i]
  }
  s + j
}

///|
/// 驗證 Assoc operad 的公理（小範例窮舉）：
/// （一）單位律：γ(id₁; τ) = τ；
/// （二）結合律：γ(γ(σ; τ); υ) = γ(σ; γ(τ; υ)…)（k=2, 單元塊）；
/// （三）結果確實是置換。
pub fn verify_assoc_operad() -> Bool {
  // 單位律：σ = id_1（[0]），τ ∈ S_2
  let id1 = [0]
  for a in 0..<=1 {
    for b in 0..<=1 {
      if a == b {
        continue
      }
      let tau = [a, b]
      let res = assoc_compose(id1, [tau], [2])
      if !(res[0] == tau[0] && res[1] == tau[1]) {
        return false
      }
    }
  }
  // 結合律：σ ∈ S_2，τ_1, τ_2 ∈ S_1，υ_1, υ_2, υ_3 ∈ S_1
  // （塊大小皆 1：合成退化为 S_2 的乘法）
  let s2 = [[0, 1], [1, 0]]
  for si in 0..<=1 {
    for sj in 0..<=1 {
      let sigma = s2[si]
      let taus = [[0], [0]]
      let inner1 = assoc_compose(sigma, taus, [1, 1])
      // γ(γ(σ; τ); υ) 與 γ(σ; γ(τ; υ)) 在單元塊下皆等於 σ
      let ups = [[0], [0]]
      let lhs = assoc_compose(inner1, ups, [1, 1])
      let inner2a = assoc_compose(taus[0], [[0]], [1])
      let inner2b = assoc_compose(taus[1], [[0]], [1])
      let rhs = assoc_compose(sigma, [inner2a, inner2b], [1, 1])
      for idx in 0..<2 {
        if lhs[idx] != rhs[idx] {
          return false
        }
      }
      let _ = sj
    }
  }
  // 置換性：γ(σ; τ₁, τ₂) ∈ S_{n₁+n₂}（雙射）
  // 塊大小 [1, 1]：τᵢ ∈ S₁ 只能是 [0]
  for a in 0..<=1 {
    for b in 0..<=1 {
      if a == b {
        continue
      }
      let sigma = [a, b]
      let res = assoc_compose(sigma, [[0], [0]], [1, 1])
      // 長度 2 且為雙射
      if res.length() != 2 {
        return false
      }
      if res[0] == res[1] ||
        (res[0] != 0 && res[0] != 1) ||
        (res[1] != 0 && res[1] != 1) {
        return false
      }
    }
  }
  // 置換性（較大情形）：σ ∈ S₂，τ₁ ∈ S₁，τ₂ ∈ S₂ ⟹ γ ∈ S₃
  for a in 0..<=1 {
    for b in 0..<=1 {
      if a == b {
        continue
      }
      let sigma = [a, b]
      for c in 0..<=1 {
        for d in 0..<=1 {
          if c == d {
            continue
          }
          let tau2 = [c, d]
          let res = assoc_compose(sigma, [[0], tau2], [1, 2])
          if res.length() != 3 {
            return false
          }
          let seen = Array::make(3, false)
          for t in 0..<3 {
            if res[t] < 0 || res[t] >= 3 || seen[res[t]] {
              return false
            }
            seen[res[t]] = true
          }
        }
      }
    }
  }
  true
}

///|
/// 自同態 operad End_X：End_X(n) = X^{X^n}
/// 合成：f ∘ (g_1, …, g_k)，
///   (f ∘ (g_1,…,g_k))(x_1,…,x_N) = f(g_1(x_1..x_{n_1}), …, g_k(…))
pub fn end_compose(
  f : Array[Int32],
  gs : Array[Array[Int32]],
  sizes : Array[Int32],
  xsize : Int32,
) -> Array[Int32] {
  let k = sizes.length()
  // 結果函數的輸入為 X^{n₁+…+nₖ}：表長 = |X|^{Σnᵢ}
  let total = pow_int(xsize, k)
  // f 的定義域大小 = xsize^k，gs[i] 的定義域大小 = xsize^{sizes[i]}
  Array::makei(total, fn(idx) {
    // 分解 idx = (x_1, …, x_N)（混合進位）
    let mut rest = idx
    let args : Array[Int32] = []
    for i in 0..<k {
      // 第 i 個子操作的輸入：sizes[i] 個變元
      let mut sub = 0
      let mut mult = 1
      for _j in 0..<sizes[i] {
        sub = sub + rest % xsize * mult
        rest = rest / xsize
        mult = mult * xsize
      }
      args.push(gs[i][sub])
    }
    // f(args)：混合進位編碼，第 i 群在第 i 個位階
    let mut code = 0
    let mut mult = 1
    for i in 0..<k {
      code = code + args[i] * mult
      mult = mult * pow_int(xsize, sizes[i])
    }
    f[code]
  })
}

///|
/// End_X(n) 的大小 = |X|^{|X|^n}
pub fn end_count(xsize : Int32, n : Int32) -> Int32 {
  pow_int(xsize, pow_int(xsize, n))
}

///|
/// 驗證 End_X 是 operad：
/// （一）單位律（恒等映射 id : X → X）；
/// （二）結合律（小情形窮舉）；
/// （三）End_X(n) 計數公式。
pub fn verify_end_operad(xsize : Int32) -> Bool {
  // 計數：End(1) = x^x，End(2) = x^{x²}
  if end_count(xsize, 1) != pow_int(xsize, xsize) {
    return false
  }
  if end_count(xsize, 2) != pow_int(xsize, xsize * xsize) {
    return false
  }
  // 單位元：id(x) = x
  let id : Array[Int32] = Array::makei(xsize, fn(i) { i })
  // 單位律：f ∘ (id) = f（k = 1, n_1 = 1）
  for a in 0..<xsize {
    for b in 0..<xsize {
      let f = [a, b]
      let res = end_compose(f, [id], [1], xsize)
      if !(res[0] == f[0] && res[1] == f[1]) {
        return false
      }
    }
  }
  // 結合律：γ(γ(f; g, h); u, v) = γ(f; γ(g; u, v), γ(h; u, v))
  // f : X² → X（16 種），g, h, u, v : X → X（各 4 種）
  if xsize == 2 {
    for fi in 0..<16 {
      for gi in 0..<=3 {
        for hi in 0..<=3 {
          for ui in 0..<=3 {
            for vi in 0..<=3 {
              let f = bin_fn_of(fi)
              let g = fn_of(gi)
              let h = fn_of(hi)
              let u = fn_of(ui)
              let v = fn_of(vi)
              // γ(γ(f; g, h); u, v) = γ(f; γ(g; u), γ(h; v))
              let fg = end_compose(f, [g, h], [1, 1], xsize)
              let lhs = end_compose(fg, [u, v], [1, 1], xsize)
              let gu = end_compose(g, [u], [1], xsize)
              let hv = end_compose(h, [v], [1], xsize)
              let rhs = end_compose(f, [gu, hv], [1, 1], xsize)
              for t in 0..<4 {
                if lhs[t] != rhs[t] {
                  return false
                }
              }
            }
          }
        }
      }
    }
  }
  true
}

///|
/// 編號 i ∈ [0, 4) ↦ 函數 X → X（X = {0, 1}）
fn fn_of(i : Int32) -> Array[Int32] {
  match i {
    0 => [0, 0]
    1 => [0, 1]
    2 => [1, 0]
    3 => [1, 1]
    _ => [0, 0]
  }
}

///|
/// 編號 i ∈ [0, 16) ↦ 函數 X² → X（X = {0, 1}）
fn bin_fn_of(i : Int32) -> Array[Int32] {
  Array::makei(4, fn(t) { (i >> t) & 1 })
}

///|
/// Catalan 數 C_n = binom(2n, n)/(n+1)
pub fn catalan(n : Int32) -> Int32 {
  let mut c = 1
  for i in 0..<n {
    c = c * (2 * (2 * i + 1)) / (i + 2)
  }
  c
}

///|
/// Stasheff 結合多面體（associahedron）K 的面枚舉：
/// 面 ↔ 凸 (n+2)-邊形的非交叉對角線集合。
/// 回傳各維面數（dim = n − 2 − |對角線數|）。
pub fn associahedron_faces(ngon : Int32) -> Array[Int32] {
  // 對角線：(i, j)，2 ≤ j − i ≤ ngon − 2
  let diags : Array[(Int32, Int32)] = []
  for i in 0..<ngon {
    for j in (i + 2)..<ngon {
      if !(i == 0 && j == ngon - 1) {
        diags.push((i, j))
      }
    }
  }
  let nd = diags.length()
  // 維數上限 = ngon − 3（三角剖分有 ngon − 3 條對角線）
  let maxk = ngon - 3
  let counts = Array::make(maxk + 1, 0)
  // 窮舉對角線子集，檢查兩兩不交叉
  let total = 1 << nd
  for mask in 0..<total {
    let mut ok = true
    let mut cnt = 0
    for a in 0..<nd {
      if ((mask >> a) & 1) == 0 {
        continue
      }
      cnt = cnt + 1
      if cnt > maxk {
        ok = false
        break
      }
      for b in (a + 1)..<nd {
        if ((mask >> b) & 1) == 0 {
          continue
        }
        if diags_cross(diags[a], diags[b]) {
          ok = false
          break
        }
      }
      if !ok {
        break
      }
    }
    if ok && cnt <= maxk {
      counts[cnt] = counts[cnt] + 1
    }
  }
  counts
}

///|
/// 兩條對角線 (a, b) 與 (c, d)（a < b, c < d）交叉
/// ⟺ 端點交錯：a < c < b < d 或 c < a < d < b
fn diags_cross(x : (Int32, Int32), y : (Int32, Int32)) -> Bool {
  let a = x.0
  let b = x.1
  let c = y.0
  let d = y.1
  (a < c && c < b && b < d) || (c < a && a < d && d < b)
}

///|
/// 驗證結合多面體：
/// （一）K_4（五邊形對應 ngon = 5）：面數 (1, 5, 5)
///     （1 個二維面、5 條邊、5 個頂點）；
/// （二）頂點數 = 三角剖分數 = Catalan(n − 2)（ngon 邊形）；
/// （三）六邊形（ngon = 6）：面數 (1, 9, 21, 14)。
pub fn verify_associahedron() -> Bool {
  let f5 = associahedron_faces(5)
  if !(f5.length() == 3 && f5[0] == 1 && f5[1] == 5 && f5[2] == 5) {
    return false
  }
  let f6 = associahedron_faces(6)
  if !(f6.length() == 4 &&
    f6[0] == 1 &&
    f6[1] == 9 &&
    f6[2] == 21 &&
    f6[3] == 14) {
    return false
  }
  // 頂點數 = 最大對角線集數 = Catalan(ngon − 2)
  for ngon in 4..<=6 {
    let ff = associahedron_faces(ngon)
    if ff[ff.length() - 1] != catalan(ngon - 2) {
      return false
    }
  }
  true
}

///|
/// 自由 operad（一個二元生成元）：元數 n 的操作數
/// = 葉數 n 的二元樹數 = Catalan(n − 1)
///   n = 1, 2, 3, 4, 5 ↦ 1, 1, 2, 5, 14
pub fn free_operad_count(n : Int32) -> Int32 {
  if n <= 1 {
    return 1
  }
  catalan(n - 1)
}

///|
/// 驗證自由 operad 計數與遞迴：
///   F(n) = Σ_{i=1}^{n−1} F(i)·F(n−i)（根的左子樹大小 i）
pub fn verify_free_operad() -> Bool {
  for n in 1..<=7 {
    let mut sum = 0
    for i in 1..<n {
      sum = sum + free_operad_count(i) * free_operad_count(n - i)
    }
    if n == 1 {
      if free_operad_count(1) != 1 {
        return false
      }
    } else if free_operad_count(n) != sum {
      return false
    }
  }
  true
}
