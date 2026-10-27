/// 代數結構：Grp（有限群）、Ab（有限交換群）、Vectₖ（有限域上的線性代數）。
///
/// 定義（群）：集合 G 配二元運算 ·，滿足結合律、單位元、逆元。
/// 定義（交換群 Ab）：群運算交換。
/// 定義（Vectₖ）：域 k 上的向量空間；有限維時由基完全決定。
/// 定理（基判定）：線性映射／雙線性運算由其在基上的取值唯一決定——
///   故驗證公理只需在基上進行，複雜度由 O(n⁶) 降至 O(n³)（對結構常數）。
/// 定理（交換化）：H¹(G, M) ≅ Hom(G_ab, M)（平凡作用時），見 cohomology.mbt。
///
/// 實作註記：MoonBit 的 Int 為 32 位元，故所有模乘經 Int64 中轉，
/// 儲存值永遠落在 [0, p)（p < 2³⁰），運算中間值落在 [0, p²) ⊂ Int64。

///|
/// 有限群：以 Cayley 表表示
pub struct FinGroup {
  order : Int32
  mul : Array[Array[Int32]]
  inv : Array[Int32]
  e : Int32
  name : String
}

///|
/// 循環群 C_n = ℤ/nℤ
pub fn cyclic_group(n : Int32) -> FinGroup {
  let mul = Array::makei(n, fn(a) { Array::makei(n, fn(b) { (a + b) % n }) })
  let inv = Array::makei(n, fn(a) { (n - a) % n })
  { order: n, mul, inv, e: 0, name: "C_" + n.to_string(), }
}

///|
/// 對稱群 S_n（n ≤ 5 實際可行），排列以 Lehmer 編碼排序
pub fn symmetric_group(n : Int32) -> FinGroup {
  let perms : Array[Array[Int32]] = []
  let cur = Array::makei(n, fn(i) { i })
  let used = Array::make(n, false)
  gen_perms(n, cur, used, 0, perms)
  let order = perms.length()
  let index = Array::make(order, -1)
  for i in 0..<order {
    index[lehmer_rank(perms[i])] = i
  }
  let mul = Array::makei(order, fn(i) {
    Array::makei(order, fn(j) {
      let sg = perms[i]
      let tau = perms[j]
      let rho = Array::makei(n, fn(x) { sg[tau[x]] })
      index[lehmer_rank(rho)]
    })
  })
  let inv = Array::makei(order, fn(i) {
    let sg = perms[i]
    let rho = Array::make(n, 0)
    for x in 0..<n {
      rho[sg[x]] = x
    }
    index[lehmer_rank(rho)]
  })
  { order, mul, inv, e: 0, name: "S_" + n.to_string(), }
}

///|
fn gen_perms(
  n : Int32,
  cur : Array[Int32],
  used : Array[Bool],
  pos : Int32,
  out : Array[Array[Int32]],
) -> Unit {
  if pos == n {
    out.push(cur.copy())
    return
  }
  for v in 0..<n {
    if !used[v] {
      used[v] = true
      cur[pos] = v
      gen_perms(n, cur, used, pos + 1, out)
      used[v] = false
    }
  }
}

///|
/// 排列的 Lehmer 編碼（階乘數系）：O(n²)，免雜湊的 O(1) 索引——複雜度優化
fn lehmer_rank(sg : Array[Int32]) -> Int32 {
  let n = sg.length()
  let mut r = 0
  let mut fact = 1
  for i in 0..<n {
    fact = fact * (i + 1)
  }
  for i in 0..<n {
    fact = fact / (n - i)
    let mut smaller = 0
    for j in (i + 1)..<n {
      if sg[j] < sg[i] {
        smaller = smaller + 1
      }
    }
    r = r + smaller * fact
  }
  r
}

///|
/// 直積 G × H
pub fn direct_product(gg : FinGroup, hh : FinGroup) -> FinGroup {
  let n = gg.order * hh.order
  let mul = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) {
      let a = i / hh.order
      let b = i % hh.order
      let c = j / hh.order
      let d = j % hh.order
      gg.mul[a][c] * hh.order + hh.mul[b][d]
    })
  })
  let inv = Array::makei(n, fn(i) {
    gg.inv[i / hh.order] * hh.order + hh.inv[i % hh.order]
  })
  { order: n, mul, inv, e: 0, name: gg.name + "×" + hh.name, }
}

///|
/// 驗證群公理：Latin 方性、單位元、逆元、結合律。
/// 複雜度：O(n²) 檢驗 Latin/單位/逆元，O(n³) 結合律（最壞，早期退出）。
pub fn check_group(gg : FinGroup) -> Bool {
  let n = gg.order
  for a in 0..<n {
    if gg.mul[a][gg.e] != a || gg.mul[gg.e][a] != a {
      return false
    }
    if gg.mul[a][gg.inv[a]] != gg.e || gg.mul[gg.inv[a]][a] != gg.e {
      return false
    }
  }
  for a in 0..<n {
    let row_seen = Array::make(n, false)
    let col_seen = Array::make(n, false)
    for b in 0..<n {
      if row_seen[gg.mul[a][b]] {
        return false
      }
      row_seen[gg.mul[a][b]] = true
      if col_seen[gg.mul[b][a]] {
        return false
      }
      col_seen[gg.mul[b][a]] = true
    }
  }
  for a in 0..<n {
    for b in 0..<n {
      for c in 0..<n {
        if gg.mul[gg.mul[a][b]][c] != gg.mul[a][gg.mul[b][c]] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 對照可信模型驗證乘法表：複雜度 O(n²)（相對 O(n³) 暴力結合律檢驗）
pub fn check_group_model(gg : FinGroup, model : Array[Array[Int32]]) -> Bool {
  for a in 0..<gg.order {
    for b in 0..<gg.order {
      if gg.mul[a][b] != model[a][b] {
        return false
      }
    }
  }
  true
}

///|
/// 是否交換群（Ab）
pub fn is_abelian(gg : FinGroup) -> Bool {
  for a in 0..<gg.order {
    for b in 0..<gg.order {
      if gg.mul[a][b] != gg.mul[b][a] {
        return false
      }
    }
  }
  true
}

///|
/// 元素階
pub fn element_order(gg : FinGroup, x : Int32) -> Int32 {
  let mut r = 1
  let mut cur = x
  while cur != gg.e {
    cur = gg.mul[cur][x]
    r = r + 1
  }
  r
}

///|
/// 中心 Z(G)
pub fn center(gg : FinGroup) -> Array[Int32] {
  let r : Array[Int32] = []
  for a in 0..<gg.order {
    let mut ok = true
    for b in 0..<gg.order {
      if gg.mul[a][b] != gg.mul[b][a] {
        ok = false
        break
      }
    }
    if ok {
      r.push(a)
    }
  }
  r
}

///|
/// 由生成元集生成的子群（BFS 閉包，O(n·|S|)）
pub fn subgroup_closure(gg : FinGroup, gens : Array[Int32]) -> Array[Int32] {
  let in_h = Array::make(gg.order, false)
  let mut frontier : Array[Int32] = [gg.e]
  in_h[gg.e] = true
  while frontier.length() > 0 {
    let next : Array[Int32] = []
    for x in frontier {
      for g in gens {
        let y = gg.mul[x][g]
        if !in_h[y] {
          in_h[y] = true
          next.push(y)
        }
        let z = gg.mul[gg.inv[g]][x]
        if !in_h[z] {
          in_h[z] = true
          next.push(z)
        }
      }
    }
    frontier = next
  }
  let r : Array[Int32] = []
  for x in 0..<gg.order {
    if in_h[x] {
      r.push(x)
    }
  }
  r
}

///|
/// 交換子子群 [G, G]
pub fn commutator_subgroup(gg : FinGroup) -> Array[Int32] {
  let gens : Array[Int32] = []
  for a in 0..<gg.order {
    for b in 0..<gg.order {
      let c1 = gg.mul[a][b]
      let c2 = gg.mul[c1][gg.inv[a]]
      gens.push(gg.mul[c2][gg.inv[b]])
    }
  }
  subgroup_closure(gg, gens)
}

///|
/// 交換化 G_ab = G/[G, G]（商群）
pub fn abelianization(gg : FinGroup) -> FinGroup {
  let nn = commutator_subgroup(gg)
  let in_n = Array::make(gg.order, false)
  for x in nn {
    in_n[x] = true
  }
  let reps : Array[Int32] = []
  let coset = Array::make(gg.order, -1)
  for x in 0..<gg.order {
    if coset[x] == -1 {
      let ci = reps.length()
      reps.push(x)
      for n_ in nn {
        coset[gg.mul[x][n_]] = ci
      }
    }
  }
  let k = reps.length()
  let mul = Array::makei(k, fn(i) {
    Array::makei(k, fn(j) { coset[gg.mul[reps[i]][reps[j]]] })
  })
  let inv = Array::makei(k, fn(i) { coset[gg.inv[reps[i]]] })
  { order: k, mul, inv, e: 0, name: gg.name + "_ab", }
}

///|
/// 共軛類
pub fn conjugacy_classes(gg : FinGroup) -> Array[Array[Int32]] {
  let classes : Array[Array[Int32]] = []
  let seen = Array::make(gg.order, false)
  for a in 0..<gg.order {
    if !seen[a] {
      let cls : Array[Int32] = []
      for g in 0..<gg.order {
        let c = gg.mul[g][gg.mul[a][gg.inv[g]]]
        if !seen[c] {
          seen[c] = true
          cls.push(c)
        }
      }
      classes.push(cls)
    }
  }
  classes
}

///|
/// 群作為單物件範疇（用於範疇論模組）
pub fn group_as_category(gg : FinGroup) -> Category {
  let m = gg.order
  let arrows = Array::makei(m, fn(_) { Arrow::{ from: 0, to: 0, } })
  let comp = Array::makei(m, fn(a) {
    Array::makei(m, fn(b) { Some(gg.mul[a][b]) })
  })
  make_category(1, arrows, comp, [0])
}

// ---------------------------------------------------------------------------
// Vectₖ：有限域 F_p 上的矩陣與線性代數（所有模乘經 Int64 中轉）
// ---------------------------------------------------------------------------

///|
/// 有限域 F_p 上的矩陣
pub struct Mat {
  rows : Int32
  cols : Int32
  p : Int32
  data : Array[Array[Int32]]
}

///|
pub fn make_mat(
  rows : Int32,
  cols : Int32,
  p : Int32,
  data : Array[Array[Int32]],
) -> Mat {
  { rows, cols, p, data, }
}

///|
/// 單位矩陣
pub fn mat_identity(n : Int32, p : Int32) -> Mat {
  let data = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { if i == j { 1 % p } else { 0 } })
  })
  { rows: n, cols: n, p, data, }
}

///|
/// 模加（輸入已約化）
fn mod_add(a : Int32, b : Int32, p : Int32) -> Int32 {
  let r = a + b
  if r >= p {
    r - p
  } else {
    r
  }
}

///|
/// 模減（輸入已約化）
fn mod_sub(a : Int32, b : Int32, p : Int32) -> Int32 {
  let r = a - b
  if r < 0 {
    r + p
  } else {
    r
  }
}

///|
/// 模乘：經 Int64 中轉避免 32 位元溢出
fn mod_mul(a : Int32, b : Int32, p : Int32) -> Int32 {
  let x = a.to_int64()
  let y = b.to_int64()
  let m = p.to_int64()
  (x * y % m).to_int()
}

///|
/// 一般約化（容許負輸入）
fn mod_reduce(a : Int32, p : Int32) -> Int32 {
  let r = a % p
  if r < 0 {
    r + p
  } else {
    r
  }
}

///|
/// 快速冪（任意幺半群上的 O(log n) 冪運算——複雜度由 O(n) 降至 O(log n)）
pub fn pow_mod(base : Int32, exp : Int32, p : Int32) -> Int32 {
  let mut r = 1 % p
  let mut b = mod_reduce(base, p)
  let mut e = exp
  while e > 0 {
    if e % 2 == 1 {
      r = mod_mul(r, b, p)
    }
    b = mod_mul(b, b, p)
    e = e / 2
  }
  r
}

///|
/// 費馬小定理求逆元（p 為素數）
pub fn mod_inv(a : Int32, p : Int32) -> Int32 {
  pow_mod(a, p - 2, p)
}

///|
/// 矩陣乘法（朴素，O(n³)）
pub fn mat_mul(aa : Mat, bb : Mat) -> Mat {
  if aa.p != bb.p || aa.cols != bb.rows {
    abort("mat_mul: dimension mismatch")
  }
  let p = aa.p
  let data = Array::makei(aa.rows, fn(i) {
    Array::makei(bb.cols, fn(j) {
      let mut s = 0
      for k in 0..<aa.cols {
        s = mod_add(s, mod_mul(aa.data[i][k], bb.data[k][j], p), p)
      }
      s
    })
  })
  { rows: aa.rows, cols: bb.cols, p, data, }
}

///|
/// Strassen 矩陣乘法：O(n^log₂7) ≈ O(n^2.807)，較朴素 O(n³) 降階。
/// 要求同階方陣（非 2 冪時自動補零）。
pub fn mat_mul_strassen(aa : Mat, bb : Mat) -> Mat {
  if aa.p != bb.p ||
    aa.rows != aa.cols ||
    bb.rows != bb.cols ||
    aa.rows != bb.rows {
    abort("mat_mul_strassen: 需要同階方陣")
  }
  let n = next_pow2(aa.rows)
  let a = pad_matrix(aa, n)
  let b = pad_matrix(bb, n)
  let c = strassen_rec(a, b, aa.p)
  let data = Array::makei(aa.rows, fn(i) { c.data[i][0:aa.cols].to_owned() })
  { rows: aa.rows, cols: bb.cols, p: aa.p, data, }
}

///|
fn next_pow2(n : Int32) -> Int32 {
  let mut r = 1
  while r < n {
    r = r * 2
  }
  r
}

///|
fn pad_matrix(aa : Mat, n : Int32) -> Mat {
  let data = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) {
      if i < aa.rows && j < aa.cols {
        aa.data[i][j]
      } else {
        0
      }
    })
  })
  { rows: n, cols: n, p: aa.p, data, }
}

///|
fn mat_add(aa : Mat, bb : Mat, p : Int32) -> Mat {
  let data = Array::makei(aa.rows, fn(i) {
    Array::makei(aa.cols, fn(j) { mod_add(aa.data[i][j], bb.data[i][j], p) })
  })
  { rows: aa.rows, cols: aa.cols, p, data, }
}

///|
fn mat_sub(aa : Mat, bb : Mat, p : Int32) -> Mat {
  let data = Array::makei(aa.rows, fn(i) {
    Array::makei(aa.cols, fn(j) { mod_sub(aa.data[i][j], bb.data[i][j], p) })
  })
  { rows: aa.rows, cols: aa.cols, p, data, }
}

///|
fn strassen_rec(aa : Mat, bb : Mat, p : Int32) -> Mat {
  let n = aa.rows
  if n == 1 {
    return {
      rows: 1,
      cols: 1,
      p,
      data: [[mod_mul(aa.data[0][0], bb.data[0][0], p)]],
    }
  }
  let h = n / 2
  let a11 = slice_mat(aa, 0, 0, h)
  let a12 = slice_mat(aa, 0, h, h)
  let a21 = slice_mat(aa, h, 0, h)
  let a22 = slice_mat(aa, h, h, h)
  let b11 = slice_mat(bb, 0, 0, h)
  let b12 = slice_mat(bb, 0, h, h)
  let b21 = slice_mat(bb, h, 0, h)
  let b22 = slice_mat(bb, h, h, h)
  let m1 = strassen_rec(mat_add(a11, a22, p), mat_add(b11, b22, p), p)
  let m2 = strassen_rec(mat_add(a21, a22, p), b11, p)
  let m3 = strassen_rec(a11, mat_sub(b12, b22, p), p)
  let m4 = strassen_rec(a22, mat_sub(b21, b11, p), p)
  let m5 = strassen_rec(mat_add(a11, a12, p), b22, p)
  let m6 = strassen_rec(mat_sub(a21, a11, p), mat_add(b11, b12, p), p)
  let m7 = strassen_rec(mat_sub(a12, a22, p), mat_add(b21, b22, p), p)
  let c11 = mat_add(mat_sub(mat_add(m1, m4, p), m5, p), m7, p)
  let c12 = mat_add(m3, m5, p)
  let c21 = mat_add(m2, m4, p)
  let c22 = mat_add(mat_sub(mat_add(m1, m3, p), m2, p), m6, p)
  join_mat(c11, c12, c21, c22)
}

///|
fn slice_mat(aa : Mat, r : Int32, c : Int32, k : Int32) -> Mat {
  let data = Array::makei(k, fn(i) { aa.data[r + i][c:c + k].to_owned() })
  { rows: k, cols: k, p: aa.p, data, }
}

///|
fn join_mat(c11 : Mat, c12 : Mat, c21 : Mat, c22 : Mat) -> Mat {
  let h = c11.rows
  let n = h * 2
  let data = Array::makei(n, fn(i) {
    if i < h {
      let row = c11.data[i].copy()
      for j in 0..<h {
        row.push(c12.data[i][j])
      }
      row
    } else {
      let row = c21.data[i - h].copy()
      for j in 0..<h {
        row.push(c22.data[i - h][j])
      }
      row
    }
  })
  { rows: n, cols: n, p: c11.p, data, }
}

///|
/// 高斯消元（模 p）：秩。複雜度 O(n³)。
pub fn mat_rank(aa : Mat) -> Int32 {
  let p = aa.p
  let m = aa.data.copy()
  for i in 0..<m.length() {
    m[i] = m[i].copy()
  }
  let mut rank = 0
  let rows = aa.rows
  let cols = aa.cols
  let mut row = 0
  for col in 0..<cols {
    let mut piv = -1
    for r in row..<rows {
      if m[r][col] != 0 {
        piv = r
        break
      }
    }
    if piv == -1 {
      continue
    }
    if piv != row {
      let tmp = m[piv]
      m[piv] = m[row]
      m[row] = tmp
    }
    let inv = mod_inv(m[row][col], p)
    for r in (row + 1)..<rows {
      if m[r][col] != 0 {
        let f = mod_mul(m[r][col], inv, p)
        for c in col..<cols {
          m[r][c] = mod_sub(m[r][c], mod_mul(f, m[row][c], p), p)
        }
      }
    }
    row = row + 1
    rank = rank + 1
    if row == rows {
      break
    }
  }
  rank
}

///|
/// 行列式（模 p，高斯消元法）
pub fn mat_det(aa : Mat) -> Int32 {
  let p = aa.p
  let m = aa.data.copy()
  for i in 0..<m.length() {
    m[i] = m[i].copy()
  }
  let n = aa.rows
  let mut det = 1 % p
  let mut row = 0
  for col in 0..<n {
    let mut piv = -1
    for r in row..<n {
      if m[r][col] != 0 {
        piv = r
        break
      }
    }
    if piv == -1 {
      return 0
    }
    if piv != row {
      let tmp = m[piv]
      m[piv] = m[row]
      m[row] = tmp
      det = mod_sub(0, det, p)
    }
    det = mod_mul(det, m[row][col], p)
    let inv = mod_inv(m[row][col], p)
    for r in (row + 1)..<n {
      if m[r][col] != 0 {
        let f = mod_mul(m[r][col], inv, p)
        for c in col..<n {
          m[r][c] = mod_sub(m[r][c], mod_mul(f, m[row][c], p), p)
        }
      }
    }
    row = row + 1
  }
  mod_reduce(det, p)
}

///|
/// 逆矩陣（高斯-約旦）
pub fn mat_inv(aa : Mat) -> Mat? {
  let p = aa.p
  let n = aa.rows
  let aug = Array::makei(n, fn(i) {
    let row = aa.data[i].copy()
    for j in 0..<n {
      row.push(if i == j { 1 % p } else { 0 })
    }
    row
  })
  for col in 0..<n {
    let mut piv = -1
    for r in col..<n {
      if aug[r][col] != 0 {
        piv = r
        break
      }
    }
    if piv == -1 {
      return None
    }
    if piv != col {
      let tmp = aug[piv]
      aug[piv] = aug[col]
      aug[col] = tmp
    }
    let inv = mod_inv(aug[col][col], p)
    for j in 0..<(2 * n) {
      aug[col][j] = mod_mul(aug[col][j], inv, p)
    }
    for r in 0..<n {
      if r != col && aug[r][col] != 0 {
        let f = aug[r][col]
        for j in 0..<(2 * n) {
          aug[r][j] = mod_sub(aug[r][j], mod_mul(f, aug[col][j], p), p)
        }
      }
    }
  }
  let data = Array::makei(n, fn(i) { aug[i][n:2 * n].to_owned() })
  Some({ rows: n, cols: n, p, data, })
}

///|
/// 線性方程組求解 Ax = b（高斯消元）
pub fn mat_solve(aa : Mat, b : Array[Int32]) -> Array[Int32]? {
  let p = aa.p
  let n = aa.rows
  let aug = Array::makei(n, fn(i) {
    let row = aa.data[i].copy()
    row.push(mod_reduce(b[i], p))
    row
  })
  for col in 0..<n {
    let mut piv = -1
    for r in col..<n {
      if aug[r][col] != 0 {
        piv = r
        break
      }
    }
    if piv == -1 {
      return None
    }
    if piv != col {
      let tmp = aug[piv]
      aug[piv] = aug[col]
      aug[col] = tmp
    }
    let inv = mod_inv(aug[col][col], p)
    for j in col..<(n + 1) {
      aug[col][j] = mod_mul(aug[col][j], inv, p)
    }
    for r in 0..<n {
      if r != col && aug[r][col] != 0 {
        let f = aug[r][col]
        for j in col..<(n + 1) {
          aug[r][j] = mod_sub(aug[r][j], mod_mul(f, aug[col][j], p), p)
        }
      }
    }
  }
  Some(Array::makei(n, fn(i) { aug[i][n] }))
}

///|
/// 數論變換（NTT）：O(n log n) 多項式乘法，較朴素 O(n²) 降階。
/// p = 998244353 = 119·2²³ + 1，原根 g = 3。
pub fn ntt(
  a : Array[Int32],
  p : Int32,
  root : Int32,
  invert : Bool,
) -> Array[Int32] {
  let n = a.length()
  let r = a.copy()
  let mut j = 0
  for i in 1..<n {
    let mut bit = n >> 1
    while (j & bit) != 0 {
      j = j ^ bit
      bit = bit >> 1
    }
    j = j ^ bit
    if i < j {
      let tmp = r[i]
      r[i] = r[j]
      r[j] = tmp
    }
  }
  let mut len = 2
  while len <= n {
    let wlen = if invert { mod_inv(root, p) } else { root }
    let w = pow_mod(wlen, (p - 1) / len, p)
    let mut i = 0
    while i < n {
      let mut wcur = 1 % p
      for k in 0..<(len / 2) {
        let u = r[i + k]
        let v = mod_mul(r[i + k + len / 2], wcur, p)
        r[i + k] = mod_add(u, v, p)
        r[i + k + len / 2] = mod_sub(u, v, p)
        wcur = mod_mul(wcur, w, p)
      }
      i = i + len
    }
    len = len * 2
  }
  if invert {
    let n_inv = mod_inv(n, p)
    for i in 0..<n {
      r[i] = mod_mul(r[i], n_inv, p)
    }
  }
  r
}

///|
/// 多項式乘法（NTT，O(n log n)）
pub fn poly_mul_ntt(
  a : Array[Int32],
  b : Array[Int32],
  p : Int32,
  root : Int32,
) -> Array[Int32] {
  let need = a.length() + b.length() - 1
  let mut n = 1
  while n < need {
    n = n * 2
  }
  let fa = a.copy()
  let fb = b.copy()
  while fa.length() < n {
    fa.push(0)
  }
  while fb.length() < n {
    fb.push(0)
  }
  let na = ntt(fa, p, root, false)
  let nb = ntt(fb, p, root, false)
  let fc : Array[Int32] = []
  for i in 0..<n {
    fc.push(mod_mul(na[i], nb[i], p))
  }
  let c = ntt(fc, p, root, true)
  c[0:need].to_owned()
}

///|
/// Karatsuba 乘法：O(n^log₂3) ≈ O(n^1.585)，較朴素 O(n²) 降階。
pub fn karatsuba(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  let n = if a.length() > b.length() { a.length() } else { b.length() }
  if n <= 32 {
    let r = Array::make(a.length() + b.length() - 1, 0)
    for i in 0..<a.length() {
      for j in 0..<b.length() {
        r[i + j] = mod_add(r[i + j], mod_mul(a[i], b[j], p), p)
      }
    }
    return r
  }
  let m = n / 2
  let a_cut = if m < a.length() { m } else { a.length() }
  let b_cut = if m < b.length() { m } else { b.length() }
  let a_lo = a[0:a_cut].to_owned()
  let a_hi = a[a_cut:a.length()].to_owned()
  let b_lo = b[0:b_cut].to_owned()
  let b_hi = b[b_cut:b.length()].to_owned()
  let z0 = karatsuba(a_lo, b_lo, p)
  let z2 = karatsuba(a_hi, b_hi, p)
  let a_sum = poly_add(a_lo, a_hi, p)
  let b_sum = poly_add(b_lo, b_hi, p)
  let z1 = karatsuba(a_sum, b_sum, p)
  let z1m = poly_sub(poly_sub(z1, z0, p), z2, p)
  let len = a.length() + b.length() - 1
  let r = Array::make(len, 0)
  for i in 0..<z0.length() {
    r[i] = mod_add(r[i], z0[i], p)
  }
  for i in 0..<z1m.length() {
    r[i + m] = mod_add(r[i + m], z1m[i], p)
  }
  for i in 0..<z2.length() {
    r[i + 2 * m] = mod_add(r[i + 2 * m], z2[i], p)
  }
  r
}

///|
fn poly_add(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  let n = if a.length() > b.length() { a.length() } else { b.length() }
  let r = Array::make(n, 0)
  for i in 0..<n {
    let x = if i < a.length() { a[i] } else { 0 }
    let y = if i < b.length() { b[i] } else { 0 }
    r[i] = mod_add(x, y, p)
  }
  r
}

///|
fn poly_sub(a : Array[Int32], b : Array[Int32], p : Int32) -> Array[Int32] {
  let n = if a.length() > b.length() { a.length() } else { b.length() }
  let r = Array::make(n, 0)
  for i in 0..<n {
    let x = if i < a.length() { a[i] } else { 0 }
    let y = if i < b.length() { b[i] } else { 0 }
    r[i] = mod_sub(x, y, p)
  }
  r
}

// ---------------------------------------------------------------------------
// 快速 zeta / Möbius 變換（偏序集上的極限計算＝平坦函子的高效演算法）
// ---------------------------------------------------------------------------

///|
/// 子集和變換（zeta 變換）：g(S) = Σ_{T⊆S} f(T)，O(n·2ⁿ)
pub fn zeta_transform(f : Array[Int32], p : Int32) -> Array[Int32] {
  let n = f.length()
  let g = f.copy()
  let mut i = 1
  while i < n {
    for s in 0..<n {
      if (s & i) != 0 {
        g[s] = mod_add(g[s], g[s ^ i], p)
      }
    }
    i = i << 1
  }
  g
}

///|
/// Möbius 反演：zeta 變換的逆，O(n·2ⁿ)
pub fn mobius_transform(g : Array[Int32], p : Int32) -> Array[Int32] {
  let n = g.length()
  let f = g.copy()
  let mut i = 1
  while i < n {
    for s in 0..<n {
      if (s & i) != 0 {
        f[s] = mod_sub(f[s], f[s ^ i], p)
      }
    }
    i = i << 1
  }
  f
}

///|
/// 第 idx 個 n 元置換（Lehmer 排序，與 symmetric_group 一致）
pub fn symmetric_perm(n : Int32, idx : Int32) -> Array[Int32] {
  let perms : Array[Array[Int32]] = []
  let cur = Array::makei(n, fn(i) { i })
  let used = Array::make(n, false)
  gen_perms(n, cur, used, 0, perms)
  perms[idx]
}

///|
/// 置換的 Lehmer 編號（對應 symmetric_group 的元素索引）
pub fn symmetric_index(perm : Array[Int32]) -> Int32 {
  lehmer_rank(perm)
}

///|
/// F_p 上矩陣零空間的基（行向量解），高斯消元 O(m·n·min(m,n))
pub fn mat_nullspace(aa : Mat) -> Array[Array[Int32]] {
  let p = aa.p
  let m = aa.rows
  let n = aa.cols
  let a = Array::makei(m, fn(i) { aa.data[i].copy() })
  let pivot_cols : Array[Int32] = []
  let mut row = 0
  for col in 0..<n {
    if row >= m {
      break
    }
    let mut piv = -1
    for r in row..<m {
      if a[r][col] != 0 {
        piv = r
      }
    }
    if piv == -1 {
      continue
    }
    if piv != row {
      let tmp = a[piv]
      a[piv] = a[row]
      a[row] = tmp
    }
    let inv = mod_inv(a[row][col], p)
    for c in col..<n {
      a[row][c] = mod_mul(a[row][c], inv, p)
    }
    for r in 0..<m {
      if r != row && a[r][col] != 0 {
        let f = a[r][col]
        for c in col..<n {
          a[r][c] = mod_sub(a[r][c], mod_mul(f, a[row][c], p), p)
        }
      }
    }
    pivot_cols.push(col)
    row = row + 1
  }
  // 自由變量
  let free_cols : Array[Int32] = []
  for col in 0..<n {
    let mut is_pivot = false
    for pc in pivot_cols {
      if pc == col {
        is_pivot = true
      }
    }
    if !is_pivot {
      free_cols.push(col)
    }
  }
  // 每個自由變量對應一個基向量
  let basis : Array[Array[Int32]] = []
  for fc in free_cols {
    let v = Array::make(n, 0)
    v[fc] = 1
    for i in 0..<pivot_cols.length() {
      v[pivot_cols[i]] = mod_sub(0, a[i][fc], p)
    }
    basis.push(v)
  }
  basis
}
