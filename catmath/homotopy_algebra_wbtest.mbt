// homotopy_algebra.mbt 白盒測試：A∞ 同倫轉移。

///|
fn vec8(idx : Int32, val : Int32) -> Array[Int32] {
  let v = Array::make(8, 0)
  v[idx] = val
  v
}

// 測試 1：外代數乘法（反交換、平方為零）

///|
test "homotopy_algebra_mul" {
  // a·b = ab（基索引 3）
  assert_eq(a_mul(vec8(1, 1), vec8(2, 1))[3], 1)
  // b·a = −ab = 2·ab (mod 3)
  assert_eq(a_mul(vec8(2, 1), vec8(1, 1))[3], 2)
  // a·a = 0
  let aa = a_mul(vec8(1, 1), vec8(1, 1))
  assert_eq(aa[3], 0)
  assert_eq(aa[0], 0)
  // a·c = ac（基索引 5）
  assert_eq(a_mul(vec8(1, 1), vec8(4, 1))[5], 1)
  // c·a = −ac = 2·ac (mod 3)
  assert_eq(a_mul(vec8(4, 1), vec8(1, 1))[5], 2)
  // 分配律：(a+b)·c = ac + bc
  let ab_sum = Array::make(8, 0)
  ab_sum[1] = 1
  ab_sum[2] = 1
  let lhs = a_mul(ab_sum, vec8(4, 1))
  let rhs = vec_add8_test(
    a_mul(vec8(1, 1), vec8(4, 1)),
    a_mul(vec8(2, 1), vec8(4, 1)),
  )
  assert_eq(lhs, rhs)
}

///|
fn vec_add8_test(xx : Array[Int32], yy : Array[Int32]) -> Array[Int32] {
  Array::makei(8, fn(i) { (xx[i] + yy[i]) % 3 })
}

// 測試 2：微分 d(c) = ab（其餘為零）

///|
test "homotopy_algebra_diff" {
  assert_eq(a_diff(vec8(4, 1))[3], 1)
  assert_eq(a_diff(vec8(1, 1))[3], 0)
  assert_eq(a_diff(vec8(2, 1))[3], 0)
  assert_eq(a_diff(vec8(3, 1))[3], 0)
}

// 測試 3：收縮同倫 h(ab) = c（其餘為零）

///|
test "homotopy_algebra_homotopy" {
  assert_eq(a_homotopy(vec8(3, 1))[4], 1)
  assert_eq(a_homotopy(vec8(4, 1))[4], 0)
  assert_eq(a_homotopy(vec8(1, 1))[4], 0)
}

// 測試 4：dh + hd = id − π（收縮同倫窮舉驗證）

///|
test "homotopy_algebra_contracting" {
  assert_eq(h_basis(), [0, 1, 2, 5, 6, 7])
  assert_eq(verify_contracting_homotopy(), true)
}

// 測試 5：轉移後 m₂ 在同調上良定（x' = x + ab ⟹ 同類）

///|
test "homotopy_algebra_m2_welldefined" {
  assert_eq(verify_m2_welldefined(), true)
}

// 測試 6：Stasheff 五邊形（A∞ 關係，n = 4，窮舉 6⁴）

///|
test "homotopy_algebra_stasheff" {
  assert_eq(verify_stasheff_pentagon(), true)
}

// 測試 7：Massey 積 ⟨a, a, b⟩ = m₃^H(a, a, b) = −[ac] = 2·[ac] ≠ 0

///|
test "homotopy_algebra_massey" {
  let res = massey_aaa_b()
  assert_eq(res[3], 2)
  assert_eq(res[0], 0)
  assert_eq(res[1], 0)
  assert_eq(res[2], 0)
  assert_eq(res[4], 0)
  assert_eq(res[5], 0)
  assert_eq(verify_massey_nonzero(), true)
}

// 測試 8：同倫轉移複雜度 m_n = O(Catalan(n−1)·n)

///|
test "homotopy_algebra_transfer_complexity" {
  assert_eq(transfer_complexity(1), 1)
  assert_eq(transfer_complexity(2), 2)
  assert_eq(transfer_complexity(3), 6)
  assert_eq(transfer_complexity(4), 20)
  assert_eq(transfer_complexity(5), 70)
}
