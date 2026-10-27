// derived.mbt 白盒測試：Dold–Kan 對應與 Tor。

// 測試 1：零微分鏈複形：H_n = C_n

///|
test "derived_chain_zero_diff" {
  let cc = ChainComplex::{
    p: 2,
    diff: [make_mat(1, 1, 2, [[0]]), make_mat(1, 1, 2, [[0]])],
  }
  assert_eq(check_chain_complex(cc), true)
  assert_eq(homology_dim(cc, 0), 1)
  assert_eq(homology_dim(cc, 1), 1)
}

// 測試 2：正合複形 0 → k --id--> k → 0：同調為零

///|
test "derived_chain_acyclic" {
  let cc = ChainComplex::{ p: 2, diff: [make_mat(1, 1, 2, [[1]])], }
  assert_eq(check_chain_complex(cc), true)
  assert_eq(homology_dim(cc, 0), 0)
  assert_eq(homology_dim(cc, 1), 0)
}

// 測試 3：∂∂ = 0 的非平凡複形（秩-零化度驗證）
// 複形 0 → k² --[[1,1],[0,0]]--> k² --[[1,0]]--> k → 0

///|
test "derived_chain_homology" {
  let d1 = make_mat(2, 2, 2, [[1, 1], [0, 0]])
  let d0 = make_mat(1, 2, 2, [[1, 0]])
  let cc = ChainComplex::{ p: 2, diff: [d0, d1], }
  // ∂₀∘∂₁ = d0·d1 = [[1,1]] ≠ 0 → 非鏈複形
  assert_eq(check_chain_complex(cc), false)
}

// 測試 4：模擬圓的模擬恆等式與 Dold–Kan 分裂

///|
test "derived_simplicial_circle" {
  let ss = simplicial_circle(2)
  assert_eq(ss.deg, [1, 2, 3])
  assert_eq(check_simplicial_identities(ss), true)
  assert_eq(verify_dold_kan_split(ss), true)
  // N₀ = 1，N₁ = dim ker(d₀) = 1，N₂ = dim ∩ ker(d₀)∩ker(d₁) = 0
  assert_eq(normalized_dims(ss), [1, 1, 0])
  // D₀ = 0，D₁ = rank(s₀) = 1，D₂ = rank([s₀|s₁]) = 3
  assert_eq(degenerate_dims(ss), [0, 1, 3])
}

// 測試 5：Dold–Kan 於模擬圓（多個素數）

///|
test "derived_dold_kan_circle" {
  assert_eq(verify_dold_kan_circle(2), true)
  assert_eq(verify_dold_kan_circle(3), true)
  assert_eq(verify_dold_kan_circle(5), true)
}

// 測試 6：Moore 複形同調 H₀ = H₁ = F_p；正則化 N₂ = 0 ⟹ H₂ = 0

///|
test "derived_moore_circle" {
  let cc = moore_complex(simplicial_circle(3))
  assert_eq(check_chain_complex(cc), true)
  assert_eq(homology_dim(cc, 0), 1)
  assert_eq(homology_dim(cc, 1), 1)
  let ss = simplicial_circle(3)
  assert_eq(normalized_dims(ss)[2], 0)
}

// 測試 7：Tor 無限週期性（對偶數環 R = F_p[x]/x²）
// 定理：Tor_n^R(k, k) = k 對所有 n ≥ 0（任意無限個非零同調群）

///|
test "derived_tor_dual_numbers" {
  assert_eq(verify_tor_dual_numbers(2, 8), true)
  assert_eq(verify_tor_dual_numbers(3, 6), true)
  assert_eq(verify_tor_dual_numbers(5, 4), true)
}

// 測試 8：對比——k[x] 的 Koszul 分解：Tor 集中在 0, 1 次

///|
test "derived_tor_poly" {
  assert_eq(verify_tor_poly(2), true)
  assert_eq(verify_tor_poly(7), true)
}
