///|
/// 群上同調白盒測試。
test "cohomology_cyclic_p_divides" {
  // H^n(C_2, F_2) = F_2（n ≥ 1，Tate 週期性）
  let c2 = cyclic_group(2)
  assert_eq(cohomology_dim(c2, 2, 0), 1)
  assert_eq(cohomology_dim(c2, 2, 1), 1)
  assert_eq(cohomology_dim(c2, 2, 2), 1)
  assert_eq(cohomology_dim(c2, 2, 3), 1)
  assert_eq(verify_cyclic_periodicity(2, 2, 3), true)
}

///|
test "cohomology_cyclic_p_coprime" {
  // H^n(C_2, F_3) = 0（n ≥ 1）：|G| 與 p 互素
  assert_eq(cyclic_cohomology_dim(2, 3, 1), 0)
  assert_eq(cyclic_cohomology_dim(2, 3, 2), 0)
  assert_eq(verify_cyclic_periodicity(2, 3, 2), true)
  // H^n(C_3, F_2) = 0
  assert_eq(verify_cyclic_periodicity(3, 2, 3), true)
  // H^n(C_3, F_3) = F_3
  assert_eq(verify_cyclic_periodicity(3, 3, 3), true)
  // H^n(C_4, F_2) = F_2
  assert_eq(verify_cyclic_periodicity(4, 2, 3), true)
}

///|
test "cohomology_h1_is_hom" {
  // H¹(G, F_p) ≅ Hom(G_ab, F_p)（平凡作用）
  assert_eq(verify_h1_is_hom(cyclic_group(2), 2), true)
  assert_eq(verify_h1_is_hom(cyclic_group(3), 3), true)
  assert_eq(verify_h1_is_hom(cyclic_group(4), 2), true)
  assert_eq(verify_h1_is_hom(symmetric_group(3), 2), true)
  // H¹(C_2×C_2, F_2) = Hom(C_2², F_2) = F_2²，维数 2
  let v4 = direct_product(cyclic_group(2), cyclic_group(2))
  assert_eq(cohomology_dim(v4, 2, 1), 2)
  assert_eq(hom_dim_from_ab(v4, 2), 2)
  assert_eq(verify_h1_is_hom(v4, 2), true)
}

///|
test "cohomology_h2_classifies_extensions" {
  // H²(C_2, F_2) = F_2：分類中心擴張 C_4 與 C_2×C_2
  assert_eq(cohomology_dim(cyclic_group(2), 2, 2), 1)
  // H²(C_3, F_3) = F_3
  assert_eq(cohomology_dim(cyclic_group(3), 3, 2), 1)
}

///|
test "cohomology_s3_f2" {
  // H^1(S_3, F_2) = Hom(S_3^{ab}, F_2) = Hom(C_2, F_2) = F_2
  let s3 = symmetric_group(3)
  assert_eq(cohomology_dim(s3, 2, 1), 1)
  assert_eq(verify_h1_is_hom(s3, 2), true)
}
