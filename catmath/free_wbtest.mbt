// free.mbt 白盒測試：自由幺半群、自由群與伴隨。

// 測試 1：自由幺半群的拼接

///|
test "free_monoid_concat" {
  assert_eq(fm_concat([0, 1], [1, 0]), [0, 1, 1, 0])
  assert_eq(fm_concat([], [0]), [0])
  assert_eq(fm_concat([], []), [])
}

// 測試 2：自由幺半群的萬有性質
// 對幺半群 A = (ℤ/2, +, 0) 與 f : X → A，
// f̃(uv) = f̃(u)·f̃(v) 且 f̃(ε) = e（窮舉長度 ≤ 3 的詞）

///|
test "free_monoid_universal" {
  let aa = FinMonoid::{ order: 2, mul: [[0, 1], [1, 0]], e: 0, name: "Z2", }
  assert_eq(verify_free_monoid(2, aa, [0, 1], 3), true)
  assert_eq(verify_free_monoid(3, aa, [1, 0, 1], 2), true)
}

// 測試 3：伴隨雙射 Hom_Mon(F(X), A) ≅ Hom_Set(X, U(A))

///|
test "free_monoid_adjunction" {
  let aa = FinMonoid::{ order: 2, mul: [[0, 1], [1, 0]], e: 0, name: "Z2", }
  // |X| = 2：右側 2² = 4 個函數，各唯一決定一個同態
  assert_eq(verify_adjunction_monoid(2, aa), true)
  // |X| = 3：右側 2³ = 8 個函數
  assert_eq(verify_adjunction_monoid(3, aa), true)
}

// 測試 4：自由群的 O(n) 棧歸一

///|
test "free_group_reduce" {
  let fg = FreeGroup::{ generators: 1, }
  // x·x⁻¹ = ε（0 = x，1 = x⁻¹）
  assert_eq(fg_reduce(fg, [0, 1]), [])
  assert_eq(fg_reduce(fg, [1, 0]), [])
  assert_eq(fg_reduce(fg, [0, 1, 0]), [0])
  assert_eq(fg_reduce(fg, [0, 0]), [0, 0])
  // 交錯相消：x x⁻¹ y y⁻¹
  assert_eq(fg_reduce(fg, [0, 1, 0, 1]), [])
  // 巢狀相消：x y y⁻¹ x⁻¹ = ε
  assert_eq(fg_reduce(fg, [0, 0, 1, 1]), [])
}

// 測試 5：自由群乘法 = 拼接 + 歸一

///|
test "free_group_mul" {
  let fg = FreeGroup::{ generators: 2, }
  assert_eq(fg_mul(fg, [0], [1]), [])
  assert_eq(fg_mul(fg, [0], [0]), [0, 0])
  // (x x⁻¹)(y y⁻¹) = ε
  assert_eq(fg_mul(fg, [0, 1], [2, 3]), [])
  // (x y)(y⁻¹ x⁻¹) = ε
  assert_eq(fg_mul(fg, [0, 2], [3, 1]), [])
}

// 測試 6：自由群的萬有性質（任意 f : X → G 唯一擴展為群同態）

///|
test "free_group_universal" {
  let gg = cyclic_group(2)
  assert_eq(verify_free_group(1, gg, [1], 3), true)
  let gg3 = cyclic_group(3)
  assert_eq(verify_free_group(2, gg3, [1, 2], 2), true)
}

// 測試 7：伴隨雙射 Hom_Grp(F(X), G) ≅ Hom_Set(X, U(G))

///|
test "free_group_adjunction" {
  let gg = cyclic_group(2)
  assert_eq(verify_adjunction_group(1, gg), true)
  let s3 = symmetric_group(3)
  assert_eq(verify_adjunction_group(2, s3), true)
}
