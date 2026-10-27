///|
/// Galois 範疇白盒測試。
test "galois_coset_gset" {
  let gg = cyclic_group(4)
  let hh = [0, 2] // C_2 ≤ C_4
  let gx = coset_gset(gg, hh)
  assert_eq(gx.elements, 2)
  assert_eq(check_gset(gx), true)
  assert_eq(is_transitive(gx), true)
}

///|
test "galois_all_subgroups" {
  assert_eq(all_subgroups(cyclic_group(2)).length(), 2)
  assert_eq(all_subgroups(cyclic_group(3)).length(), 2)
  // C_2×C_2：{e}, 三個 C_2, 整群 → 5 個
  let v4 = direct_product(cyclic_group(2), cyclic_group(2))
  assert_eq(all_subgroups(v4).length(), 5)
}

///|
test "galois_transitive_gsets" {
  // C_2：子群共軛類 2 個 → 傳遞 G-集 2 個
  assert_eq(transitive_gsets(cyclic_group(2)).length(), 2)
  // S_3：{e}, C_2（共軛類）, C_3, S_3 → 4 個
  assert_eq(transitive_gsets(symmetric_group(3)).length(), 4)
}

///|
test "galois_correspondence" {
  // Aut_G(G/H) ≅ N_G(H)/H（計數）
  assert_eq(verify_galois_correspondence(cyclic_group(2)), true)
  assert_eq(verify_galois_correspondence(cyclic_group(3)), true)
  let v4 = direct_product(cyclic_group(2), cyclic_group(2))
  assert_eq(verify_galois_correspondence(v4), true)
  assert_eq(verify_galois_correspondence(symmetric_group(3)), true)
  // 明確檢查：Aut_G(G/{e}) = G（正則表現的自同構 = 右乘，|G| 個）
  let gg = symmetric_group(3)
  let reg = coset_gset(gg, [gg.e])
  assert_eq(equivariant_maps(reg, reg).length(), 6)
}

///|
test "galois_aut_fiber" {
  // Aut(F) ≅ G：自然自同構族 τ^b 的驗證
  let gg = cyclic_group(3)
  let objects = transitive_gsets(gg)
  assert_eq(objects.length(), 2)
  assert_eq(verify_aut_fiber(gg, objects), true)
  let v4 = direct_product(cyclic_group(2), cyclic_group(2))
  assert_eq(verify_aut_fiber(v4, transitive_gsets(v4)), true)
}

///|
test "galois_category_axioms" {
  assert_eq(verify_galois_category(cyclic_group(2)), true)
  assert_eq(verify_galois_category(cyclic_group(3)), true)
}

///|
test "galois_equivariant_maps" {
  // G/{e} → G/G 的等變映射恰 1 個（常值）
  let gg = cyclic_group(3)
  let reg = coset_gset(gg, [gg.e])
  let pt = coset_gset(gg, [0, 1, 2])
  assert_eq(pt.elements, 1)
  assert_eq(equivariant_maps(reg, pt).length(), 1)
  // G/G → G/{e}：0 個（正則作用無固定點）
  assert_eq(equivariant_maps(pt, reg).length(), 0)
}
