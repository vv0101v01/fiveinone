/// A∞-代數與同倫轉移的符號計算。
///
/// 定理（同倫轉移）：若 A 是 DGA，h 是其收縮同倫，
///   則同調 H(A) 繼承 A∞-結構：
///   m₁ = 0，m₂ = 誘導乘積，
///   m₃(x, y, z) = [h(xy)z − x·h(yz)]，
///   m_n（n ≥ 4）由平面樹求和给出。
/// 定理（Stasheff，n = 4 五邊形）：
///   m₃(m₂(x,y),z,w) − m₃(x,m₂(y,z),w) + m₃(x,y,m₂(z,w))
///   − m₂(m₃(x,y,z),w) − m₂(x,m₃(y,z,w)) = 0。
/// 例（Massey 積）：A = Λ(a, b, c)（F₃ 上外代數），
///   d(c) = ab，h(ab) = c；則 H(A) = ⟨1, a, b, ac, bc, abc⟩，
///   m₃^H(a, a, b) = −[ac] ≠ 0，即 Massey 積 ⟨a, a, b⟩ ≠ 0。

///|
/// A = Λ(a, b, c) 的基（位元遮罩編碼）：
///   0:1, 1:a, 2:b, 3:ab, 4:c, 5:ac, 6:bc, 7:abc
pub fn a_basis_len() -> Int32 {
  8
}

///|
/// 外代數乘法（F₃ 上）
pub fn a_mul(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  let p = 3
  let n = a_basis_len()
  let out = Array::make(n, 0)
  for i in 0..<n {
    if xx[i] == 0 {
      continue
    }
    for j in 0..<n {
      if yy[j] == 0 {
        continue
      }
      // 位元遮罩乘法：有重複生成元則為 0
      if (i & j) != 0 {
        continue
      }
      let m = i | j
      // 符號 = 逆序數（i 的生成元在 j 的生成元之後的個數）
      let mut inv = 0
      for gi in 0..<3 {
        if ((i >> gi) & 1) == 0 {
          continue
        }
        for gj in 0..<3 {
          if ((j >> gj) & 1) != 0 && gi > gj {
            inv = inv + 1
          }
        }
      }
      let sign = if inv % 2 == 0 { 1 } else { 2 } // −1 ≡ 2 (mod 3)
      let coeff = xx[i] * yy[j] * sign % p
      out[m] = (out[m] + coeff) % p
    }
  }
  out
}

///|
/// 微分 d：d(c) = ab（其餘基元為 0）
pub fn a_diff(xx : Array[Int32]) -> Array[Int32] {
  // d(x) = x[c]·ab（c = 基索引 4，ab = 基索引 3）
  make_vec8(3, xx[4])
}

///|
fn make_vec8(idx : Int32, val : Int32) -> Array[Int32] {
  let v = Array::make(a_basis_len(), 0)
  v[idx] = val % 3
  v
}

///|
/// 同倫 h：h(ab) = c，其餘為 0
pub fn a_homotopy(xx : Array[Int32]) -> Array[Int32] {
  make_vec8(4, xx[3])
}

///|
/// 投影 π : A → H（去掉 c 與 ab 分量）
/// H 的基：1, a, b, ac, bc, abc（A 基索引 0, 1, 2, 5, 6, 7）
pub fn h_basis() -> Array[Int32] {
  [0, 1, 2, 5, 6, 7]
}

///|
/// 投影到 H（8 維向量 → 只保留 H 基分量）
pub fn project_h(xx : Array[Int32]) -> Array[Int32] {
  // 回傳 6 維向量（H 基座標）
  let bb = h_basis()
  Array::makei(6, fn(i) { xx[bb[i]] })
}

///|
/// 驗證 h 是收縮同倫：dh + hd = id − π（在 A 上）
pub fn verify_contracting_homotopy() -> Bool {
  for i in 0..<a_basis_len() {
    let ei = make_vec8(i, 1)
    let lhs = a_diff(a_homotopy(ei))
    let rhs = a_homotopy(a_diff(ei))
    let sum = vec_add8(lhs, rhs)
    // id − π：π 保留 H 分量
    for k in 0..<a_basis_len() {
      let is_h = k == 0 || k == 1 || k == 2 || k == 5 || k == 6 || k == 7
      let expect = if is_h { 0 } else { ei[k] }
      if sum[k] != expect {
        return false
      }
    }
  }
  true
}

///|
fn vec_add8(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  Array::makei(a_basis_len(), fn(i) { (xx[i] + yy[i]) % 3 })
}

///|
fn vec_sub6(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  Array::makei(6, fn(i) { (xx[i] - yy[i] + 3) % 3 })
}

///|
/// 轉移後的 m₂ : H ⊗ H → H
pub fn m2_h(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  project_h(a_mul(xx, yy))
}

///|
/// 轉移後的 m₃ : H^{⊗3} → H
/// m₃(x, y, z) = [h(xy)z − x·h(yz)]
pub fn m3_h(
  xx : Array[Int32],
  yy : Array[Int32],
  zz : Array[Int32],
) -> Array[Int32] {
  let t1 = a_mul(a_homotopy(a_mul(xx, yy)), zz)
  let t2 = a_mul(xx, a_homotopy(a_mul(yy, zz)))
  project_h(vec_sub8(t1, t2))
}

///|
fn vec_sub8(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  Array::makei(a_basis_len(), fn(i) { (xx[i] - yy[i] + 3) % 3 })
}

///|
/// H 的元素（6 維座標）↔ A 的元素（8 維）
pub fn h_to_a(xx : Array[Int32]) -> Array[Int32] {
  let bb = h_basis()
  let out = Array::make(a_basis_len(), 0)
  for i in 0..<6 {
    out[bb[i]] = xx[i]
  }
  out
}

///|
/// 驗證 m₂ 在同調上良定：
///   x' = x + ab（同調等價）⟹ m₂(x', y) = m₂(x, y)
pub fn verify_m2_welldefined() -> Bool {
  for i in 0..<6 {
    for j in 0..<6 {
      let x = h_to_a(unit_h(i))
      let y = h_to_a(unit_h(j))
      let xp = vec_add8(x, make_vec8(3, 1)) // x + ab（ab = 基索引 3）
      if !vec_eq6(m2_h(xp, y), m2_h(x, y)) {
        return false
      }
    }
  }
  true
}

///|
fn unit_h(i : Int32) -> Array[Int32] {
  let v = Array::make(6, 0)
  v[i] = 1
  v
}

///|
fn vec_eq6(xx : Array[Int32], yy : Array[Int32]) -> Bool {
  for i in 0..<6 {
    if xx[i] != yy[i] {
      return false
    }
  }
  true
}

///|
/// 驗證 Stasheff 五邊形（n = 4）：
///   m₃(m₂(x,y),z,w) − m₃(x,m₂(y,z),w) + m₃(x,y,m₂(z,w))
///   − m₂(m₃(x,y,z),w) − m₂(x,m₃(y,z,w)) = 0
/// （轉移結構中 m₁ = m₄ = 0）
pub fn verify_stasheff_pentagon() -> Bool {
  for i in 0..<6 {
    for j in 0..<6 {
      for k in 0..<6 {
        for l in 0..<6 {
          let x = h_to_a(unit_h(i))
          let y = h_to_a(unit_h(j))
          let z = h_to_a(unit_h(k))
          let w = h_to_a(unit_h(l))
          // m₂, m₃ 在 H 座標（6 維）與 A 向量（8 維）間轉換
          let t1 = m3_h(h_to_a(m2_h(x, y)), z, w)
          let t2 = m3_h(x, h_to_a(m2_h(y, z)), w)
          let t3 = m3_h(x, y, h_to_a(m2_h(z, w)))
          let t4 = m2_h(h_to_a(m3_h(x, y, z)), w)
          let t5 = m2_h(x, h_to_a(m3_h(y, z, w)))
          let mut acc = t1
          acc = vec_sub6(acc, t2)
          acc = vec_add6(acc, t3)
          acc = vec_sub6(acc, t4)
          acc = vec_sub6(acc, t5)
          for q in 0..<6 {
            if acc[q] != 0 {
              return false
            }
          }
        }
      }
    }
  }
  true
}

///|
fn vec_add6(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  Array::makei(6, fn(i) { (xx[i] + yy[i]) % 3 })
}

///|
/// Massey 積 ⟨a, a, b⟩ = m₃^H(a, a, b) = −[ac] ≠ 0
pub fn massey_aaa_b() -> Array[Int32] {
  // a = H 基索引 1，b = H 基索引 2
  let a = h_to_a(unit_h(1))
  let b = h_to_a(unit_h(2))
  m3_h(a, a, b)
}

///|
/// 驗證 Massey 積非零（等於 2·[ac]）
pub fn verify_massey_nonzero() -> Bool {
  let res = massey_aaa_b()
  // [ac] 是 H 基索引 3（h_basis = [0,1,2,5,6,7]，ac 為 A 基索引 5）
  res[3] != 0
}

///|
/// 複雜度：轉移 m₃ 的樹求和
///   對 n 元操作，平面樹數 = Catalan(n−1)，
///   每棵樹的計算 O(n) 次乘法 ⟹ m_n 轉移複雜度 O(C_{n−1}·n)。
/// 對比：直接在 A 上計算 n 重乘積的 naive 複雜度 O(n·dim(A)^n)。
pub fn transfer_complexity(n : Int32) -> Int32 {
  if n <= 1 {
    return 1
  }
  catalan(n - 1) * n
}
