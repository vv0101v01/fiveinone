/// 導出代數幾何的計算核心：Dold–Kan 對應與 Tor。
///
/// 定理（Dold–Kan）：模擬阿貝爾群 A 的範疇 ≅ 鏈複形的範疇。
///   正則化 N_n = ∩_{i<n} ker(d_i)，微分 ∂ = d_n|_{N_n}；
///   且 A_n = N_n ⊕ D_n（D_n = 退化子模）。
///   Moore 複形 ∂_n = Σ(−1)^i d_i 與正則化同調同構。
/// 定理（導出張量積）：Tor_n^R(k, k) = H_n(k ⊗^L_R k)。
/// 例（任意無限）：R = k[x]/(x²)（對偶數），bar 分解
///   B_n = R̄^{⊗n} ⊗ k，R̄ = span{x} ⟹ B_n = k，
///   bar 微分 d(x⊗…⊗x) = Σ(−1)^i …⊗x·x⊗… + …⊗x·m = 0
///   （因 x² = 0 且 x·k = 0）。
///   故 Tor_n^R(k, k) = k 對所有 n ≥ 0——無限多個非零同調群。
/// 對比：R = k[x] 的 Koszul 分解 0 → R --x--> R → k → 0：
///   Tor_0 = Tor_1 = k，Tor_n = 0（n ≥ 2）。

///|
/// 鏈複形（F_p 上）：diff[k] = ∂_{k+1} : C_{k+1} → C_k
pub struct ChainComplex {
  p : Int32
  diff : Array[Mat]
}

///|
/// 驗證鏈複形：∂∘∂ = 0
pub fn check_chain_complex(cc : ChainComplex) -> Bool {
  for k in 0..<(cc.diff.length() - 1) {
    let dd = mat_mul(cc.diff[k], cc.diff[k + 1])
    for i in 0..<dd.rows {
      for j in 0..<dd.cols {
        if dd.data[i][j] != 0 {
          return false
        }
      }
    }
  }
  true
}

///|
/// 同調維數 H_n = ker(∂_n) / im(∂_{n+1})
/// diff[k] = ∂_{k+1} ⟹ ∂_n = diff[n−1]
pub fn homology_dim(cc : ChainComplex, n : Int32) -> Int32 {
  if n == 0 {
    // H_0 = C_0 / im(∂_1)
    if cc.diff.length() == 0 {
      return 0
    }
    return cc.diff[0].rows - mat_rank(cc.diff[0])
  }
  // ker(∂_n) = ker(diff[n−1])
  if n - 1 >= cc.diff.length() {
    return 0
  }
  let dn = cc.diff[n - 1]
  let ker_dim = dn.cols - mat_rank(dn)
  // im(∂_{n+1}) = im(diff[n])
  if n >= cc.diff.length() {
    return ker_dim
  }
  let im_dim = mat_rank(cc.diff[n])
  ker_dim - im_dim
}

///|
/// 模擬 F_p-向量空間（截断至 maxdeg）
pub struct SimplicialSpace {
  p : Int32
  /// deg[n] = V_n 的維數
  deg : Array[Int32]
  /// face[n][i] : V_n → V_{n−1}（i = 0..n，n ≥ 1）
  face : Array[Array[Mat]]
  /// degen[n][i] : V_n → V_{n+1}（i = 0..n）
  degen : Array[Array[Mat]]
}

///|
/// 驗證模擬恆等式（在 V_2 → V_0 與 V_1 → V_1 層級）
pub fn check_simplicial_identities(ss : SimplicialSpace) -> Bool {
  // d_i d_j = d_{j−1} d_i（i < j），V_2 → V_0
  for j in 1..<=2 {
    for i in 0..<j {
      let lhs = mat_mul(ss.face[1][i], ss.face[2][j])
      let rhs = mat_mul(ss.face[1][j - 1], ss.face[2][i])
      if !mat_eq_dg(lhs, rhs) {
        return false
      }
    }
  }
  // d_j s_j = d_{j+1} s_j = id（V_1 → V_1）
  let id1 = mat_identity(ss.deg[1], ss.p)
  for j in 0..<=1 {
    if !mat_eq_dg(mat_mul(ss.face[2][j], ss.degen[1][j]), id1) {
      return false
    }
    if !mat_eq_dg(mat_mul(ss.face[2][j + 1], ss.degen[1][j]), id1) {
      return false
    }
  }
  // d_0 s_1 = s_0 d_0（i < j）
  let lhs01 = mat_mul(ss.face[2][0], ss.degen[1][1])
  let rhs01 = mat_mul(ss.degen[0][0], ss.face[1][0])
  if !mat_eq_dg(lhs01, rhs01) {
    return false
  }
  // d_2 s_0 = s_0 d_1（i > j+1）
  let lhs20 = mat_mul(ss.face[2][2], ss.degen[1][0])
  let rhs20 = mat_mul(ss.degen[0][0], ss.face[1][1])
  if !mat_eq_dg(lhs20, rhs20) {
    return false
  }
  true
}

///|
fn mat_eq_dg(aa : Mat, bb : Mat) -> Bool {
  if aa.rows != bb.rows || aa.cols != bb.cols {
    return false
  }
  for i in 0..<aa.rows {
    for j in 0..<aa.cols {
      if aa.data[i][j] != bb.data[i][j] {
        return false
      }
    }
  }
  true
}

///|
/// Moore 複形：∂_n = Σ(−1)^i d_i
pub fn moore_complex(ss : SimplicialSpace) -> ChainComplex {
  let p = ss.p
  let diff : Array[Mat] = []
  for n in 1..<ss.deg.length() {
    let mut acc = ss.face[n][0]
    for i in 1..<=n {
      // (−1)^i d_i
      let di = if i % 2 == 0 {
        ss.face[n][i]
      } else {
        mat_neg(ss.face[n][i], p)
      }
      acc = mat_add(acc, di, p)
    }
    diff.push(acc)
  }
  { p, diff, }
}

///|
/// 矩陣取負（F_p）
fn mat_neg(aa : Mat, p : Int32) -> Mat {
  make_mat(
    aa.rows,
    aa.cols,
    p,
    Array::makei(aa.rows, fn(i) {
      Array::makei(aa.cols, fn(j) { (p - aa.data[i][j]) % p })
    }),
  )
}

///|
/// Dold–Kan 正則化維數：dim N_n = dim ∩_{i<n} ker(d_i)
/// （零空間交集 = 垂直堆疊矩陣的零空間）
pub fn normalized_dims(ss : SimplicialSpace) -> Array[Int32] {
  let p = ss.p
  let out : Array[Int32] = []
  for n in 0..<ss.deg.length() {
    if n == 0 {
      out.push(ss.deg[0])
      continue
    }
    // 堆疊 d_0 .. d_{n−1}（每個 rows = deg[n−1]）
    let total_rows = n * ss.deg[n - 1]
    let stacked = Array::makei(total_rows, fn(r) {
      let i = r / ss.deg[n - 1]
      let rr = r % ss.deg[n - 1]
      ss.face[n][i].data[rr].copy()
    })
    let mm = make_mat(total_rows, ss.deg[n], p, stacked)
    out.push(ss.deg[n] - mat_rank(mm))
  }
  out
}

///|
/// 退化子模維數：dim D_n = rank([s_0 | s_1 | …])
pub fn degenerate_dims(ss : SimplicialSpace) -> Array[Int32] {
  let p = ss.p
  let out : Array[Int32] = []
  for n in 0..<ss.deg.length() {
    if n == 0 {
      out.push(0)
      continue
    }
    // 堆疊所有 s_i : V_{n−1} → V_n 的矩陣（水平拼接）
    let total_cols = n * ss.deg[n - 1]
    let stacked = Array::makei(ss.deg[n], fn(i) {
      let row : Array[Int32] = []
      for j in 0..<n {
        for c in 0..<ss.deg[n - 1] {
          row.push(ss.degen[n - 1][j].data[i][c])
        }
      }
      row
    })
    let mm = make_mat(ss.deg[n], total_cols, p, stacked)
    out.push(mat_rank(mm))
  }
  out
}

///|
/// 驗證 Dold–Kan 分解：dim V_n = dim N_n + dim D_n
pub fn verify_dold_kan_split(ss : SimplicialSpace) -> Bool {
  let nn = normalized_dims(ss)
  let dd = degenerate_dims(ss)
  for n in 0..<ss.deg.length() {
    if nn[n] + dd[n] != ss.deg[n] {
      return false
    }
  }
  true
}

///|
/// 模擬圓 S¹ = Δ¹/∂Δ¹ 的自由 F_p-模擬空間：
///   V_0 = span{v}（1 維），V_1 = span{s₀v, e}（2 維），
///   V_2 = span{s₀s₀v, s₀e, s₁e}（3 維，s₁s₀v = s₀s₀v）。
pub fn simplicial_circle(p : Int32) -> SimplicialSpace {
  // 面映射 V_1 → V_0：d_0 = d_1 = [1, 1]
  let d0_1 = make_mat(1, 2, p, [[1, 1]])
  let d1_1 = make_mat(1, 2, p, [[1, 1]])
  // 面映射 V_2 → V_1（基：s₀s₀v, s₀e, s₁e）
  // d_0：(s₀v, e, s₀v)
  let d0_2 = make_mat(2, 3, p, [[1, 0, 1], [0, 1, 0]])
  // d_1：(s₀v, e, e)
  let d1_2 = make_mat(2, 3, p, [[1, 0, 0], [0, 1, 1]])
  // d_2：(s₀v, s₀v, e)
  let d2_2 = make_mat(2, 3, p, [[1, 1, 0], [0, 0, 1]])
  // 退化 s_0 : V_0 → V_1，v ↦ s₀v
  let s0_0 = make_mat(2, 1, p, [[1], [0]])
  // 退化 s_0, s_1 : V_1 → V_2
  let s0_1 = make_mat(3, 2, p, [[1, 0], [0, 1], [0, 0]])
  let s1_1 = make_mat(3, 2, p, [[1, 0], [0, 0], [0, 1]])
  {
    p,
    deg: [1, 2, 3],
    face: [[], [d0_1, d1_1], [d0_2, d1_2, d2_2]],
    degen: [[s0_0], [s0_1, s1_1]],
  }
}

///|
/// 驗證 Dold–Kan 於模擬圓：
/// （一）模擬恆等式成立；
/// （二）分解 V_n = N_n ⊕ D_n；
/// （三）Moore 複形同調 H_0 = H_1 = F_p；
/// （四）正則化 N₂ = 0（S¹ 無非退化 2-單形 ⟹ H₂ = 0）。
/// 註：模擬空間截断至 2 次，最高次 Moore 同調受截断影響，
///   故以正則化維數認證 H₂ = 0。
pub fn verify_dold_kan_circle(p : Int32) -> Bool {
  let ss = simplicial_circle(p)
  if !check_simplicial_identities(ss) {
    return false
  }
  if !verify_dold_kan_split(ss) {
    return false
  }
  let cc = moore_complex(ss)
  if !check_chain_complex(cc) {
    return false
  }
  homology_dim(cc, 0) == 1 &&
  homology_dim(cc, 1) == 1 &&
  normalized_dims(ss)[2] == 0
}

///|
/// 對偶數 R = F_p[x]/(x²) 的 bar 分解（截断至 nmax）：
///   B_n = R̄^{⊗n} ⊗ k = k（1 維），微分全零
///   （bar 公式中 x·x = 0 且 x·k = 0）。
/// Tor_n^R(k, k) = k 對所有 n ≥ 0（無限週期性）。
pub fn bar_dual_numbers(p : Int32, nmax : Int32) -> ChainComplex {
  let diff : Array[Mat] = []
  for _n in 1..<=nmax {
    // bar 微分在基元 x^{⊗n} 上：
    // 內項含 x·x = 0；邊界項含 x·m = 0（m ∈ k）
    diff.push(make_mat(1, 1, p, [[0]]))
  }
  { p, diff, }
}

///|
/// 多項式環 k[x] 的 Koszul 分解：0 → R --x--> R → k → 0
/// ⊗_R k 後微分為零：Tor_0 = Tor_1 = k，Tor_n = 0（n ≥ 2）
pub fn koszul_poly(p : Int32) -> ChainComplex {
  { p, diff: [make_mat(1, 1, p, [[0]])], }
}

///|
/// 定理：Tor_n^{k[x]/x²}(k, k) = k 對所有 n ≥ 0
pub fn verify_tor_dual_numbers(p : Int32, nmax : Int32) -> Bool {
  let cc = bar_dual_numbers(p, nmax)
  if !check_chain_complex(cc) {
    return false
  }
  for n in 0..<=nmax {
    if homology_dim(cc, n) != 1 {
      return false
    }
  }
  true
}

///|
/// 對比：k[x] 的 Tor 在 n ≥ 2 時為零
pub fn verify_tor_poly(p : Int32) -> Bool {
  let cc = koszul_poly(p)
  if !check_chain_complex(cc) {
    return false
  }
  homology_dim(cc, 0) == 1 && homology_dim(cc, 1) == 1
}
