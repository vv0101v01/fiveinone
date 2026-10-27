/// 群上同調（group cohomology）的有限計算。
///
/// 定義：G 在 F_p-模 M 上的上同調 H^n(G, M) = Ext^n_{ZG}(k, M)，
///   由 bar 分解計算：上鏈 C^n(G,M) = {f : G^n → M}，
///   (d^n f)(g_1..g_{n+1}) = g_1·f(g_2..g_{n+1})
///     + Σ_{i=1}^{n} (−1)^i f(g_1..g_i g_{i+1}..g_{n+1}) + (−1)^{n+1} f(g_1..g_n)。
/// 定理（H¹）：平凡作用下 H¹(G, M) ≅ Hom(G_ab, M)。
/// 定理（循環群 Tate 週期性）：H^{2k}(C_m, M) = M^G/NM，
///   H^{2k+1}(C_m, M) = ker N/(σ−1)M；平凡 F_p 作用時
///   H^n(C_m, F_p) = F_p（若 p | m，n ≥ 1），否則 0。
/// 複雜度：bar 分解為 O(|G|^{n+1}) 線性代數；循環群閉式 O(m)。

///|
/// 多重索引編碼：(g_1..g_n) ↦ g_1 |G|^{n-1} + ... + g_n
fn multi_index(gg : FinGroup, idx : Array[Int32]) -> Int32 {
  let mut r = 0
  for g in idx {
    r = r * gg.order + g
  }
  r
}

///|
/// 多重索引解碼
fn multi_decode(gg : FinGroup, n : Int32, code : Int32) -> Array[Int32] {
  let mut r = code
  let out = Array::make(n, 0)
  let mut i = n - 1
  while i >= 0 {
    out[i] = r % gg.order
    r = r / gg.order
    i = i - 1
  }
  out
}

///|
/// 上鏈微分 d^n : C^n(G,F_p) → C^{n+1}(G,F_p) 的矩陣（平凡作用）。
/// 行 = G^n，row = G^{n+1}。
pub fn cochain_diff(gg : FinGroup, p : Int32, n : Int32) -> Mat {
  let rows = pow_int(gg.order, n + 1)
  let cols = pow_int(gg.order, n)
  let entries : Array[Array[Int32]] = Array::makei(rows, fn(_) {
    Array::make(cols, 0)
  })
  if n == 0 {
    // d⁰ : M → C¹，(dm)(g) = g·m − m = 0（平凡作用）
    return make_mat(
      gg.order,
      1,
      p,
      Array::makei(gg.order, fn(_) { Array::make(1, 0) }),
    )
  }
  for row in 0..<rows {
    let gs = multi_decode(gg, n + 1, row)
    // g_1·f(g_2..g_{n+1})：平凡作用 → 係數 +1，column = (g_2..g_{n+1})
    let tail = Array::makei(n, fn(i) { gs[i + 1] })
    entries[row][multi_index(gg, tail)] = (
        entries[row][multi_index(gg, tail)] + 1
      ) %
      p
    for i in 1..<=n {
      // (−1)^i f(g_1..g_i g_{i+1}..g_{n+1})
      let merged : Array[Int32] = []
      for j in 0..<(i - 1) {
        merged.push(gs[j])
      }
      merged.push(gg.mul[gs[i - 1]][gs[i]])
      for j in (i + 1)..<(n + 1) {
        merged.push(gs[j])
      }
      let sign = if i % 2 == 0 { 1 } else { p - 1 }
      let col = multi_index(gg, merged)
      entries[row][col] = (entries[row][col] + sign) % p
    }
    // (−1)^{n+1} f(g_1..g_n)
    let head = Array::makei(n, fn(i) { gs[i] })
    let sign = if (n + 1) % 2 == 0 { 1 } else { p - 1 }
    let col = multi_index(gg, head)
    entries[row][col] = (entries[row][col] + sign) % p
  }
  make_mat(rows, cols, p, entries)
}

///|
/// 矩陣秩（重用 algebra.mbt 的 mat_rank）
fn pow_int(base : Int32, exp : Int32) -> Int32 {
  let mut r = 1
  for _ in 0..<exp {
    r = r * base
  }
  r
}

///|
/// H^n(G, F_p) 的維數：dim ker(d^n) − rank(d^{n−1})
pub fn cohomology_dim(gg : FinGroup, p : Int32, n : Int32) -> Int32 {
  if n == 0 {
    // H⁰ = M^G = F_p（平凡作用）
    return 1
  }
  let dn = cochain_diff(gg, p, n)
  let dn1 = cochain_diff(gg, p, n - 1)
  let ker_dim = dn.cols - mat_rank(dn)
  let im_dim = mat_rank(dn1)
  ker_dim - im_dim
}

///|
/// 平凡作用下 H¹(G, F_p) ≅ Hom(G_ab, F_p) 的維數（直接數同態）
pub fn hom_dim_from_ab(gg : FinGroup, p : Int32) -> Int32 {
  let gab = abelianization(gg)
  // 數 Hom(G_ab, F_p)：窮舉所有函數並檢驗同態性
  let m = gab.order
  let total = pow_int(p, m)
  let mut count = 0
  for code in 0..<total {
    // 解碼為 f : G_ab → F_p
    let f = Array::make(m, 0)
    let mut r = code
    let mut i = m - 1
    while i >= 0 {
      f[i] = r % p
      r = r / p
      i = i - 1
    }
    let mut ok = true
    for a in 0..<m {
      for b in 0..<m {
        if (f[gab.mul[a][b]] - (f[a] + f[b]) % p + p) % p != 0 {
          ok = false
        }
      }
    }
    if ok {
      count = count + 1
    }
  }
  // log_p(count)
  let mut dim = 0
  let mut c = count
  while c > 1 {
    c = c / p
    dim = dim + 1
  }
  dim
}

///|
/// 循環群 C_m 的 Tate 閉式（平凡 F_p 作用）：
/// H⁰ = F_p；n ≥ 1 時 H^n = F_p 若 p | m，否則 0。
/// 複雜度 O(m)（相對 bar 分解的 O(m^{n+1}) 為指數級降低）。
pub fn cyclic_cohomology_dim(m : Int32, p : Int32, n : Int32) -> Int32 {
  if n == 0 {
    return 1
  }
  if m % p == 0 {
    1
  } else {
    0
  }
}

///|
/// 驗證 H¹ ≅ Hom(G_ab, M)：bar 分解計算與同態計數一致
pub fn verify_h1_is_hom(gg : FinGroup, p : Int32) -> Bool {
  cohomology_dim(gg, p, 1) == hom_dim_from_ab(gg, p)
}

///|
/// 驗證循環群閉式與 bar 分解一致（對所有 1 ≤ n ≤ maxdeg）
pub fn verify_cyclic_periodicity(m : Int32, p : Int32, maxdeg : Int32) -> Bool {
  let cg = cyclic_group(m)
  for n in 1..<=maxdeg {
    if cohomology_dim(cg, p, n) != cyclic_cohomology_dim(m, p, n) {
      return false
    }
  }
  true
}
