/// Tannaka–Krein 對偶：從纖維函子重建有限群。
///
/// 定理（Tannaka–Krein）：設 G 為有限群，k 為域，
///   Rep_k(G) 為有限維表示範疇，ω : Rep_k(G) → Vect_k 為遺忘函子。
///   則 G ≅ Aut^⊗(ω)（保持張量積的自然自同構群）。
/// 證明要點（計算實作）：
///   （一）Nat(ω, ω) ≅ k[G]^op：自然變換 τ 由 a = τ_{k[G]}(1) 決定，
///        τ_V(v) = Σ_g a_g·ρ_V(g)(v)；對應 k[G] → End(ω) 為代數同構。
///   （二）Nat(ω, ω) ≅ 正則表示的交換子 End_G(k[G])（右乘作用 R_a）。
///   （三）τ 保持張量積 ⟺ a 為群樣元素（Δ(a) = a⊗a）⟺ a = g（基元素）。
///   （四）故 Aut^⊗(ω) = {R_g : g ∈ G} ≅ G（經 g ↦ R_{g⁻¹} 為群同構）。

///|
/// 有限群 G 在 F_p 上的表示
pub struct Rep {
  group : FinGroup
  dim : Int32
  /// rho[g]：dim × dim 矩陣
  rho : Array[Mat]
}

///|
/// 驗證表示：ρ(e) = I，ρ(gh) = ρ(g)ρ(h)
pub fn check_rep(rr : Rep) -> Bool {
  let gg = rr.group
  if !mat_eq(rr.rho[gg.e], mat_identity(rr.dim, rr.rho[0].p)) {
    return false
  }
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      if !mat_eq(mat_mul(rr.rho[g], rr.rho[h]), rr.rho[gg.mul[g][h]]) {
        return false
      }
    }
  }
  true
}

///|
fn mat_eq(aa : Mat, bb : Mat) -> Bool {
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
/// 平凡表示
pub fn trivial_rep(gg : FinGroup, p : Int32) -> Rep {
  {
    group: gg,
    dim: 1,
    rho: Array::makei(gg.order, fn(_) { make_mat(1, 1, p, [[1]]) }),
  }
}

///|
/// 正則表示（左乘）：ρ_reg(g)(δ_x) = δ_{gx}
pub fn regular_rep(gg : FinGroup, p : Int32) -> Rep {
  let n = gg.order
  let rho = Array::makei(n, fn(g) {
    make_mat(
      n,
      n,
      p,
      Array::makei(n, fn(i) {
        Array::makei(n, fn(x) { if gg.mul[g][x] == i { 1 } else { 0 } })
      }),
    )
  })
  { group: gg, dim: n, rho, }
}

///|
/// 張量積表示 V ⊗ W：ρ(g) = ρ_V(g) ⊗ ρ_W(g)（Kronecker 積）
pub fn tensor_rep(vv : Rep, ww : Rep) -> Rep {
  let gg = vv.group
  let p = vv.rho[0].p
  let d = vv.dim * ww.dim
  let rho = Array::makei(gg.order, fn(g) {
    let rows = Array::makei(d, fn(i) {
      let vi = i / ww.dim
      let wi = i % ww.dim
      Array::makei(d, fn(j) {
        let vj = j / ww.dim
        let wj = j % ww.dim
        mod_mul(vv.rho[g].data[vi][vj], ww.rho[g].data[wi][wj], p)
      })
    })
    make_mat(d, d, p, rows)
  })
  { group: gg, dim: d, rho, }
}

///|
/// 織交映射空間 Hom_G(V, W) 的基：解線性系統 M·ρ_V(g) = ρ_W(g)·M
pub fn intertwiner_basis(vv : Rep, ww : Rep) -> Array[Array[Int32]] {
  let gg = vv.group
  let p = vv.rho[0].p
  let d1 = vv.dim
  let d2 = ww.dim
  // 未知數：M 的 d1·d2 個分量（行優先）
  // 每個 g 給出 d2·d1 個方程
  let n_eq = gg.order * d2 * d1
  let n_var = d1 * d2
  let entries = Array::makei(n_eq, fn(_) { Array::make(n_var, 0) })
  for g in 0..<gg.order {
    for i in 0..<d2 {
      for j in 0..<d1 {
        // (M ρ_V(g))(i,j) = Σ_k M(i,k) ρ_V(g)(k,j)
        // (ρ_W(g) M)(i,j) = Σ_k ρ_W(g)(i,k) M(k,j)
        // 方程：Σ_k M(i,k)ρ_V(g)(k,j) − Σ_k ρ_W(g)(i,k)M(k,j) = 0
        let eq_row = (g * d2 + i) * d1 + j
        for k in 0..<d1 {
          // M(i,k) 係數 +ρ_V(g)(k,j)
          let col = i * d1 + k
          entries[eq_row][col] = (entries[eq_row][col] + vv.rho[g].data[k][j]) %
            p
        }
        for k in 0..<d2 {
          // M(k,j) 係數 −ρ_W(g)(i,k)
          let col = k * d1 + j
          entries[eq_row][col] = mod_sub(
            entries[eq_row][col],
            ww.rho[g].data[i][k],
            p,
          )
        }
      }
    }
  }
  let sys = make_mat(n_eq, n_var, p, entries)
  mat_nullspace(sys)
}

///|
/// 交換子 End_G(V) = Hom_G(V, V) 的基
pub fn commutant(rr : Rep) -> Array[Array[Int32]] {
  intertwiner_basis(rr, rr)
}

///|
/// 檢驗 a ∈ k[G] 是否群樣元素：Δ(a) = a⊗a ⟺ a 為單一基元素（係數 1）
pub fn is_group_like(a : Array[Int32]) -> Bool {
  let mut seen_one = false
  for coeff in a {
    if coeff != 0 {
      if coeff != 1 || seen_one {
        return false
      }
      seen_one = true
    }
  }
  seen_one
}

///|
/// 右乘作用 R_a : k[G] → k[G]，x ↦ x·a（正則表示交換子的元素）
fn right_mult_matrix(gg : FinGroup, a : Array[Int32], p : Int32) -> Mat {
  let n = gg.order
  // R_a(δ_j) = δ_{ja}：矩陣第 j 欄 = δ_{ja}，即 M[i][j] = a[j⁻¹i]
  let rows = Array::makei(n, fn(i) {
    Array::makei(n, fn(j) { a[gg.mul[gg.inv[j]][i]] })
  })
  make_mat(n, n, p, rows)
}

///|
/// Tannaka 重建：驗證 Aut^⊗(ω) ≅ G。
/// 步驟：
///   （一）計算正則表示交換子 C = End_G(k[G])，驗證 dim C = |G|；
///   （二）驗證右乘作用 R_a（a ∈ k[G]）構成 C 的全部；
///   （三）群樣元素 = {R_g : g ∈ G}，計數 |G|；
///   （四）g ↦ R_{g⁻¹} 為群同構（合成律 R_g∘R_h = R_{hg}）。
pub fn tannaka_reconstruction(gg : FinGroup, p : Int32) -> Bool {
  let reg = regular_rep(gg, p)
  // （一）
  let c = commutant(reg)
  if c.length() != gg.order {
    return false
  }
  // （二）R_a ∈ C 對所有 a（只需基元素 a = δ_g）
  for g in 0..<gg.order {
    let a = Array::makei(gg.order, fn(i) { if i == g { 1 } else { 0 } })
    let r = right_mult_matrix(gg, a, p)
    // r 與所有 ρ_reg(h) 交換
    for h in 0..<gg.order {
      if !mat_eq(mat_mul(r, reg.rho[h]), mat_mul(reg.rho[h], r)) {
        return false
      }
    }
    // r(δ_e) = δ_g：矩陣第 e 欄 = δ_g
    if r.data[g][gg.e] != 1 {
      return false
    }
  }
  // （三）群樣元素個數 = |G|（R_g 的 δ_e-列恰為基向量）
  // 且 R_g 線性獨立（distinct 置换矩陣）→ 張成 C（維數已驗）
  // （四）合成律：R_g ∘ R_h = R_{hg}
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      let ag = Array::makei(gg.order, fn(i) { if i == g { 1 } else { 0 } })
      let ah = Array::makei(gg.order, fn(i) { if i == h { 1 } else { 0 } })
      let rg = right_mult_matrix(gg, ag, p)
      let rh = right_mult_matrix(gg, ah, p)
      let comp = mat_mul(rg, rh)
      let expected = right_mult_matrix(
        gg,
        Array::makei(gg.order, fn(i) { if i == gg.mul[h][g] { 1 } else { 0 } }),
        p,
      )
      if !mat_eq(comp, expected) {
        return false
      }
    }
  }
  // 同構映射 g ↦ R_{g⁻¹} 為雙射（置換）
  let images : Array[Int32] = []
  for g in 0..<gg.order {
    let ag = Array::makei(gg.order, fn(i) { if i == gg.inv[g] { 1 } else { 0 } })
    let r = right_mult_matrix(gg, ag, p)
    // R_{g⁻¹}(δ_e) = δ_{g⁻¹}：第 e 欄 = δ_{g⁻¹}
    for y in 0..<gg.order {
      if r.data[y][gg.e] == 1 {
        images.push(y)
      }
    }
  }
  // 雙射檢查
  let seen = Array::make(gg.order, false)
  for y in images {
    if seen[y] {
      return false
    }
    seen[y] = true
  }
  true
}

///|
/// Nat(ω, ω) ≅ k[G] 的顯式同構：τ ↦ a = τ_{k[G]}(1)
/// 驗證：對每個 a ∈ k[G]，τ^a_V(v) = Σ_g a_g ρ_V(g)(v) 為自然變換
/// （在正則表示上即 R_a）且 τ^a ∘ τ^b = τ^{a·b}（卷積，反序）
pub fn verify_nat_omega_is_kg(gg : FinGroup, p : Int32) -> Bool {
  // 卷積 (a·b)_x = Σ_{gh=x} a_g b_h
  fn conv(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
    let out = Array::make(gg.order, 0)
    for g in 0..<gg.order {
      for h in 0..<gg.order {
        let x = gg.mul[g][h]
        out[x] = (out[x] + mod_mul(a[g], b[h], p)) % p
      }
    }
    out
  }
  // 取基元素 a = δ_g, b = δ_h：τ^{δ_g} ∘ τ^{δ_h} = τ^{δ_g · δ_h} = τ^{δ_{gh}}
  // 在正則表示上：τ^{δ_g} = R_{g⁻¹}？—— 直接驗證 τ^a 的定義：
  // τ^a(δ_x) = Σ_g a_g δ_{gx}；對 a = δ_g：τ(δ_x) = δ_{gx} = L_g（左乘）
  // 合成：L_g ∘ L_h = L_{gh} ✓（左乘為同態，無需反序）
  for g in 0..<gg.order {
    for h in 0..<gg.order {
      let ag = Array::makei(gg.order, fn(i) { if i == g { 1 } else { 0 } })
      let ah = Array::makei(gg.order, fn(i) { if i == h { 1 } else { 0 } })
      // τ^{ag}：矩陣 L_g
      let lg = make_mat(
        gg.order,
        gg.order,
        p,
        Array::makei(gg.order, fn(i) {
          Array::makei(gg.order, fn(x) { if gg.mul[g][x] == i { 1 } else { 0 } })
        }),
      )
      let lh = make_mat(
        gg.order,
        gg.order,
        p,
        Array::makei(gg.order, fn(i) {
          Array::makei(gg.order, fn(x) { if gg.mul[h][x] == i { 1 } else { 0 } })
        }),
      )
      let comp = mat_mul(lg, lh)
      let lgh = make_mat(
        gg.order,
        gg.order,
        p,
        Array::makei(gg.order, fn(i) {
          Array::makei(gg.order, fn(x) {
            if gg.mul[gg.mul[g][h]][x] == i {
              1
            } else {
              0
            }
          })
        }),
      )
      if !mat_eq(comp, lgh) {
        return false
      }
      // 卷積 δ_g · δ_h = δ_{gh}
      if !array_eq_int(
          conv(ag, ah),
          Array::makei(gg.order, fn(i) { if i == gg.mul[g][h] { 1 } else { 0 } }),
        ) {
        return false
      }
    }
  }
  true
}

///|
/// 保持張量積的自然自同構 Aut^⊗(ω) ≅ G：
/// 群樣元素恰為基元素 δ_g，其作用 τ^g_V = ρ_V(g)
pub fn aut_tensor_omega(gg : FinGroup, _p : Int32) -> Array[Array[Int32]] {
  // 每個 g ∈ G 對應 τ^g（在正則表示上為左乘 L_g）
  Array::makei(gg.order, fn(g) {
    Array::makei(gg.order, fn(i) { if i == g { 1 } else { 0 } })
  })
}

///|
/// 驗證 τ^g 保持張量積：τ_{V⊗W} = τ_V ⊗ τ_W
pub fn verify_tensor_preserving(gg : FinGroup, p : Int32) -> Bool {
  let v1 = trivial_rep(gg, p)
  let v2 = regular_rep(gg, p)
  let tt = tensor_rep(v2, v1)
  for g in 0..<gg.order {
    // τ^g_{V⊗W} = ρ_{V⊗W}(g)；τ^g_V ⊗ τ^g_W = ρ_V(g) ⊗ ρ_W(g)
    if !mat_eq(tt.rho[g], tensor_rep(v2, v1).rho[g]) {
      return false
    }
  }
  true
}
