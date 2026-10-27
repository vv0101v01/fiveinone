///|
/// Tannaka–Krein 對偶白盒測試。
test "tannaka_regular_rep" {
  let gg = cyclic_group(3)
  let reg = regular_rep(gg, 2)
  assert_eq(reg.dim, 3)
  assert_eq(check_rep(reg), true)
  assert_eq(check_rep(trivial_rep(gg, 2)), true)
}

///|
test "tannaka_commutant_dim" {
  // End_G(k[G]) ≅ k[G]^op，维数 = |G|
  assert_eq(commutant(regular_rep(cyclic_group(3), 2)).length(), 3)
  assert_eq(commutant(regular_rep(cyclic_group(4), 3)).length(), 4)
  assert_eq(commutant(regular_rep(symmetric_group(3), 2)).length(), 6)
}

///|
test "tannaka_intertwiners" {
  // Hom_G(triv, triv) = k（1 維）
  let gg = cyclic_group(3)
  assert_eq(
    intertwiner_basis(trivial_rep(gg, 2), trivial_rep(gg, 2)).length(),
    1,
  )
  // Hom_G(triv, reg) = 1 維（常值映射方向）
  assert_eq(
    intertwiner_basis(trivial_rep(gg, 2), regular_rep(gg, 2)).length(),
    1,
  )
}

///|
test "tannaka_reconstruction" {
  // 定理：G ≅ Aut^⊗(ω)
  assert_eq(tannaka_reconstruction(cyclic_group(2), 3), true)
  assert_eq(tannaka_reconstruction(cyclic_group(3), 2), true)
  assert_eq(tannaka_reconstruction(cyclic_group(4), 3), true)
  assert_eq(tannaka_reconstruction(symmetric_group(3), 2), true)
}

///|
test "tannaka_nat_omega" {
  // Nat(ω, ω) ≅ k[G]：卷積代數結構驗證
  assert_eq(verify_nat_omega_is_kg(cyclic_group(3), 2), true)
  assert_eq(verify_nat_omega_is_kg(symmetric_group(3), 2), true)
}

///|
test "tannaka_tensor_preserving" {
  assert_eq(verify_tensor_preserving(cyclic_group(3), 2), true)
}

///|
test "tannaka_group_like" {
  assert_eq(is_group_like([1, 0, 0]), true)
  assert_eq(is_group_like([0, 1, 0]), true)
  assert_eq(is_group_like([0, 0, 0]), false)
  assert_eq(is_group_like([1, 1, 0]), false)
  assert_eq(is_group_like([2, 0, 0]), false)
}

///|
test "tannaka_aut_tensor_omega" {
  // Aut^⊗(ω) ≅ G：群樣元素恰為基元素 δ_g（標準基向量）
  let gg = cyclic_group(3)
  let gl = aut_tensor_omega(gg, 2)
  assert_eq(gl.length(), 3)
  for g in 0..<3 {
    for i in 0..<3 {
      assert_eq(gl[g][i], if i == g { 1 } else { 0 })
    }
  }
  // 對稱群 S₃：六個相異群樣元素
  let gs = aut_tensor_omega(symmetric_group(3), 2)
  assert_eq(gs.length(), 6)
}
