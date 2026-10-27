// operad.mbt 白盒測試：對稱 operad、自同態 operad、結合多面體。

// 測試 1：結合 operad 合成 γ(σ; τ₁, τ₂) = B(σ)∘(τ₁⊕τ₂)

///|
test "operad_assoc_compose_swap" {
  // σ = 交換 [1,0]，τ₁ = τ₂ = 單位：γ = B(σ) = 交換
  assert_eq(assoc_compose([1, 0], [[0], [0]], [1, 1]), [1, 0])
  assert_eq(assoc_compose([0, 1], [[0], [0]], [1, 1]), [0, 1])
}

// 測試 2：結合 operad 公理（單位律、結合律、等變性窮舉）

///|
test "operad_assoc_axioms" {
  assert_eq(verify_assoc_operad(), true)
}

// 測試 3：End_X 計數公式 End_X(n) = |X|^{|X|^n}

///|
test "operad_end_count" {
  assert_eq(end_count(2, 1), 4)
  assert_eq(end_count(2, 2), 16)
  assert_eq(end_count(3, 1), 27)
  assert_eq(end_count(2, 3), 256)
}

// 測試 4：End_X 是 operad（單位律 + 結合律窮舉，|X| = 2）

///|
test "operad_end_axioms" {
  assert_eq(verify_end_operad(2), true)
}

// 測試 5：Catalan 數

///|
test "operad_catalan" {
  assert_eq(catalan(0), 1)
  assert_eq(catalan(1), 1)
  assert_eq(catalan(2), 2)
  assert_eq(catalan(3), 5)
  assert_eq(catalan(4), 14)
  assert_eq(catalan(5), 42)
  assert_eq(catalan(6), 132)
}

// 測試 6：Stasheff 結合多面體的面枚舉
// K₄（五邊形）：面數 (1, 5, 5)；K₅（六邊形）：(1, 9, 21, 14)

///|
test "operad_associahedron" {
  assert_eq(associahedron_faces(5), [1, 5, 5])
  assert_eq(associahedron_faces(6), [1, 9, 21, 14])
  assert_eq(verify_associahedron(), true)
}

// 測試 7：自由 operad F(n) = Catalan(n−1)（二元樹計數）

///|
test "operad_free_operad" {
  assert_eq(free_operad_count(1), 1)
  assert_eq(free_operad_count(2), 1)
  assert_eq(free_operad_count(3), 2)
  assert_eq(free_operad_count(4), 5)
  assert_eq(free_operad_count(5), 14)
  assert_eq(verify_free_operad(), true)
}
