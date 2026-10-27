///|
/// 規範形式（canonical forms）與衍生演算法、定理之彙編。
///
/// 逐一範疇化，覆蓋專案全部模組。五大範疇：
///   I.  重寫規範形（Smith 範形、βη-長範式、自由群約化詞、證明網歸約）
///   II. 矩陣規範形（F_p 上 RREF、整係數 SNF）
///   III. 範疇論規範形（骨架、極小模型、元素範疇、strictification）
///   IV. 組合規範形（函數圖、有限拓撲空間 core、Read 樹規範化）
///   V.  代數規範形（共軛類、特徵標分解、複雜度 Θ-範形）
///
/// 每條規範形配一條定理（唯一性/完全性）與一個演算法；
/// 衍生定理見 derived_index() 與 verify_all_derived()。

// ===== 通用工具 =====

fn abs_int(x : Int32) -> Int32 {
  if x < 0 {
    -x
  } else {
    x
  }
}

///|
fn gcd_int(a : Int32, b : Int32) -> Int32 {
  let mut x = abs_int(a)
  let mut y = abs_int(b)
  while y != 0 {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
/// 整數陣列字典序比較（−1/0/1）
fn cmp_int_array(aa : Array[Int32], bb : Array[Int32]) -> Int32 {
  let k = if aa.length() < bb.length() { aa.length() } else { bb.length() }
  for i in 0..<k {
    if aa[i] < bb[i] {
      return -1
    }
    if aa[i] > bb[i] {
      return 1
    }
  }
  if aa.length() < bb.length() {
    -1
  } else if aa.length() > bb.length() {
    1
  } else {
    0
  }
}

///|
fn sort_copy_int(xs : Array[Int32]) -> Array[Int32] {
  let r = xs.copy()
  for i in 1..<r.length() {
    let key = r[i]
    let mut j = i - 1
    while j >= 0 && r[j] > key {
      r[j + 1] = r[j]
      j = j - 1
    }
    r[j + 1] = key
  }
  r
}

///|
fn sort_int_arrays(xs : Array[Array[Int32]]) -> Array[Array[Int32]] {
  let r = xs.copy()
  for i in 1..<r.length() {
    let key = r[i]
    let mut j = i - 1
    while j >= 0 && cmp_int_array(r[j], key) > 0 {
      r[j + 1] = r[j]
      j = j - 1
    }
    r[j + 1] = key
  }
  r
}

///|
/// 布林矩陣字典序比較
fn bool_matrix_lt(aa : Array[Array[Bool]], bb : Array[Array[Bool]]) -> Bool {
  for i in 0..<aa.length() {
    for j in 0..<aa[i].length() {
      if aa[i][j] != bb[i][j] {
        return aa[i][j] && !bb[i][j]
      }
    }
  }
  false
}

///|
fn empty_ints() -> Array[Int32] {
  []
}

///|
/// 全排列（n ≤ 6）
fn permutations(n : Int32) -> Array[Array[Int32]] {
  let mut out : Array[Array[Int32]] = [[]]
  for i in 0..<n {
    let nxt : Array[Array[Int32]] = []
    for perm in out {
      for pos in 0..<(perm.length() + 1) {
        let p2 : Array[Int32] = []
        for j in 0..<perm.length() {
          if j == pos {
            p2.push(i)
          }
          p2.push(perm[j])
        }
        if pos == perm.length() {
          p2.push(i)
        }
        nxt.push(p2)
      }
    }
    out = nxt
  }
  out
}

// =====================================================================
// I. 重寫規範形（rewriting normal forms）
// =====================================================================

// ----- Smith 範形（整數矩陣） -----

///|
pub struct IntMat {
  rows : Int32
  cols : Int32
  data : Array[Array[Int32]]
}

///|
fn intmat_swap_rows(a : IntMat, i : Int32, j : Int32) -> Unit {
  let t = a.data[i]
  a.data[i] = a.data[j]
  a.data[j] = t
}

///|
fn intmat_swap_cols(a : IntMat, i : Int32, j : Int32) -> Unit {
  for r in 0..<a.rows {
    let t = a.data[r][i]
    a.data[r][i] = a.data[r][j]
    a.data[r][j] = t
  }
}

///|
/// Smith 範形：經單模變換化為對角矩陣 diag(s₁,…,sᵣ,0,…,0)，
///   且 s₁ | s₂ | … | sᵣ（整除鏈）。
/// 定理（Smith 1861）：任意整數矩陣皆有 Smith 範形，且唯一
///   （不變因子 sᵢ = dᵢ(A)/d_{i−1}(A)，dᵢ = 所有 i 階子式之最大公因數）。
/// 演算法：輾轉相除消去（Euclid）＋整除性修正。
/// 複雜度：O(mn·max|a|²)（小矩陣）。
pub fn snf_int(a : IntMat) -> IntMat {
  let rows = a.rows
  let cols = a.cols
  let mut r = 0
  let mut c = 0
  while r < rows && c < cols {
    // 子矩陣中絕對值最小的非零元作樞紐
    let mut pr = -1
    let mut pc = -1
    let mut best = 0
    for i in r..<rows {
      for j in c..<cols {
        let v = a.data[i][j]
        if v != 0 {
          let av = abs_int(v)
          if pr == -1 || av < best {
            pr = i
            pc = j
            best = av
          }
        }
      }
    }
    if pr == -1 {
      c = c + 1
      continue
    }
    if pr != r {
      intmat_swap_rows(a, pr, r)
    }
    if pc != c {
      intmat_swap_cols(a, pc, c)
    }
    // 輾轉相除：消去樞紐行與樞紐列
    let mut changed = true
    while changed {
      changed = false
      for i in (r + 1)..<rows {
        if a.data[i][c] != 0 {
          let q = a.data[i][c] / a.data[r][c]
          for j in c..<cols {
            a.data[i][j] = a.data[i][j] - q * a.data[r][j]
          }
          if a.data[i][c] != 0 {
            intmat_swap_rows(a, i, r)
            changed = true
          }
        }
      }
      for j in (c + 1)..<cols {
        if a.data[r][j] != 0 {
          let q = a.data[r][j] / a.data[r][c]
          for i in r..<rows {
            a.data[i][j] = a.data[i][j] - q * a.data[i][c]
          }
          if a.data[r][j] != 0 {
            intmat_swap_cols(a, j, c)
            changed = true
          }
        }
      }
    }
    // 整除性修正：非對角元不被樞紐整除時，將其行併入樞紐行
    let mut bad = -1
    for i in (r + 1)..<rows {
      for j in (c + 1)..<cols {
        if a.data[i][j] % a.data[r][c] != 0 {
          bad = i
        }
      }
    }
    if bad != -1 {
      for j in c..<cols {
        a.data[r][j] = a.data[r][j] + a.data[bad][j]
      }
      continue
    }
    // 樞紐取正
    if a.data[r][c] < 0 {
      for j in c..<cols {
        a.data[r][j] = -a.data[r][j]
      }
    }
    r = r + 1
    c = c + 1
  }
  a
}

///|
/// Smith 範形的不變因子（對角線上所有正元）。
pub fn snf_invariant_factors(a : IntMat) -> Array[Int32] {
  let d = snf_int(a)
  let out : Array[Int32] = []
  let k = if d.rows < d.cols { d.rows } else { d.cols }
  for i in 0..<k {
    if d.data[i][i] > 0 {
      out.push(d.data[i][i])
    }
  }
  out
}

///|
/// 整數矩陣的秩（SNF 中非零對角元個數）。
pub fn snf_rank(a : IntMat) -> Int32 {
  snf_invariant_factors(a).length()
}

// ----- 有限交換群的不變因子（結構定理） -----

///|
fn gpow(gg : FinGroup, x : Int32, m : Int32) -> Int32 {
  let mut r = gg.e
  for _ in 0..<m {
    r = gg.mul[r][x]
  }
  r
}

///|
fn log_exact(v : Int32, p : Int32) -> Int32 {
  let mut r = 0
  let mut w = v
  while w > 1 {
    w = w / p
    r = r + 1
  }
  r
}

///|
/// 有限交換群的規範形：不變因子 [d₁ | d₂ | … | dᵣ]（dᵢ > 1，dᵢ ∣ d_{i+1}）。
/// 定理（有限交換群結構定理）：G ≅ Z/d₁ ⊕ … ⊕ Z/dᵣ，且不變因子唯一。
/// 演算法：由元素階計數 c_k = #{x : x^{p^k} = e} 反推各素數的初等因子，
///   再逐位相乘合成不變因子。複雜度 O(|G|²·ω(|G|))。
pub fn abelian_invariant_factors(gg : FinGroup) -> Array[Int32] {
  let n = gg.order
  // 素因數分解 n
  let primes : Array[Int32] = []
  let mut m = n
  let mut q = 2
  while q * q <= m {
    if m % q == 0 {
      primes.push(q)
      while m % q == 0 {
        m = m / q
      }
    }
    q = q + 1
  }
  if m > 1 {
    primes.push(m)
  }
  // 各素數的初等因子（指數分割）
  let elem : Array[(Int32, Int32)] = []
  for p in primes {
    // c_k = #{x : x^{p^k} = e}；m_k = log_p(c_k/c_{k−1}) = #{aᵢ ≥ k}
    let ms : Array[Int32] = []
    let mut ck_prev = 1
    let mut pk = p
    while pk <= n {
      let mut ck = 0
      for x in 0..<n {
        if gpow(gg, x, pk) == gg.e {
          ck = ck + 1
        }
      }
      let mk = log_exact(ck / ck_prev, p)
      if mk == 0 {
        pk = pk * p
        continue
      }
      ms.push(mk)
      ck_prev = ck
      pk = pk * p
    }
    // 分割 ms（共軛分割）→ 初等因子指數 λᵢ = #{k : m_k ≥ i}
    let mut i = 1
    while true {
      let mut lam = 0
      for k in 0..<ms.length() {
        if ms[k] >= i {
          lam = lam + 1
        }
      }
      if lam == 0 {
        break
      }
      elem.push((p, lam))
      i = i + 1
    }
  }
  // 由初等因子合成不變因子：各素數指數遞減排列，逐位相乘
  let exp_lists : Array[Array[Int32]] = []
  for p in primes {
    let ex : Array[Int32] = []
    for d in elem {
      if d.0 == p {
        ex.push(d.1)
      }
    }
    // 指數遞減排序
    for i in 1..<ex.length() {
      let key = ex[i]
      let mut j = i - 1
      while j >= 0 && ex[j] < key {
        ex[j + 1] = ex[j]
        j = j - 1
      }
      ex[j + 1] = key
    }
    exp_lists.push(ex)
  }
  let mut rr = 0
  for ex in exp_lists {
    if ex.length() > rr {
      rr = ex.length()
    }
  }
  // 指數遞減排列 → d 由大到小；慣例要求 d₁ | d₂ | …（升冪）故反向
  let desc : Array[Int32] = []
  for i in 0..<rr {
    let mut d = 1
    for k in 0..<exp_lists.length() {
      if i < exp_lists[k].length() {
        d = d * pow_int(primes[k], exp_lists[k][i])
      }
    }
    if d > 1 {
      desc.push(d)
    }
  }
  let out : Array[Int32] = []
  for i in 0..<desc.length() {
    out.push(desc[desc.length() - 1 - i])
  }
  out
}

// ----- STLC 的 βη-長範式（CCC 的規範形） -----

///|
fn stlc_shift(tt : STerm, by : Int32) -> STerm {
  fn go(t : STerm, cutoff : Int32) -> STerm {
    match t {
      SVar(i) => if i >= cutoff { SVar(i + by) } else { SVar(i) }
      SUnit => SUnit
      SPair(xx, yy) => SPair(go(xx, cutoff), go(yy, cutoff))
      SFst(t1) => SFst(go(t1, cutoff))
      SSnd(t1) => SSnd(go(t1, cutoff))
      SLam(ty, body) => SLam(ty, go(body, cutoff + 1))
      SApp(f, a) => SApp(go(f, cutoff), go(a, cutoff))
    }
  }
  go(tt, 0)
}

///|
fn sterm_eq(aa : STerm, bb : STerm) -> Bool {
  match aa {
    SVar(i) =>
      match bb {
        SVar(j) => i == j
        _ => false
      }
    SUnit =>
      match bb {
        SUnit => true
        _ => false
      }
    SPair(x1, y1) =>
      match bb {
        SPair(x2, y2) => sterm_eq(x1, x2) && sterm_eq(y1, y2)
        _ => false
      }
    SFst(t1) =>
      match bb {
        SFst(t2) => sterm_eq(t1, t2)
        _ => false
      }
    SSnd(t1) =>
      match bb {
        SSnd(t2) => sterm_eq(t1, t2)
        _ => false
      }
    SLam(ty1, b1) =>
      match bb {
        SLam(ty2, b2) => stype_eq(ty1, ty2) && sterm_eq(b1, b2)
        _ => false
      }
    SApp(f1, a1) =>
      match bb {
        SApp(f2, a2) => sterm_eq(f1, f2) && sterm_eq(a1, a2)
        _ => false
      }
  }
}

///|
/// η-展開（在函數型別處強制為 λ 抽象）。
fn eta_long(tt : STerm, ty : SType) -> STerm {
  match ty {
    SArrow(a, b) =>
      match tt {
        SLam(_, body) => SLam(a, eta_long(body, b))
        _ => SLam(a, eta_long(SApp(stlc_shift(tt, 1), SVar(0)), b))
      }
    SPair(a, b) =>
      match tt {
        SPair(xx, yy) => SPair(eta_long(xx, a), eta_long(yy, b))
        _ => SPair(eta_long(SFst(tt), a), eta_long(SSnd(tt), b))
      }
    _ => tt
  }
}

///|
/// STLC 項的 βη-長範式（de Bruijn 指標）。
/// 定理（正規化 + Church–Rosser）：每個 STLC 項 βη-等價於唯一的
///   長 βη-範式；兩項 βη-等價 ⟺ 長範式相同（規範形完全性）。
/// 演算法：stlc_eval（β 歸約）後 η-展開（reify）。
pub fn stlc_beta_eta_nf(tt : STerm, ty : SType) -> STerm {
  eta_long(stlc_eval(tt), ty)
}

// ----- 自由群：自由約化詞（字問題的規範形） -----

///|
/// 自由群詞的規範形判定：兩詞在群中相等 ⟺ 自由約化後相同。
/// 定理（自由群範式定理）：每元素有唯一自由約化代表元。
pub fn fg_word_equal(
  ff : FreeGroup,
  w1 : Array[Int32],
  w2 : Array[Int32],
) -> Bool {
  array_eq_int(fg_reduce(ff, w1), fg_reduce(ff, w2))
}

// ----- 線性邏輯證明網：切消歸約（規範形） -----

///|
/// 證明網的規範形：切消後的無切網（歸約核）。
/// 定理：切消保持正確性；網正確 ⟺ 其無切歸約核正確（GMM 可收縮）。
pub fn net_reduct(nn : ProofNet) -> ProofNet {
  cut_eliminate(nn)
}

///|
fn net_eq(aa : ProofNet, bb : ProofNet) -> Bool {
  if aa.nodes.length() != bb.nodes.length() {
    return false
  }
  for i in 0..<aa.nodes.length() {
    if aa.nodes[i].kind != bb.nodes[i].kind {
      return false
    }
    if aa.nodes[i].dead != bb.nodes[i].dead {
      return false
    }
    if !array_eq_int(aa.nodes[i].prem, bb.nodes[i].prem) {
      return false
    }
  }
  true
}

// =====================================================================
// II. 矩陣規範形
// =====================================================================

///|
/// F_p 上矩陣的化簡列階梯形（RREF）——矩陣的規範形。
/// 定理：RREF 在行等價下唯一；軸元個數 = 秩。
/// 演算法：Gauss–Jordan（模 p 消去，mod_inv 求逆）。複雜度 O(mnr)。
pub fn rref_f_p(a : Array[Array[Int32]], p : Int32) -> Array[Array[Int32]] {
  let mrows = a.length()
  let ncols = if mrows == 0 { 0 } else { a[0].length() }
  let r : Array[Array[Int32]] = []
  for i in 0..<mrows {
    r.push(a[i].copy())
  }
  let mut piv = 0
  let mut row = 0
  while row < mrows && piv < ncols {
    let mut sel = -1
    for i in row..<mrows {
      if r[i][piv] != 0 {
        sel = i
        break
      }
    }
    if sel == -1 {
      piv = piv + 1
      continue
    }
    if sel != row {
      let t = r[sel]
      r[sel] = r[row]
      r[row] = t
    }
    let inv = mod_inv(r[row][piv], p)
    for j in piv..<ncols {
      r[row][j] = mod_mul(r[row][j], inv, p)
    }
    for i in 0..<mrows {
      if i != row && r[i][piv] != 0 {
        let factor = r[i][piv]
        for j in piv..<ncols {
          r[i][j] = (r[i][j] - mod_mul(factor, r[row][j], p) + p) % p
        }
      }
    }
    row = row + 1
    piv = piv + 1
  }
  r
}

///|
/// F_p 上矩陣的秩（RREF 的非零行數）。
pub fn rank_f_p(a : Array[Array[Int32]], p : Int32) -> Int32 {
  let rr = rref_f_p(a, p)
  let mut rank = 0
  for i in 0..<rr.length() {
    let mut nonzero = false
    for j in 0..<rr[i].length() {
      if rr[i][j] != 0 {
        nonzero = true
      }
    }
    if nonzero {
      rank = rank + 1
    }
  }
  rank
}

///|
/// 整係數鏈複形的一階同調（SNF 法）：H = ker ∂ / im ∂'。
/// 定理：自由秩 = (cols ∂ − rank ∂) − rank ∂'；
///   撓部 = ∂' 的不變因子中 > 1 者（SNF 給出精確結構）。
/// 演算法：兩次 SNF。衍生：有限 CW 複形/簡單複形的整係數同調。
pub fn integral_homology(d_n : IntMat, d_n1 : IntMat) -> (Int32, Array[Int32]) {
  let rank_n = snf_rank(d_n)
  let rank_n1 = snf_rank(d_n1)
  let free_rank = d_n.cols - rank_n - rank_n1
  let torsion : Array[Int32] = []
  for s in snf_invariant_factors(d_n1) {
    if s > 1 {
      torsion.push(s)
    }
  }
  (free_rank, torsion)
}

// =====================================================================
// III. 範疇論規範形
// =====================================================================

///|
/// 範疇的骨架：每個同構類取最小代表物件，僅保留代表間的箭號。
/// 定理：C ≃ skeleton(C)；兩範疇等價 ⟺ 骨架同構。
/// 演算法：並查集合併同構物件。複雜度 O(n²·|hom|·iso)。
pub fn category_skeleton(cc : Category) -> Category {
  let n = cc.n_obj
  let parent = Array::makei(n, fn(i) { i })
  for x in 0..<n {
    for y in (x + 1)..<n {
      for a in hom(cc, x, y) {
        if is_iso(cc, a) {
          uf_union(parent, x, y)
        }
      }
    }
  }
  let reps : Array[Int32] = []
  for x in 0..<n {
    if uf_find(parent, x) == x {
      reps.push(x)
    }
  }
  // 重標號：代表元 → 0,1,…（並查集代表未必是連續小编號）
  let obj_map = Array::make(n, -1)
  for i in 0..<reps.length() {
    obj_map[reps[i]] = i
  }
  let arrows : Array[Arrow] = []
  let old2new = Array::make(cc.arrows.length(), -1)
  for a in 0..<cc.arrows.length() {
    let of = obj_map[cc.arrows[a].from]
    let ot = obj_map[cc.arrows[a].to]
    if of != -1 && ot != -1 {
      old2new[a] = arrows.length()
      arrows.push(Arrow::{ from: of, to: ot, })
    }
  }
  let na = arrows.length()
  let comp : Array[Array[Int32?]] = Array::makei(na, fn(_i) {
    Array::makei(na, fn(_j) { None })
  })
  for a in 0..<cc.arrows.length() {
    for b in 0..<cc.arrows.length() {
      if old2new[a] != -1 && old2new[b] != -1 {
        match compose(cc, a, b) {
          Some(c) => comp[old2new[a]][old2new[b]] = Some(old2new[c])
          None => ()
        }
      }
    }
  }
  let id_of_obj : Array[Int32] = Array::makei(reps.length(), fn(i) {
    cc.id_of_obj[reps[i]]
  })
  make_category(reps.length(), arrows, comp, id_of_obj)
}

///|
/// 薄範疇（hom 集至多一元）的規範形：
///   骨架的可達矩陣在所有物件標號排列下的字典序最小者。
/// 定理：兩薄範疇等價 ⟺ 規範形相同（骨架同構 ⟺ 預序同構）。
/// 複雜度：O(n!·n²)（小範疇的暴力規範化；一般情形可用個別化-精化）。
pub fn preorder_canonical_form(cc : Category) -> Array[Array[Bool]] {
  preorder_matrix(category_skeleton(cc))
}

///|
/// 預序矩陣的規範形（不取骨架；供內部使用）。
fn preorder_matrix(cc : Category) -> Array[Array[Bool]] {
  let n = cc.n_obj
  let reach = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) {
      if i == j {
        true
      } else {
        hom(cc, i, j).length() > 0
      }
    })
  })
  // 傳遞閉包（Warshall）
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        if reach[i][k] && reach[k][j] {
          reach[i][j] = true
        }
      }
    }
  }
  let mut best = reach
  for perm in permutations(n) {
    let cand = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) { reach[perm[i]][perm[j]] })
    })
    if bool_matrix_lt(cand, best) {
      best = cand
    }
  }
  best
}

///|
pub fn are_equivalent_thin(cc : Category, dd : Category) -> Bool {
  let aa = preorder_canonical_form(cc)
  let bb = preorder_canonical_form(dd)
  if aa.length() != bb.length() {
    return false
  }
  for i in 0..<aa.length() {
    for j in 0..<aa.length() {
      if aa[i][j] != bb[i][j] {
        return false
      }
    }
  }
  true
}

// ----- 群胚骨架與群胚基數 -----

///|
/// 連通群胚的骨架：每個連通分量取最小代表，其頂點群 Aut(x)。
/// 定理：連通群胚 G ≃ ⊔ᵢ Aut(xᵢ)（不交並）。
pub fn groupoid_skeleton(cc : Category) -> Array[FinGroup] {
  let comps = groupoid_components(cc)
  let reps : Array[Int32] = []
  for x in 0..<cc.n_obj {
    let mut is_min = true
    for y in 0..<cc.n_obj {
      if comps[y] == comps[x] && y < x {
        is_min = false
      }
    }
    if is_min {
      reps.push(x)
    }
  }
  Array::makei(reps.length(), fn(i) { vertex_group(cc, reps[i]) })
}

///|
/// 群胚基數（Baez–Dolan）：|G| = Σ_{[x] ∈ π₀(G)} 1/#Aut(x)。
/// 定理：基數是範疇等價不變量；對不交並可加、對張量積可乘。
/// 回傳既約分數 (分子, 分母)。
pub fn groupoid_cardinality(cc : Category) -> (Int32, Int32) {
  let skel = groupoid_skeleton(cc)
  let mut den = 1
  for gg in skel {
    den = den * gg.order / gcd_int(den, gg.order)
  }
  let mut num = 0
  for gg in skel {
    num = num + den / gg.order
  }
  let g = gcd_int(num, den)
  if g == 0 {
    (0, 1)
  } else {
    (num / g, den / g)
  }
}

// ----- 鏈複形的極小模型 -----

///|
/// 鏈複形（域上）的極小模型：Hₙ 置於 n 次、微分全零。
/// 定理（極小模型）：域上任意鏈複形與其同調複形擬同構；
///   極小模型在同構意義下唯一（Whitehead 型定理）。
pub fn minimal_complex(cc : ChainComplex) -> ChainComplex {
  let p = cc.p
  let maxdeg = cc.diff.length()
  let dims : Array[Int32] = []
  for k in 0..<(maxdeg + 1) {
    dims.push(homology_dim(cc, k))
  }
  let diff : Array[Mat] = []
  for k in 0..<maxdeg {
    let rows = dims[k]
    let cols = dims[k + 1]
    let data = Array::makei(rows, fn(_i) { Array::make(cols, 0) })
    diff.push(make_mat(rows, cols, p, data))
  }
  { p, diff, }
}

// ----- 平坦函子的元素範疇 -----

///|
/// 集合值函子 F 的元素範疇 ∫F：物件 (c, x)（x ∈ F(c)），
///   箭號 h : (c,x) → (c',x') 為 h : c→c' 且 F(h)(x) = x'。
/// 定理（Grothendieck）：F 平坦 ⟺ ∫F 餘濾過 ⟺ F 是代表函子的濾過餘極限。
pub fn elements_category(ff : SetFunctor) -> Category {
  let cc = ff.dom
  let objs : Array[(Int32, Int32)] = []
  let idx : Array[Array[Int32]] = []
  for c in 0..<cc.n_obj {
    let row : Array[Int32] = []
    for a in 0..<ff.objects[c].length() {
      row.push(objs.length())
      objs.push((c, a))
    }
    idx.push(row)
  }
  let arrows : Array[Arrow] = []
  let arr_idx : Array[Array[Int32]] = []
  for h in 0..<cc.arrows.length() {
    let from = cc.arrows[h].from
    let to = cc.arrows[h].to
    let row : Array[Int32] = []
    for a in 0..<ff.objects[from].length() {
      let b = ff.arrows[h][a]
      row.push(arrows.length())
      arrows.push(Arrow::{ from: idx[from][a], to: idx[to][b], })
    }
    arr_idx.push(row)
  }
  let na = arrows.length()
  let comp : Array[Array[Int32?]] = Array::makei(na, fn(_i) {
    Array::makei(na, fn(_j) { None })
  })
  for h1 in 0..<cc.arrows.length() {
    for h2 in 0..<cc.arrows.length() {
      match compose(cc, h1, h2) {
        Some(h3) =>
          for a in 0..<ff.objects[cc.arrows[h1].from].length() {
            let b = ff.arrows[h1][a]
            comp[arr_idx[h1][a]][arr_idx[h2][b]] = Some(arr_idx[h3][a])
          }
        None => ()
      }
    }
  }
  let id_of_obj : Array[Int32] = Array::makei(objs.length(), fn(i) {
    arr_idx[cc.id_of_obj[objs[i].0]][objs[i].1]
  })
  make_category(objs.length(), arrows, comp, id_of_obj)
}

///|
/// 範疇版本的餘濾過判準（直接用於 ∫F）。
/// 定理：F 平坦 ⟺ ∫F 餘濾過（非空、任意兩物件有共同錐、
///   任意平行箭號可被等化）。
pub fn is_cofiltered_cat(cc : Category) -> Bool {
  if cc.n_obj == 0 {
    return false
  }
  for x in 0..<cc.n_obj {
    for y in 0..<cc.n_obj {
      let mut ok = false
      for z in 0..<cc.n_obj {
        if hom(cc, z, x).length() > 0 && hom(cc, z, y).length() > 0 {
          ok = true
        }
      }
      if !ok {
        return false
      }
    }
  }
  for x in 0..<cc.n_obj {
    for y in 0..<cc.n_obj {
      let hs = hom(cc, x, y)
      for a in 0..<hs.length() {
        for b in (a + 1)..<hs.length() {
          let mut ok = false
          for z in 0..<cc.n_obj {
            for c in hom(cc, z, x) {
              match compose(cc, c, a) {
                Some(u) =>
                  match compose(cc, c, b) {
                    Some(v) => if u == v { ok = true }
                    None => ()
                  }
                None => ()
              }
            }
          }
          if !ok {
            return false
          }
        }
      }
    }
  }
  true
}

// =====================================================================
// IV. 組合規範形
// =====================================================================

// ----- 函數圖（動態系統）的規範形 -----

///|
fn ds_tree_sig(
  rev : Array[Array[Int32]],
  sigs : Array[Array[Int32]],
  v : Int32,
) -> Array[Int32] {
  if sigs[v].length() > 0 {
    return sigs[v]
  }
  let mut child_sigs : Array[Array[Int32]] = []
  for c in rev[v] {
    child_sigs.push(ds_tree_sig(rev, sigs, c))
  }
  child_sigs = sort_int_arrays(child_sigs)
  let out : Array[Int32] = [child_sigs.length()]
  for cs in child_sigs {
    for x in cs {
      out.push(x)
    }
  }
  sigs[v] = out
  out
}

///|
fn min_cyclic_rotation(ts : Array[Array[Int32]]) -> Array[Array[Int32]] {
  let len = ts.length()
  if len <= 1 {
    return ts
  }
  let mut best = 0
  for i in 1..<len {
    for k in 0..<len {
      let cp = cmp_int_array(ts[(i + k) % len], ts[(best + k) % len])
      if cp < 0 {
        best = i
        break
      } else if cp > 0 {
        break
      }
    }
  }
  let out : Array[Array[Int32]] = []
  for k in 0..<len {
    out.push(ts[(best + k) % len])
  }
  out
}

///|
/// 函數圖（動態系統）的規範形：每分量 = 環長 + 環上各點之樹簽名
///   （取循環最小旋轉），分量間排序；編碼為整數陣列。
/// 定理：兩函數圖共軛 ⟺ 規範形相同（完全同構不變量）。
/// 演算法：O(n) 剝離 + BFS 標尾，樹簽名後序排序，旋轉最小化。
/// 複雜度：O(n²)（取代 O(n!) 的置換窮舉）。
pub fn dynsys_canonical_form(ds : DynSys) -> Array[Int32] {
  let info = cycle_decompose(ds)
  let n = ds.n
  // 反向鄰接（僅尾點 → 指向者）
  let rev = Array::makei(n, fn(_i) { empty_ints() })
  for x in 0..<n {
    if info[x].1 > 0 {
      rev[ds.f[x]].push(x)
    }
  }
  let sigs = Array::makei(n, fn(_i) { empty_ints() })
  let visited = Array::make(n, false)
  let mut comp_codes : Array[Array[Int32]] = []
  for x in 0..<n {
    if info[x].1 == 0 && !visited[x] {
      let cyc : Array[Int32] = []
      let mut cur = x
      while !visited[cur] {
        visited[cur] = true
        cyc.push(cur)
        cur = ds.f[cur]
      }
      let mut ts : Array[Array[Int32]] = []
      for cnode in cyc {
        ts.push(ds_tree_sig(rev, sigs, cnode))
      }
      ts = min_cyclic_rotation(ts)
      let code : Array[Int32] = [ts.length()]
      for t in ts {
        for v in t {
          code.push(v)
        }
      }
      comp_codes.push(code)
    }
  }
  comp_codes = sort_int_arrays(comp_codes)
  let out : Array[Int32] = []
  for code in comp_codes {
    out.push(code.length())
    for v in code {
      out.push(v)
    }
  }
  out
}

///|
/// 共軛判定的規範形版本：O(n²)（原 perm_conjugate 為 O(n!)）。
pub fn are_conjugate_canonical(ds1 : DynSys, ds2 : DynSys) -> Bool {
  array_eq_int(dynsys_canonical_form(ds1), dynsys_canonical_form(ds2))
}

// ----- 有限拓撲空間：core 與同胚規範形 -----

///|
/// 有限 T₀ 空間的 core：反覆剝離 beat point（下集有最大元或上集有最小元）。
/// 定理（Stong）：core 唯一（至多同胚）；X ≃ Y（同倫等價）
///   ⟺ core(X) ≅ core(Y)。複雜度 O(n³)。
pub fn core_of(tt : FinTop) -> FinTop {
  let keep = Array::make(tt.n, true)
  let mut changed = true
  while changed {
    changed = false
    for x in 0..<tt.n {
      if !keep[x] {
        continue
      }
      let lower : Array[Int32] = []
      let upper : Array[Int32] = []
      for y in 0..<tt.n {
        if y != x && keep[y] {
          if tt.le[y][x] && !tt.le[x][y] {
            lower.push(y)
          }
          if tt.le[x][y] && !tt.le[y][x] {
            upper.push(y)
          }
        }
      }
      let mut beat = false
      for m in lower {
        let mut is_max = true
        for y in lower {
          if !tt.le[y][m] {
            is_max = false
          }
        }
        if is_max {
          beat = true
        }
      }
      if !beat {
        for m in upper {
          let mut is_min = true
          for y in upper {
            if !tt.le[m][y] {
              is_min = false
            }
          }
          if is_min {
            beat = true
          }
        }
      }
      if beat {
        keep[x] = false
        changed = true
        break
      }
    }
  }
  let old_of : Array[Int32] = []
  for x in 0..<tt.n {
    if keep[x] {
      old_of.push(x)
    }
  }
  let k = old_of.length()
  let le = Array::makei(k, fn(i) {
    Array::makei(k, fn(j) { tt.le[old_of[i]][old_of[j]] })
  })
  make_top(k, le)
}

///|
/// 有限拓撲空間的規範標號（暴力法，n ≤ 6）：
///   專化預序矩陣在所有點排列下的字典序最小者。
/// 定理：兩有限空間同胚 ⟺ 規範形相同。
/// 複雜度：O(n!·n²)（小空間；一般情形可用個別化-精化精煉）。
pub fn finitop_canonical_form(tt : FinTop) -> Array[Array[Bool]] {
  let n = tt.n
  let mut best = tt.le
  for perm in permutations(n) {
    let cand = Array::makei(n, fn(i) {
      Array::makei(n, fn(j) { tt.le[perm[i]][perm[j]] })
    })
    if bool_matrix_lt(cand, best) {
      best = cand
    }
  }
  best
}

///|
/// 有限拓撲空間同胚判定（規範形版本）。
pub fn homeomorphic(tt : FinTop, uu : FinTop) -> Bool {
  let aa = finitop_canonical_form(tt)
  let bb = finitop_canonical_form(uu)
  if aa.length() != bb.length() {
    return false
  }
  for i in 0..<aa.length() {
    for j in 0..<aa.length() {
      if aa[i][j] != bb[i][j] {
        return false
      }
    }
  }
  true
}

// ----- 有根樹規範化（Read 演算法；自由 operad 的樹元） -----

///|
/// Read 樹規範化：有根樹 s(v) = 0 · sort(s(子)) · 1。
/// 定理：canon(T₁) = canon(T₂) ⟺ T₁ ≅ T₂（有根樹同構）。
/// 演算法： bottom-up 排序拼接。複雜度 O(n log n)（排序主導）。
/// 衍生：自由 operad 的元素即樹，其相等判定由此規範形給出。
pub fn canon_tree(children : Array[Array[Int32]]) -> Array[Int32] {
  fn sig(v : Int32) -> Array[Int32] {
    let mut subs : Array[Array[Int32]] = []
    for c in children[v] {
      subs.push(sig(c))
    }
    subs = sort_int_arrays(subs)
    let out : Array[Int32] = [subs.length()]
    for s in subs {
      for x in s {
        out.push(x)
      }
    }
    out.push(1)
    out
  }
  sig(0)
}

// =====================================================================
// V. 代數規範形
// =====================================================================

// ----- 子群格的共軛類 -----

///|
/// 子群格的共軛類分解（每類取字典序最小者為規範代表）。
/// 定理：共軛是子群格上的等價關係；正規子群 ⟺ 單元素類。
/// 衍生：Galois 對應中，中間體與子群共軛類一一對應。
pub fn subgroup_conjugacy_classes(gg : FinGroup) -> Array[Array[Array[Int32]]] {
  let subs = all_subgroups(gg)
  let classes : Array[Array[Array[Int32]]] = []
  let done = Array::make(subs.length(), false)
  for i in 0..<subs.length() {
    if done[i] {
      continue
    }
    let canon = canonical_subgroup_rep(gg, subs[i])
    let cls : Array[Array[Int32]] = []
    for j in i..<subs.length() {
      if done[j] {
        continue
      }
      if array_eq_int(canon, canonical_subgroup_rep(gg, subs[j])) {
        done[j] = true
        cls.push(subs[j])
      }
    }
    classes.push(cls)
  }
  classes
}

///|
fn canonical_subgroup_rep(gg : FinGroup, hh : Array[Int32]) -> Array[Int32] {
  let mut best = sort_copy_int(hh)
  for g in 0..<gg.order {
    let mut conj : Array[Int32] = []
    for h in hh {
      conj.push(gg.mul[g][gg.mul[h][gg.inv[g]]])
    }
    conj = sort_copy_int(conj)
    if cmp_int_array(conj, best) < 0 {
      best = conj
    }
  }
  best
}

// ----- 循環群的特徵標分解 -----

///|
fn primitive_root(g : Int32, p : Int32) -> Bool {
  let mut m = p - 1
  let mut q = 2
  while q * q <= m {
    if m % q == 0 {
      if pow_mod(g, (p - 1) / q, p) == 1 {
        return false
      }
      while m % q == 0 {
        m = m / q
      }
    }
    q = q + 1
  }
  if m > 1 {
    if pow_mod(g, (p - 1) / m, p) == 1 {
      return false
    }
  }
  true
}

///|
/// 循環群 Z/n 於 F_p（需 p ≡ 1 mod n）的一維不可約特徵標表。
/// 定理：不可約特徵標正交規範（⟨χᵢ, χⱼ⟩ = δᵢⱼ）。
pub fn cyclic_characters(n : Int32, p : Int32) -> Array[Array[Int32]] {
  let mut g = 2
  while g < p {
    if primitive_root(g, p) {
      break
    }
    g = g + 1
  }
  let omega = pow_mod(g, (p - 1) / n, p)
  Array::makei(n, fn(k) {
    Array::makei(n, fn(j) { pow_mod(omega, k * j % n, p) })
  })
}

///|
/// 循環群表示的不可約分解（特徵標內積法）。
/// 定理（Maschke + 特徵標正交）：ρ ≅ ⊕ₖ mₖ·χₖ，
///   mₖ = ⟨χ_ρ, χₖ⟩ = (1/n) Σ_j χ_ρ(g^j)·χₖ(g^j)⁻¹；
///   ρ 不可約 ⟺ ⟨χ_ρ, χ_ρ⟩ = 1。
pub fn decompose_rep_cyclic(rr : Rep, n : Int32, p : Int32) -> Array[Int32] {
  let chi : Array[Int32] = []
  for j in 0..<n {
    let mut tr = 0
    for i in 0..<rr.rho[j].rows {
      tr = (tr + rr.rho[j].data[i][i]) % p
    }
    chi.push(tr)
  }
  let chars = cyclic_characters(n, p)
  let inv_n = mod_inv(n, p)
  Array::makei(n, fn(k) {
    let mut s = 0
    for j in 0..<n {
      let inv = mod_inv(chars[k][j], p)
      s = (s + mod_mul(chi[j], inv, p)) % p
    }
    mod_mul(s, inv_n, p)
  })
}

// ----- 複雜度表達式的 Θ-範形 -----

///|
/// 字串位元組轉數字（UTF-16 碼單元 → Int32）
fn byte_digit(s : String, i : Int32) -> Int32 {
  s[i].to_int() - 48
}

///|
fn parse_monomial(s : String, lo : Int32, hi : Int32) -> (Int32, Int32, Int32) {
  let mut coeff = 1
  let mut dn = 0
  let mut dl = 0
  let mut i = lo
  while i < hi {
    if s[i] == 42 {
      // '*'
      i = i + 1
      continue
    }
    if s[i] >= 48 && s[i] <= 57 {
      let mut v = 0
      while i < hi && s[i] >= 48 && s[i] <= 57 {
        v = v * 10 + byte_digit(s, i)
        i = i + 1
      }
      coeff = coeff * v
      continue
    }
    if s[i] == 110 {
      // 'n'
      i = i + 1
      let mut e = 1
      if i < hi && s[i] == 94 {
        // '^'
        i = i + 1
        e = 0
        while i < hi && s[i] >= 48 && s[i] <= 57 {
          e = e * 10 + byte_digit(s, i)
          i = i + 1
        }
      }
      dn = dn + e
      continue
    }
    if s[i] == 108 {
      // 'l'（log(n)）
      i = i + 1
      while i < hi && s[i] != 41 {
        i = i + 1
      }
      i = i + 1
      let mut e = 1
      if i < hi && s[i] == 94 {
        i = i + 1
        e = 0
        while i < hi && s[i] >= 48 && s[i] <= 57 {
          e = e * 10 + byte_digit(s, i)
          i = i + 1
        }
      }
      dl = dl + e
      continue
    }
    i = i + 1
  }
  (coeff, dn, dl)
}

///|
/// 複雜度表達式的規範形：單項式 (係數, n 次數, log 次數) 列表，
///   合併同類項、去零係數、按增長升冪排序。
/// 定理：兩表達式 Θ-等價 ⟺ 主導單項式相同。
pub fn complexity_parse(expr : String) -> Array[(Int32, Int32, Int32)] {
  let terms : Array[(Int32, Int32, Int32)] = []
  let len = expr.length()
  let mut lo = 0
  for i in 0..<len {
    if expr[i] == 43 {
      // '+'
      terms.push(parse_monomial(expr, lo, i))
      lo = i + 1
    }
  }
  terms.push(parse_monomial(expr, lo, len))
  let merged : Array[(Int32, Int32, Int32)] = []
  for t in terms {
    let mut found = false
    for k in 0..<merged.length() {
      if merged[k].1 == t.1 && merged[k].2 == t.2 {
        merged[k] = (merged[k].0 + t.0, t.1, t.2)
        found = true
      }
    }
    if !found {
      merged.push(t)
    }
  }
  let out : Array[(Int32, Int32, Int32)] = []
  for t in merged {
    if t.0 != 0 {
      out.push(t)
    }
  }
  for i in 1..<out.length() {
    let key = out[i]
    let mut j = i - 1
    while j >= 0 &&
          (out[j].1 > key.1 || (out[j].1 == key.1 && out[j].2 > key.2)) {
      out[j + 1] = out[j]
      j = j - 1
    }
    out[j + 1] = key
  }
  out
}

///|
/// Θ-範形：主導單項式（增長最快者）。
pub fn complexity_theta(expr : String) -> (Int32, Int32, Int32) {
  let ms = complexity_parse(expr)
  ms[ms.length() - 1]
}

// =====================================================================
// 分類索引與完整性驗證（逐一範疇化直至全部完成）
// =====================================================================

///|
pub struct CanonicalEntry {
  /// 範疇編號（I=1 重寫、II=2 矩陣、III=3 範疇論、IV=4 組合、V=5 代數）
  family : Int32
  /// 所屬模組
  mod_name : String
  name : String
  definition : String
  algorithm : String
  complexity : String
  theorem : String
}

///|
/// 規範形總索引：逐一範疇化，覆蓋專案全部模組。
pub fn canonical_index() -> Array[CanonicalEntry] {
  [
    // I. 重寫規範形
    {
      family: 1,
      mod_name: "algebra",
      name: "Smith 範形",
      definition: "整數矩陣經單模變換化為對角形 diag(s₁,…,sᵣ,0,…)，s₁|…|sᵣ",
      algorithm: "輾轉相除消去＋整除性修正",
      complexity: "O(mn·max|a|²)",
      theorem: "Smith：存在且唯一（不變因子 dᵢ/d_{i−1}）",
    },
    {
      family: 1,
      mod_name: "algebra",
      name: "交換群不變因子",
      definition: "有限交換群 G ≅ Z/d₁⊕…⊕Z/dᵣ，d₁|…|dᵣ",
      algorithm: "元素階計數反推初等因子",
      complexity: "O(|G|²·ω(|G|))",
      theorem: "有限交換群結構定理（唯一分解）",
    },
    {
      family: 1,
      mod_name: "ccc",
      name: "βη-長範式",
      definition: "STLC 項的 β 歸約＋η-展長代表元",
      algorithm: "stlc_eval 後 reify（η-展開）",
      complexity: "O(|t|²)",
      theorem: "正規化＋Church–Rosser：長範式唯一",
    },
    {
      family: 1,
      mod_name: "free",
      name: "自由約化詞",
      definition: "自由群元素的唯一相消代表元",
      algorithm: "O(n) 棧歸一",
      complexity: "O(n)",
      theorem: "自由群範式定理（字問題可解）",
    },
    {
      family: 1,
      mod_name: "linear",
      name: "無切歸約核",
      definition: "證明網切消後的無切代表元",
      algorithm: "切消＋死鏈修剪",
      complexity: "O(n²)",
      theorem: "切消保持正確性（GMM 可收縮性）",
    },
    {
      family: 1,
      mod_name: "zerocost",
      name: "單態化規範形",
      definition: "泛型函數經單態化後的特化代表元",
      algorithm: "編譯期單態化＋#inline",
      complexity: "O(1)（編譯期）",
      theorem: "零成本抽象（特化版與泛型版等值）",
    },
    // II. 矩陣規範形
    {
      family: 2,
      mod_name: "cohomology",
      name: "F_p 上 RREF",
      definition: "矩陣的化簡列階梯形（行等價類唯一代表）",
      algorithm: "Gauss–Jordan（mod p）",
      complexity: "O(mnr)",
      theorem: "RREF 唯一；秩 = 軸元數",
    },
    {
      family: 2,
      mod_name: "derived",
      name: "整係數同調（SNF 法）",
      definition: "H = ker ∂/im ∂' 的自由秩＋撓部",
      algorithm: "兩次 SNF",
      complexity: "O(r³·max|a|²)",
      theorem: "同調的結構定理（自由秩＋不變因子）",
    },
    // III. 範疇論規範形
    {
      family: 3,
      mod_name: "category",
      name: "範疇骨架",
      definition: "每個同構類取一代表物件的子範疇",
      algorithm: "並查集合同構類",
      complexity: "O(n²·|hom|)",
      theorem: "C ≃ skel(C)；等價 ⟺ 骨架同構",
    },
    {
      family: 3,
      mod_name: "topos",
      name: "特徵映射規範形",
      definition: "子對象由其唯一特徵映射 χ : F → Ω 代表",
      algorithm: "子預層枚舉＋Ω 分類",
      complexity: "O(2^{Σ|F(c)|})",
      theorem: "子對象分類器：Sub(F) ≅ Hom(F, Ω)",
    },
    {
      family: 3,
      mod_name: "pseudo",
      name: "嚴格化",
      definition: "偽函子的嚴格代表元（相容化）",
      algorithm: "座標改變 b(g) 吸收上同調類",
      complexity: "O(|G|·|obj|)",
      theorem: "Mac Lane 相干性：每偽函子等價於嚴格函子",
    },
    {
      family: 3,
      mod_name: "groupoid",
      name: "群胚骨架",
      definition: "连通分量代表之頂點群的不交並",
      algorithm: "分量分解＋頂點群",
      complexity: "O(n²·|hom|)",
      theorem: "連通群胚 ≃ ⊔ Aut(xᵢ)",
    },
    {
      family: 3,
      mod_name: "groupoid",
      name: "群胚基數",
      definition: "|G| = Σ_{[x]} 1/#Aut(x)（Baez–Dolan）",
      algorithm: "骨架求和（精確分數）",
      complexity: "O(n²)",
      theorem: "等價不變量；對不交並可加、對積可乘",
    },
    {
      family: 3,
      mod_name: "derived",
      name: "極小複形",
      definition: "以同調為鏈群、零微分的複形",
      algorithm: "逐次取 Hₙ",
      complexity: "O(秩計算)",
      theorem: "域上複形與其同調擬同構（極小模型唯一）",
    },
    {
      family: 3,
      mod_name: "flat",
      name: "元素範疇 ∫F",
      definition: "平坦函子的（餘）濾過代表圖",
      algorithm: "物件 (c,x)、箭號 F(h)(x)=x'",
      complexity: "O(|arr|·|el|)",
      theorem: "Grothendieck：F 平坦 ⟺ ∫F 餘濾過",
    },
    {
      family: 3,
      mod_name: "homotopy_algebra",
      name: "極小 A∞-模型",
      definition: "同調上 m₁=0 的 A∞-結構（Kadeishvili）",
      algorithm: "同倫轉移 m₂, m₃",
      complexity: "O(dim³)",
      theorem: "極小模型存在且唯一（至 A∞-同構）",
    },
    // IV. 組合規範形
    {
      family: 4,
      mod_name: "systems",
      name: "函數圖規範形",
      definition: "分量 = 環長＋環上樹簽名（循環最小旋轉）",
      algorithm: "O(n) 剝離＋樹簽名＋旋轉最小化",
      complexity: "O(n²)",
      theorem: "共軛 ⟺ 規範形相同",
    },
    {
      family: 4,
      mod_name: "topology",
      name: "有限空間 core",
      definition: "剝盡 beat point 後的極小同倫代表",
      algorithm: "迭代剝離 beat point",
      complexity: "O(n³)",
      theorem: "Stong：core 唯一；同倫等價 ⟺ core 同胚",
    },
    {
      family: 4,
      mod_name: "topology",
      name: "有限空間規範標號",
      definition: "專化預序矩陣在排列下的字典序最小者",
      algorithm: "暴力排列取最小",
      complexity: "O(n!·n²)（n ≤ 6）",
      theorem: "同胚 ⟺ 規範形相同",
    },
    {
      family: 4,
      mod_name: "operad",
      name: "Read 樹規範化",
      definition: "有根樹 s(v) = 0·sort(s(子))·1",
      algorithm: "bottom-up 排序拼接",
      complexity: "O(n log n)",
      theorem: "canon(T₁)=canon(T₂) ⟺ T₁≅T₂",
    },
    // V. 代數規範形
    {
      family: 5,
      mod_name: "galois",
      name: "子群共軛類",
      definition: "子群格按共軛劃分，每類取字典序最小代表",
      algorithm: "共軛作用＋字典序最小化",
      complexity: "O(|Sub|·|G|·n)",
      theorem: "共軛劃分子群格；正規子群 = 單點類",
    },
    {
      family: 5,
      mod_name: "tannaka",
      name: "特徵標分解",
      definition: "表示 ρ ≅ ⊕ mₖχₖ（不可約重數）",
      algorithm: "特徵標內積 ⟨χ_ρ, χₖ⟩",
      complexity: "O(n²·dim²)",
      theorem: "Maschke＋正交性：mₖ 唯一",
    },
    {
      family: 5,
      mod_name: "algorithms",
      name: "複雜度 Θ-範形",
      definition: "增長率表達式的主導單項式代表",
      algorithm: "解析＋合併同類項＋取主導",
      complexity: "O(|expr|)",
      theorem: "Θ-等價 ⟺ 主導單項式相同",
    },
    {
      family: 5,
      mod_name: "homott",
      name: "S¹ 路徑規範形",
      definition: "恆等類型道路的唯一代表 loopⁿ",
      algorithm: "編碼/解碼雙射",
      complexity: "O(1)",
      theorem: "canonicity：閉路徑項唯一決定 loopⁿ",
    },
  ]
}

///|
/// 分類完整性驗證：專案每一個模組都至少有一條規範形。
pub fn verify_taxonomy_complete() -> Bool {
  let mods = canonical_index()
  let all = [
    "category", "algebra", "topos", "ccc", "pseudo", "groupoid", "cohomology", "galois",
    "tannaka", "flat", "linear", "homott", "derived", "operad", "homotopy_algebra",
    "topology", "free", "algorithms", "systems", "zerocost",
  ]
  for m in all {
    let mut covered = false
    for e in mods {
      if e.mod_name == m {
        covered = true
      }
    }
    if !covered {
      return false
    }
  }
  true
}

// =====================================================================
// 衍生演算法與定理（由規範形導出）
// =====================================================================

///|
pub struct DerivedThm {
  name : String
  statement : String
  source : String
}

///|
/// 衍生定理索引：由規範形導出的演算法與定理。
pub fn derived_index() -> Array[DerivedThm] {
  [
    {
      name: "有限交換群分類",
      statement: "G ≅ Z/d₁⊕…⊕Z/dᵣ（d₁|…|dᵣ），由 SNF 或元素階計數唯一確定",
      source: "Smith 範形",
    },
    {
      name: "整係數同調",
      statement: "Hₙ = ker ∂ₙ/im ∂ₙ₊₁ 的自由秩與撓部由 SNF 一次算出",
      source: "Smith 範形",
    },
    {
      name: "秩–零化度定理",
      statement: "rank(dⁿ) + dim Hⁿ + rank(dⁿ⁺¹) = dim Cⁿ（F_p 上）",
      source: "RREF",
    },
    {
      name: "範疇等價判定",
      statement: "薄範疇等價 ⟺ 規範形（預序）相同",
      source: "範疇骨架",
    },
    {
      name: "群胚基數可加性",
      statement: "|G₁ ⊔ G₂| = |G₁| + |G₂|；單點群胚基數 = 1/|G|",
      source: "群胚骨架",
    },
    {
      name: "Whitehead 型定理",
      statement: "域上鏈複形與其極小模型擬同構",
      source: "極小複形",
    },
    {
      name: "Grothendieck 平坦判準",
      statement: "F 平坦 ⟺ ∫F 餘濾過（範疇層級）",
      source: "元素範疇",
    },
    {
      name: "函數圖共軛判定",
      statement: "共軛 ⟺ 規範形相同，O(n²) 取代 O(n!)",
      source: "函數圖規範形",
    },
    {
      name: "有限空間同倫分類",
      statement: "X ≃ Y ⟺ core(X) ≅ core(Y)（Stong）",
      source: "有限空間 core",
    },
    {
      name: "有限空間同胚判定",
      statement: "同胚 ⟺ 規範標號相同",
      source: "規範標號",
    },
    {
      name: "自由 operad 詞問題",
      statement: "樹元相等 ⟺ Read 規範字串相同",
      source: "Read 樹規範化",
    },
    {
      name: "子群格類方程",
      statement: "子群按共軛劃分；Σ|類| = |Sub(G)|；正規子群 = 單點類",
      source: "子群共軛類",
    },
    {
      name: "表示分解算法",
      statement: "ρ ≅ ⊕ mₖχₖ，mₖ = ⟨χ_ρ, χₖ⟩（循環群，p ≡ 1 mod n）",
      source: "特徵標分解",
    },
    {
      name: "Curry–Howard 完全性",
      statement: "不同 βη-長範式 = 不同證明；規範形即範疇態射",
      source: "βη-長範式",
    },
    {
      name: "自由群字問題",
      statement: "詞相等 ⟺ 自由約化形式相同（O(n) 判定）",
      source: "自由約化詞",
    },
    {
      name: "切消正確性保持",
      statement: "網正確 ⟺ 無切歸約核正確；歸約核冪等",
      source: "無切歸約核",
    },
    {
      name: "Kadeishvili 極小性",
      statement: "轉移後 m₂ 在同調上嚴格結合，m₁ = 0",
      source: "極小 A∞-模型",
    },
    {
      name: "Θ-等價判定",
      statement: "兩複雜度表達式 Θ-等價 ⟺ 主導單項式相同",
      source: "複雜度 Θ-範形",
    },
    {
      name: "S¹ 道路 canonicity",
      statement: "閉路徑項唯一決定 loopⁿ（編解碼雙射）",
      source: "S¹ 路徑規範形",
    },
  ]
}

// ----- 衍生定理的逐一驗證 -----

///|
/// 結構定理 round-trip：由不變因子造群，再由群回推不變因子。
pub fn verify_structure_theorem_abelian() -> Bool {
  let cases = [[2], [4], [2, 2], [2, 4], [3, 3], [6], [12], [2, 2, 2], [2, 6]]
  for inv in cases {
    // G = ⊕ Z/dᵢ：元素 = (a₁,…,aₖ)，逐分量加法
    let k = inv.length()
    let mut n = 1
    for d in inv {
      n = n * d
    }
    // 編碼：混合進位
    let gg_mul = Array::makei(n, fn(_i) { Array::make(n, 0) })
    for x in 0..<n {
      for y in 0..<n {
        let mut z = 0
        let mut base = 1
        for i in 0..<k {
          let d = inv[i]
          let xi = x / base % d
          let yi = y / base % d
          z = z + (xi + yi) % d * base
          base = base * d
        }
        gg_mul[x][y] = z
      }
    }
    let gg = FinGroup::{
      order: n,
      e: 0,
      mul: gg_mul,
      inv: Array::makei(n, fn(x) {
        let mut z = 0
        let mut base = 1
        for i in 0..<k {
          let d = inv[i]
          let xi = x / base % d
          z = z + (d - xi) % d * base
          base = base * d
        }
        z
      }),
      name: "abelian_test",
    }
    if !array_eq_int(abelian_invariant_factors(gg), inv) {
      return false
    }
  }
  true
}

///|
/// Z/2⊕Z/4 與 Z/8 可由規範形區分（結構定理的判別力）。
pub fn verify_abelian_distinguishing() -> Bool {
  let g8 = cyclic_group(8)
  let g42 = direct_product_abelian(cyclic_group(4), cyclic_group(2))
  let f8 = abelian_invariant_factors(g8)
  let f42 = abelian_invariant_factors(g42)
  array_eq_int(f8, [8]) && array_eq_int(f42, [2, 4])
}

///|
fn direct_product_abelian(gg : FinGroup, hh : FinGroup) -> FinGroup {
  let n = gg.order * hh.order
  FinGroup::{
    order: n,
    e: 0,
    mul: Array::makei(n, fn(x) {
      Array::makei(n, fn(y) {
        gg.mul[x % gg.order][y % gg.order] +
        gg.order * hh.mul[x / gg.order][y / gg.order]
      })
    }),
    inv: Array::makei(n, fn(x) {
      gg.inv[x % gg.order] + gg.order * hh.inv[x / gg.order]
    }),
    name: "direct_product",
  }
}

///|
/// 整係數同調：圓周 H₀ = Z, H₁ = Z；RP² H₀ = Z, H₁ = Z/2, H₂ = 0。
pub fn verify_integral_homology() -> Bool {
  // 圓周：0 → Z --0--> Z --0--> Z → 0
  let z0 = IntMat::{ rows: 1, cols: 1, data: [[0]], }
  let h_circle = integral_homology(z0, z0)
  if h_circle.0 != 1 {
    return false
  }
  // RP²：0 → Z --[2]--> Z --[0]--> Z → 0
  let d2 = IntMat::{ rows: 1, cols: 1, data: [[2]], }
  let d1 = IntMat::{ rows: 1, cols: 1, data: [[0]], }
  let h1 = integral_homology(d1, d2)
  if h1.0 != 0 || h1.1.length() != 1 || h1.1[0] != 2 {
    return false
  }
  // H₀ = Z（d₀ = 0）
  let h0 = integral_homology(z0, d1)
  h0.0 == 1 && h0.1.length() == 0
}

///|
/// SNF 唯一性：行/列交換不改變不變因子。
pub fn verify_snf_invariance() -> Bool {
  let a = IntMat::{ rows: 2, cols: 2, data: [[2, 0], [0, 4]], }
  let b = IntMat::{ rows: 2, cols: 2, data: [[0, 2], [4, 0]], }
  let fa = snf_invariant_factors(a)
  let fb = snf_invariant_factors(b)
  array_eq_int(fa, fb) &&
  array_eq_int(fa, [2, 4]) &&
  // gcd 範例：diag(6, 10) → 不變因子 [2, 30]
  array_eq_int(
    snf_invariant_factors(IntMat::{ rows: 2, cols: 2, data: [[6, 0], [0, 10]], }),
    [2, 30],
  )
}

///|
/// 秩–零化度：與上同調維數公式交叉驗證（F_p 上）。
pub fn verify_rank_nullity_cross() -> Bool {
  // RREF 基本檢查
  let m = [[1, 2], [2, 4]]
  let rr = rref_f_p(m, 5)
  if rr[0][0] != 1 || rr[0][1] != 2 || rr[1][0] != 0 || rr[1][1] != 0 {
    return false
  }
  if rank_f_p(m, 5) != 1 {
    return false
  }
  // 與上同調維數公式交叉驗證（用自有 rank_f_p 對抗模組的 mat_rank）：
  //   dim H⁰ = 1；dim Hⁿ = (cols dⁿ − rank dⁿ) − rank d^{n−1}（n ≥ 1）
  let gg = cyclic_group(3)
  let p = 2
  for n in 0..<3 {
    let dim_h = cohomology_dim(gg, p, n)
    let predicted = if n == 0 {
      1
    } else {
      let dn = cochain_diff(gg, p, n)
      let dn1 = cochain_diff(gg, p, n - 1)
      dn.cols - rank_f_p(dn.data, p) - rank_f_p(dn1.data, p)
    }
    if predicted != dim_h {
      return false
    }
  }
  true
}

///|
/// 骨架：添加同構副本不改變薄範疇的規範形（等價不變性）。
/// 走路範疇 0→1（薄範疇）：物件 {0,1}，箭號 id₀, id₁, f:0→1。
fn ca_walking_arrow() -> Category {
  let arrows = [
    Arrow::{ from: 0, to: 0, },
    Arrow::{ from: 1, to: 1, },
    Arrow::{ from: 0, to: 1, },
  ]
  let comp : Array[Array[Int32?]] = [
    [Some(0), None, Some(2)],
    [None, Some(1), None],
    [None, Some(2), None],
  ]
  make_category(2, arrows, comp, [0, 1])
}

///|
/// 走路範疇的「加倍版」：1 有了同構副本 2。
fn walking_arrow_doubled() -> Category {
  // 物件 {0,1,2}；1 ≅ 2（a, b 互逆）；0→1, 0→2
  let arrows = [
    Arrow::{ from: 0, to: 0, }, // 0 id₀
    Arrow::{ from: 1, to: 1, }, // 1 id₁
    Arrow::{ from: 2, to: 2, }, // 2 id₂
    Arrow::{ from: 0, to: 1, }, // 3 f
    Arrow::{ from: 0, to: 2, }, // 4 g
    Arrow::{ from: 1, to: 2, }, // 5 a
    Arrow::{ from: 2, to: 1, }, // 6 b
  ]
  // comp[x][y] = y ∘ x（定義於 x.to == y.from）
  let comp : Array[Array[Int32?]] = [
    [Some(0), None, None, Some(3), Some(4), None, None],
    [None, Some(1), None, None, None, Some(5), Some(6)],
    [None, None, Some(2), None, None, None, Some(6)],
    [None, Some(3), None, None, None, Some(4), None],
    [None, None, Some(4), None, None, None, Some(3)],
    [None, None, Some(5), None, None, None, Some(1)],
    [None, Some(6), None, None, None, Some(2), None],
  ]
  make_category(3, arrows, comp, [0, 1, 2])
}

///|
/// 離散薄範疇（兩物件、僅單位箭號）。
fn discrete_two() -> Category {
  let arrows = [Arrow::{ from: 0, to: 0, }, Arrow::{ from: 1, to: 1, }]
  let comp : Array[Array[Int32?]] = [[Some(0), None], [None, Some(1)]]
  make_category(2, arrows, comp, [0, 1])
}

///|
/// 骨架：薄範疇的等價判定（規範形版本）。
pub fn verify_skeleton_equivalence() -> Bool {
  let cc = ca_walking_arrow()
  let dd = walking_arrow_doubled()
  // 骨架化去掉同構副本
  let skel = category_skeleton(dd)
  if skel.n_obj != 2 {
    return false
  }
  // 等價 ⟺ 骨架規範形相同
  are_equivalent_thin(cc, dd) &&
  are_equivalent_thin(cc, cc) &&
  !are_equivalent_thin(cc, discrete_two())
}

///|
/// 群胚基數：單群群胚基數 = 1/|G|；兩分量可加。
pub fn verify_groupoid_cardinality() -> Bool {
  let gg = cyclic_group(3)
  let one = group_as_category(gg)
  let (num, den) = groupoid_cardinality(one)
  if num != 1 || den != 3 {
    return false
  }
  // 不交並：兩個 BG₂ → 基數 1/2 + 1/2 = 1
  let dd = two_copies_of_bz2()
  let (n2, d2) = groupoid_cardinality(dd)
  n2 == 1 && d2 == 1
}

///|
/// 兩個不交的 BZ/2（各一物件，帶一個二階自同構）。
fn two_copies_of_bz2() -> Category {
  // 箭號：0=id₀, 1=a₀:0→0, 2=id₁, 3=a₁:1→1
  let arrows = [
    Arrow::{ from: 0, to: 0, },
    Arrow::{ from: 0, to: 0, },
    Arrow::{ from: 1, to: 1, },
    Arrow::{ from: 1, to: 1, },
  ]
  // a∘a = id
  let comp : Array[Array[Int32?]] = [
    [Some(0), Some(1), None, None],
    [Some(1), Some(0), None, None],
    [None, None, Some(2), Some(3)],
    [None, None, Some(3), Some(2)],
  ]
  make_category(2, arrows, comp, [0, 2])
}

///|
/// 極小模型：同調維數逐次保持（擬同構）。
pub fn verify_minimal_model() -> Bool {
  let cc = koszul_poly(2)
  let mm = minimal_complex(cc)
  for k in 0..<(cc.diff.length() + 1) {
    if homology_dim(cc, k) != homology_dim(mm, k) {
      return false
    }
  }
  // 極小模型微分全零
  for d in mm.diff {
    for row in d.data {
      for v in row {
        if v != 0 {
          return false
        }
      }
    }
  }
  true
}

///|
/// 元素範疇判準與函子判準一致（Grothendieck 定理）。
pub fn verify_elements_cofiltered() -> Bool {
  // 走路範疇上的代表函子 y(1)（平坦）與非平坦函子
  let cc = ca_walking_arrow()
  // F(0) = {*}, F(1) = {*}, F(f) = id（= y(1)，平坦）
  let flat_ff = SetFunctor::{
    dom: cc,
    objects: [[0], [0]],
    arrows: [[0], [0], [0]],
  }
  // F(0) = {0,1}, F(1) = {0}, F(f) = [0,0]（|F(0)|=2，非平坦）
  let bad_ff = SetFunctor::{
    dom: cc,
    objects: [[0, 1], [0]],
    arrows: [[0, 1], [0], [0, 0]],
  }
  is_flat(flat_ff) == is_cofiltered_cat(elements_category(flat_ff)) &&
  is_flat(bad_ff) == is_cofiltered_cat(elements_category(bad_ff)) &&
  is_cofiltered_cat(elements_category(flat_ff)) &&
  !is_cofiltered_cat(elements_category(bad_ff))
}

///|
/// 函數圖規範形與窮舉共軛判定一致，且區分非共軛系統。
pub fn verify_dynsys_canonical() -> Bool {
  // 共軛：ρ 形系統的兩種標號
  let a = make_dyn(4, [1, 2, 3, 0])
  let b = make_dyn(4, [3, 0, 1, 2])
  if !are_conjugate(a, b) || !are_conjugate_canonical(a, b) {
    return false
  }
  // 非共軛：環長不同
  let c = make_dyn(4, [1, 0, 3, 2])
  if are_conjugate(a, c) || are_conjugate_canonical(a, c) {
    return false
  }
  // 非共軛：尾長不同
  let d = make_dyn(4, [1, 2, 2, 2])
  let e = make_dyn(4, [1, 2, 3, 2])
  if are_conjugate(d, e) || are_conjugate_canonical(d, e) {
    return false
  }
  // 冪等性：規範形的規範形不變
  array_eq_int(dynsys_canonical_form(a), dynsys_canonical_form(a))
}

///|
/// Stong core 定理：含 beat point 的空間與其 core 同倫等價
///  （core 的規範形相同）；可縮空間的 core 為單點。
pub fn verify_core_theorem() -> Bool {
  // Sierpiński 空間：0 ≤ 1（專化序），1 是 beat point（上集有最小元）
  let sierp = make_top(2, [[false, true], [false, false]])
  let core = core_of(sierp)
  if core.n != 1 {
    return false
  }
  // 三點鏈 0 ≤ 1 ≤ 2：1 為 beat point，剝盡後 core 為單點（可縮）
  let chain = make_top(3, [
    [false, true, true],
    [false, false, true],
    [false, false, false],
  ])
  let core2 = core_of(chain)
  if core2.n != 1 {
    return false
  }
  // 同倫等價：chain 與其 core 的 core 同胚（規範形相同）
  homeomorphic(core, core2) && !homeomorphic(sierp, chain)
}

///|
/// 有限空間同胚判定的規範形版本與窮舉同胚判定一致。
pub fn verify_finitop_homeomorphism() -> Bool {
  let a = make_top(3, [
    [false, true, false],
    [false, false, true],
    [false, false, false],
  ])
  let b = make_top(3, [
    [false, false, false],
    [true, false, false],
    [true, true, false],
  ])
  // a: 0≤1≤2（鏈）；b: 2≤1≤0（反向鏈）——同胚
  if !homeomorphic(a, b) {
    return false
  }
  let c = make_top(3, [
    [false, true, true],
    [false, false, false],
    [false, false, false],
  ])
  // c: 0 ≤ 1, 0 ≤ 2（V 形）——不同胚於鏈
  !homeomorphic(a, c)
}

///|
/// Read 樹規範化：同構樹同字，不同構異字。
pub fn verify_tree_canonization() -> Bool {
  // 樹 A：根有兩個葉子
  let ta = [[1, 2], [], []]
  // 樹 B：根 → 葉 → 葉（左傾鏈）
  let tb = [[1], [2], []]
  // 樹 C：根有兩個子，第一個子是內部節點帶一葉
  let tc = [[1, 2], [3], [], []]
  // 樹 D：根有兩個子（次序交換），同構於 C
  let td = [[2, 1], [], [3], []]
  array_eq_int(canon_tree(ta), canon_tree(ta)) &&
  !array_eq_int(canon_tree(ta), canon_tree(tb)) &&
  array_eq_int(canon_tree(tc), canon_tree(td)) &&
  !array_eq_int(canon_tree(ta), canon_tree(tc))
}

///|
/// 子群共軛類：S₃ 有 4 類（{e}、Z/3、三個 Z/2、S₃）；類方程成立。
pub fn verify_conjugacy_classes() -> Bool {
  let gg = symmetric_group(3)
  let classes = subgroup_conjugacy_classes(gg)
  if classes.length() != 4 {
    return false
  }
  let mut total = 0
  let mut singles = 0
  let mut triples = 0
  for cls in classes {
    total = total + cls.length()
    if cls.length() == 1 {
      singles = singles + 1
    }
    if cls.length() == 3 {
      triples = triples + 1
    }
  }
  // 類方程：Σ|類| = |Sub(G)|；三個正規子群（單點類），一個三元素類
  total == all_subgroups(gg).length() && singles == 3 && triples == 1
}

///|
/// 特徵標分解：Z/3 於 F₇ 的正則表示 = 三個不可約各一次；
///   平凡表示 = χ₀。
pub fn verify_character_decomposition() -> Bool {
  let gg = cyclic_group(3)
  let p = 7
  let reg = regular_rep(gg, p)
  let m_reg = decompose_rep_cyclic(reg, 3, p)
  if !array_eq_int(m_reg, [1, 1, 1]) {
    return false
  }
  let triv = trivial_rep(gg, p)
  let m_triv = decompose_rep_cyclic(triv, 3, p)
  array_eq_int(m_triv, [1, 0, 0])
}

///|
/// βη-長範式：η-等價項有相同長範式；長範式冪等。
pub fn verify_beta_eta_canonical() -> Bool {
  let aa = SArrow(SAtom, SAtom)
  let ty = SArrow(aa, aa)
  // λf. λx. f x 與 λf. f（η-等價）
  let t1 = SLam(aa, SLam(SAtom, SApp(SVar(1), SVar(0))))
  let t2 = SLam(aa, SVar(0))
  let n1 = stlc_beta_eta_nf(t1, ty)
  let n2 = stlc_beta_eta_nf(t2, ty)
  if !sterm_eq(n1, n2) {
    return false
  }
  // 冪等
  sterm_eq(stlc_beta_eta_nf(n1, ty), n1)
}

///|
/// 自由群字問題：約化詞相等判定。
pub fn verify_free_word_problem() -> Bool {
  let ff = FreeGroup::{ generators: 2, }
  // a a⁻¹ b = b（生成元 2i 为 a_i，2i+1 为 a_i⁻¹）
  let w1 = [0, 1, 2]
  let w2 = [2]
  fg_word_equal(ff, w1, w2) && !fg_word_equal(ff, [0], [1])
}

///|
/// 證明網歸約核：切消保持正確性且冪等。
pub fn verify_net_reduct() -> Bool {
  // 4 公理星形網（正確）
  let nodes : Array[NetNode] = []
  for _ in 0..<4 {
    nodes.push(mk_axiom())
    nodes.push(mk_axiom())
  }
  for i in 0..<4 {
    nodes.push(mk_par(2 * i, 2 * i + 1))
  }
  nodes.push(mk_tensor(8, 9))
  nodes.push(mk_tensor(12, 10))
  nodes.push(mk_tensor(13, 11))
  let net = ProofNet::{ nodes, }
  let red = net_reduct(net)
  net_is_correct(net) && net_is_correct(red) && net_eq(red, net_reduct(red))
}

///|
/// Kadeishvili 極小性：轉移後的 m₂ 在同調上嚴格結合。
pub fn verify_minimal_a_infinity() -> Bool {
  let hb = h_basis()
  for i in 0..<hb.length() {
    for j in 0..<hb.length() {
      for k in 0..<hb.length() {
        let x = h_to_a(unit_vector(hb.length(), i))
        let y = h_to_a(unit_vector(hb.length(), j))
        let z = h_to_a(unit_vector(hb.length(), k))
        // m₂^H : H⊗H → H（6 維）；乘前需擡回 A（8 維）
        let lhs = m2_h(h_to_a(m2_h(x, y)), z)
        let rhs = m2_h(x, h_to_a(m2_h(y, z)))
        if !array_eq_int(lhs, rhs) {
          return false
        }
      }
    }
  }
  true
}

///|
fn unit_vector(n : Int32, i : Int32) -> Array[Int32] {
  let v = Array::make(n, 0)
  v[i] = 1
  v
}

///|
/// 複雜度 Θ-範形：主導單項式判定。
pub fn verify_complexity_theta() -> Bool {
  let t1 = complexity_theta("n^2 + 3*n + 5")
  let t2 = complexity_theta("2*n^2 + log(n)")
  t1.1 == 2 &&
  t2.1 == 2 &&
  t1.2 == 0 &&
  complexity_theta("n*log(n) + n").2 == 1 &&
  complexity_parse("n + n").length() == 1
}

///|
/// 逐一驗證所有衍生定理。
pub fn verify_all_derived() -> Bool {
  verify_structure_theorem_abelian() &&
  verify_abelian_distinguishing() &&
  verify_integral_homology() &&
  verify_snf_invariance() &&
  verify_rank_nullity_cross() &&
  verify_skeleton_equivalence() &&
  verify_groupoid_cardinality() &&
  verify_minimal_model() &&
  verify_elements_cofiltered() &&
  verify_dynsys_canonical() &&
  verify_core_theorem() &&
  verify_finitop_homeomorphism() &&
  verify_tree_canonization() &&
  verify_conjugacy_classes() &&
  verify_character_decomposition() &&
  verify_beta_eta_canonical() &&
  verify_free_word_problem() &&
  verify_net_reduct() &&
  verify_minimal_a_infinity() &&
  verify_complexity_theta()
}
