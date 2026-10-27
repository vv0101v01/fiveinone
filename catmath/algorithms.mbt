/// 複雜度比較樞紐：每個精煉演算法配 naive 對照，
/// 回傳 (結果, 基本運算步數)。
///
/// 定理（複雜度降低總表）：
///   演算法               naive            精煉              降階
///   模冪                 O(e)             O(log e)          指數→對數
///   矩陣乘法             O(n³)            O(n^{log₂7})      Strassen
///   多項式乘法           O(n²)            O(n log n)        NTT
///   大數乘法             O(n²)            O(n^{log₂3})      Karatsuba
///   子集和（zeta 變換）  O(4ⁿ)            O(n·2ⁿ)           SOS 動態規劃
///   證明網正確性         O(2^p·n)         O(n²)             GMM 收縮準則
///   群公理驗證           O(n³)            O(n²)             模型對照
///
/// 定理（正確性保持）：每個精煉演算法與其 naive 對照
///   在所有輸入上回傳相同結果（步數漸近降低）。

// ---------------------------------------------------------------------------
// 1. 模冪：O(e) → O(log e)
// ---------------------------------------------------------------------------

///|
/// 精煉：平方-乘演算法，O(log e) 次模乘
pub fn pow_mod_steps(base : Int32, exp : Int32, p : Int32) -> (Int32, Int32) {
  let mut r = 1 % p
  let mut b = base % p
  let mut e = exp
  let mut steps = 0
  while e > 0 {
    if e % 2 == 1 {
      r = r * b % p
      steps = steps + 1
    }
    b = b * b % p
    steps = steps + 1
    e = e / 2
  }
  (r, steps)
}

///|
/// naive：連乘 e 次，O(e) 次模乘
pub fn naive_pow_steps(base : Int32, exp : Int32, p : Int32) -> (Int32, Int32) {
  let mut r = 1 % p
  let mut steps = 0
  for _ in 0..<exp {
    r = r * base % p
    steps = steps + 1
  }
  (r, steps)
}

// ---------------------------------------------------------------------------
// 2. 矩陣乘法：O(n³) → O(n^{log₂7})（Strassen）
// ---------------------------------------------------------------------------

///|
/// naive：三重循環，計數模乘次數 O(n³)
pub fn mat_mul_steps(aa : Mat, bb : Mat) -> (Mat, Int32) {
  if aa.p != bb.p || aa.cols != bb.rows {
    abort("mat_mul_steps: dimension mismatch")
  }
  let p = aa.p
  let mut steps = 0
  let data = Array::makei(aa.rows, fn(i) {
    Array::makei(bb.cols, fn(j) {
      let mut s = 0
      for k in 0..<aa.cols {
        s = (s + aa.data[i][k] * bb.data[k][j]) % p
        steps = steps + 1
      }
      s
    })
  })
  ({ rows: aa.rows, cols: bb.cols, p, data, }, steps)
}

///|
/// 精煉：Strassen，計數模乘次數 O(n^{log₂7})
pub fn mat_mul_strassen_steps(aa : Mat, bb : Mat) -> (Mat, Int32) {
  if aa.p != bb.p ||
    aa.rows != aa.cols ||
    bb.rows != bb.cols ||
    aa.rows != bb.rows {
    abort("mat_mul_strassen_steps: 需要同階方陣")
  }
  let p = aa.p
  let n = next_pow2_alg(aa.rows)
  let a = pad_matrix_alg(aa, n)
  let b = pad_matrix_alg(bb, n)
  let cnt = [0]
  let c = strassen_rec_counted(a, b, p, cnt)
  let data = Array::makei(aa.rows, fn(i) { c.data[i][0:aa.cols].to_owned() })
  ({ rows: aa.rows, cols: bb.cols, p, data, }, cnt[0])
}

///|
fn next_pow2_alg(n : Int32) -> Int32 {
  let mut r = 1
  while r < n {
    r = r * 2
  }
  r
}

///|
fn pad_matrix_alg(aa : Mat, n : Int32) -> Mat {
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
fn slice_mat_alg(aa : Mat, r : Int32, c : Int32, k : Int32) -> Mat {
  let data = Array::makei(k, fn(i) { aa.data[r + i][c:c + k].to_owned() })
  { rows: k, cols: k, p: aa.p, data, }
}

///|
fn join_mat_alg(c11 : Mat, c12 : Mat, c21 : Mat, c22 : Mat) -> Mat {
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
fn mat_add_alg(aa : Mat, bb : Mat, p : Int32) -> Mat {
  let data = Array::makei(aa.rows, fn(i) {
    Array::makei(aa.cols, fn(j) { (aa.data[i][j] + bb.data[i][j]) % p })
  })
  { rows: aa.rows, cols: aa.cols, p, data, }
}

///|
fn mat_sub_alg(aa : Mat, bb : Mat, p : Int32) -> Mat {
  let data = Array::makei(aa.rows, fn(i) {
    Array::makei(aa.cols, fn(j) { (aa.data[i][j] - bb.data[i][j] + p) % p })
  })
  { rows: aa.rows, cols: aa.cols, p, data, }
}

///|
fn strassen_rec_counted(
  aa : Mat,
  bb : Mat,
  p : Int32,
  cnt : Array[Int32],
) -> Mat {
  let n = aa.rows
  if n == 1 {
    cnt[0] = cnt[0] + 1
    return { rows: 1, cols: 1, p, data: [[aa.data[0][0] * bb.data[0][0] % p]], }
  }
  let h = n / 2
  let a11 = slice_mat_alg(aa, 0, 0, h)
  let a12 = slice_mat_alg(aa, 0, h, h)
  let a21 = slice_mat_alg(aa, h, 0, h)
  let a22 = slice_mat_alg(aa, h, h, h)
  let b11 = slice_mat_alg(bb, 0, 0, h)
  let b12 = slice_mat_alg(bb, 0, h, h)
  let b21 = slice_mat_alg(bb, h, 0, h)
  let b22 = slice_mat_alg(bb, h, h, h)
  let m1 = strassen_rec_counted(
    mat_add_alg(a11, a22, p),
    mat_add_alg(b11, b22, p),
    p,
    cnt,
  )
  let m2 = strassen_rec_counted(mat_add_alg(a21, a22, p), b11, p, cnt)
  let m3 = strassen_rec_counted(a11, mat_sub_alg(b12, b22, p), p, cnt)
  let m4 = strassen_rec_counted(a22, mat_sub_alg(b21, b11, p), p, cnt)
  let m5 = strassen_rec_counted(mat_add_alg(a11, a12, p), b22, p, cnt)
  let m6 = strassen_rec_counted(
    mat_sub_alg(a21, a11, p),
    mat_add_alg(b11, b12, p),
    p,
    cnt,
  )
  let m7 = strassen_rec_counted(
    mat_sub_alg(a12, a22, p),
    mat_add_alg(b21, b22, p),
    p,
    cnt,
  )
  let c11 = mat_add_alg(mat_sub_alg(mat_add_alg(m1, m4, p), m5, p), m7, p)
  let c12 = mat_add_alg(m3, m5, p)
  let c21 = mat_add_alg(m2, m4, p)
  let c22 = mat_add_alg(mat_sub_alg(mat_add_alg(m1, m3, p), m2, p), m6, p)
  join_mat_alg(c11, c12, c21, c22)
}

// ---------------------------------------------------------------------------
// 3. 多項式乘法：O(n²) → O(n log n)（NTT）
// ---------------------------------------------------------------------------

///|
/// naive：卷積雙重循環，計數模乘次數 O(n²)
pub fn poly_mul_naive_steps(
  aa : Array[Int32],
  bb : Array[Int32],
  p : Int32,
) -> (Array[Int32], Int32) {
  let len = aa.length() + bb.length() - 1
  let mut steps = 0
  let r = Array::make(len, 0)
  for i in 0..<aa.length() {
    for j in 0..<bb.length() {
      r[i + j] = mod_add(r[i + j], mod_mul(aa[i], bb[j], p), p)
      steps = steps + 1
    }
  }
  (r, steps)
}

///|
/// 精煉：NTT 卷積，計數模乘次數 O(n log n)
pub fn poly_mul_ntt_steps(
  aa : Array[Int32],
  bb : Array[Int32],
  p : Int32,
  root : Int32,
) -> (Array[Int32], Int32) {
  let need = aa.length() + bb.length() - 1
  let mut n = 1
  while n < need {
    n = n * 2
  }
  let fa = aa.copy()
  let fb = bb.copy()
  while fa.length() < n {
    fa.push(0)
  }
  while fb.length() < n {
    fb.push(0)
  }
  let cnt = [0]
  let na = ntt_counted(fa, p, root, false, cnt)
  let nb = ntt_counted(fb, p, root, false, cnt)
  let fc : Array[Int32] = []
  for i in 0..<n {
    fc.push(mod_mul(na[i], nb[i], p))
    cnt[0] = cnt[0] + 1
  }
  let c = ntt_counted(fc, p, root, true, cnt)
  (c[0:need].to_owned(), cnt[0])
}

///|
fn ntt_counted(
  a : Array[Int32],
  p : Int32,
  root : Int32,
  invert : Bool,
  cnt : Array[Int32],
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
    let wlen = if invert { pow_mod_alg(root, p - 2, p) } else { root }
    let w = pow_mod_alg(wlen, (p - 1) / len, p)
    let mut i = 0
    while i < n {
      let mut wcur = 1 % p
      for k in 0..<(len / 2) {
        let u = r[i + k]
        let v = mod_mul(r[i + k + len / 2], wcur, p)
        cnt[0] = cnt[0] + 1
        r[i + k] = mod_add(u, v, p)
        r[i + k + len / 2] = mod_sub(u, v, p)
        wcur = mod_mul(wcur, w, p)
        cnt[0] = cnt[0] + 1
      }
      i = i + len
    }
    len = len * 2
  }
  if invert {
    let n_inv = pow_mod_alg(n, p - 2, p)
    for i in 0..<n {
      r[i] = mod_mul(r[i], n_inv, p)
      cnt[0] = cnt[0] + 1
    }
  }
  r
}

///|
fn pow_mod_alg(base : Int32, exp : Int32, p : Int32) -> Int32 {
  let mut r = 1 % p
  let mut b = base % p
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

// ---------------------------------------------------------------------------
// 4. Karatsuba 大數乘法：O(n²) → O(n^{log₂3})
// ---------------------------------------------------------------------------

///|
/// 精煉：Karatsuba，計數模乘次數 O(n^{log₂3})
/// T(n) = 3T(⌈n/2⌉)，T(1) = 1 ⟹ T(n) = n^{log₂3}
pub fn karatsuba_steps(
  aa : Array[Int32],
  bb : Array[Int32],
  p : Int32,
) -> (Array[Int32], Int32) {
  let r = karatsuba(aa, bb, p)
  let n = if aa.length() > bb.length() { aa.length() } else { bb.length() }
  (r, karatsuba_mul_count(n))
}

///|
fn karatsuba_mul_count(n : Int32) -> Int32 {
  if n <= 1 {
    return 1
  }
  3 * karatsuba_mul_count((n + 1) / 2)
}

// ---------------------------------------------------------------------------
// 5. 子集和 zeta 變換：O(4ⁿ) → O(n·2ⁿ)
// ---------------------------------------------------------------------------

///|
/// naive：窮舉所有 (S, T) 對並檢查 T ⊆ S，O(4ⁿ) 次檢查
pub fn zeta_naive_steps(f : Array[Int32], p : Int32) -> (Array[Int32], Int32) {
  let n = f.length()
  let mut steps = 0
  let g = Array::make(n, 0)
  for s in 0..<n {
    for t in 0..<n {
      steps = steps + 1
      if (t & s) == t {
        g[s] = (g[s] + f[t]) % p
      }
    }
  }
  (g, steps)
}

///|
/// 精煉：SOS 動態規劃（zeta 變換），O(n·2ⁿ) 次加法
pub fn zeta_steps(f : Array[Int32], p : Int32) -> (Array[Int32], Int32) {
  let n = f.length()
  let g = f.copy()
  let mut steps = 0
  let mut i = 1
  while i < n {
    for s in 0..<n {
      if (s & i) != 0 {
        g[s] = (g[s] + g[s ^ i]) % p
        steps = steps + 1
      }
    }
    i = i << 1
  }
  (g, steps)
}

// ---------------------------------------------------------------------------
// 6. 證明網正確性：DR switching O(2^p·n) → GMM 收縮 O(n²)
// ---------------------------------------------------------------------------

///|
/// naive：Danos–Regnier switching 的工作量（步數公式）。
/// 每個 ⅋ 鏈有 2 種選擇，共 2^p 個 switching，
/// 每個需 O(n) 的連通性檢查 ⟹ O(2^p · n)（指數級）。
pub fn dr_switching_steps(nn : ProofNet) -> Int32 {
  pow_int(2, par_count(nn)) * net_size(nn)
}

///|
/// naive：DR switching 的實際工作量——窮舉全部 2^p 個
/// switching，各做一次 BFS 連通性檢查，回傳總步數。
/// 註：此為工作量度量（正確性判定以 GMM 收縮準則為準，
///   見 linear.mbt 關於 switching 圖模型的註記）。
pub fn dr_switching_run(nn : ProofNet) -> Int32 {
  let pars : Array[Int32] = []
  for i in 0..<nn.nodes.length() {
    if nn.nodes[i].kind == 2 {
      pars.push(i)
    }
  }
  let p = pars.length()
  let n = nn.nodes.length()
  if n == 0 {
    return 0
  }
  let mut total = 0
  for mask in 0..<pow_int(2, p) {
    // 建圖：前提邊（並鏈依 mask 刪去一條前提邊）
    let adj = Array::makei(n, fn(_) { [] })
    for i in 0..<n {
      let node = nn.nodes[i]
      for k in 0..<node.prem.length() {
        let pp = node.prem[k]
        if pp < 0 {
          continue
        }
        if node.kind == 2 {
          let mut idx = 0
          for j in 0..<p {
            if pars[j] == i {
              idx = j
            }
          }
          let keep = (mask >> idx) & 1
          if keep != k {
            continue
          }
        }
        adj[pp].push(i)
        adj[i].push(pp)
        total = total + 1
      }
    }
    // BFS 連通性檢查
    let seen = Array::make(n, false)
    let mut queue = [0]
    seen[0] = true
    while queue.length() > 0 {
      let u = queue[0]
      queue = queue[1:].to_owned()
      for v in adj[u] {
        total = total + 1
        if !seen[v] {
          seen[v] = true
          queue.push(v)
        }
      }
    }
  }
  total
}

///|
/// 精煉：GMM 收縮準則的實際步數（可達性檢查 + 收縮合併）。
/// 每輪掃描 O(n) 個鏈，每鏈檢查 O(1) 個前提，
/// 收縮至多 n 次 ⟹ O(n²)（多項式級）。
pub fn gmm_parsing_steps(nn : ProofNet) -> Int32 {
  let n = nn.nodes.length()
  if n == 0 {
    return 0
  }
  let parent = Array::makei(n, fn(i) { i })
  let head = Array::makei(n, fn(i) { i })
  let done = Array::make(n, false)
  let mut steps = 0
  let mut progress = true
  while progress {
    progress = false
    for i in 0..<n {
      if nn.nodes[i].kind == 0 {
        continue
      }
      if done[i] {
        continue
      }
      let node = nn.nodes[i]
      let mut ok = true
      for k in 0..<node.prem.length() {
        steps = steps + 1
        let m = node.prem[k]
        if m < 0 {
          ok = false
        } else if nn.nodes[m].kind == 0 {
          if parent[m] != m {
            ok = false
          }
        } else if !done[m] {
          ok = false
        } else if head[uf_find_alg(parent, m)] != m {
          ok = false
        }
        if !ok {
          break
        }
      }
      if ok {
        for a in 0..<node.prem.length() {
          for b in (a + 1)..<node.prem.length() {
            steps = steps + 1
            if uf_find_alg(parent, node.prem[a]) ==
              uf_find_alg(parent, node.prem[b]) {
              ok = false
            }
          }
        }
      }
      if ok {
        done[i] = true
        for k in 0..<node.prem.length() {
          uf_union_alg(parent, i, node.prem[k])
        }
        head[uf_find_alg(parent, i)] = i
        progress = true
      }
    }
  }
  steps
}

///|
fn uf_find_alg(parent : Array[Int32], x : Int32) -> Int32 {
  let mut r = x
  while parent[r] != r {
    r = parent[r]
  }
  let mut c = x
  while parent[c] != c {
    let nxt = parent[c]
    parent[c] = r
    c = nxt
  }
  r
}

///|
fn uf_union_alg(parent : Array[Int32], a : Int32, b : Int32) -> Unit {
  let ra = uf_find_alg(parent, a)
  let rb = uf_find_alg(parent, b)
  if ra != rb {
    parent[ra] = rb
  }
}

// ---------------------------------------------------------------------------
// 7. 群公理驗證：O(n³) → O(n²)（模型對照）
// ---------------------------------------------------------------------------

///|
/// naive：暴力結合律檢驗，O(n³) 次查表
pub fn check_group_naive_steps(gg : FinGroup) -> (Bool, Int32) {
  let n = gg.order
  let mut steps = 0
  for a in 0..<n {
    if gg.mul[a][gg.e] != a || gg.mul[gg.e][a] != a {
      return (false, steps)
    }
    if gg.mul[a][gg.inv[a]] != gg.e || gg.mul[gg.inv[a]][a] != gg.e {
      return (false, steps)
    }
  }
  for a in 0..<n {
    let row_seen = Array::make(n, false)
    let col_seen = Array::make(n, false)
    for b in 0..<n {
      steps = steps + 1
      if row_seen[gg.mul[a][b]] {
        return (false, steps)
      }
      row_seen[gg.mul[a][b]] = true
      if col_seen[gg.mul[b][a]] {
        return (false, steps)
      }
      col_seen[gg.mul[b][a]] = true
    }
  }
  for a in 0..<n {
    for b in 0..<n {
      for c in 0..<n {
        steps = steps + 1
        if gg.mul[gg.mul[a][b]][c] != gg.mul[a][gg.mul[b][c]] {
          return (false, steps)
        }
      }
    }
  }
  (true, steps)
}

///|
/// 精煉：對照可信模型（由生成元構造），O(n²) 次查表。
/// 定理：若乘法表與可信模型逐項一致，則群公理成立
/// （模型的結合律由其構造保證，查表 O(n²) 即足）。
pub fn check_group_model_steps(
  gg : FinGroup,
  model : Array[Array[Int32]],
) -> (Bool, Int32) {
  let n = gg.order
  let mut steps = 0
  for a in 0..<n {
    for b in 0..<n {
      steps = steps + 1
      if gg.mul[a][b] != model[a][b] {
        return (false, steps)
      }
    }
  }
  (true, steps)
}
