// homott.mbt 白盒測試：S¹ 的路徑代數與編碼-解碼定理。

// 測試 1：路徑代數基本運算（refl = 0，loop = 1，連接 = 加法）

///|
test "homott_path_algebra" {
  assert_eq(refl_s1().n, 0)
  assert_eq(loop_s1().n, 1)
  assert_eq(concat_s1(loop_s1(), loop_s1()).n, 2)
  assert_eq(concat_s1(loop_s1(), inverse_s1(loop_s1())).n, 0)
  assert_eq(inverse_s1(inverse_s1(loop_s1())).n, 1)
}

// 測試 2：路徑代數 ≅ ℤ（群公理窮舉驗證）

///|
test "homott_path_group" {
  assert_eq(verify_path_group(), true)
}

// 測試 3：transport：code(base) = ℤ，沿 loop 的 transport 為 +1

///|
test "homott_transport" {
  assert_eq(transport_code(refl_s1(), 5), 5)
  assert_eq(transport_code(loop_s1(), 5), 6)
  assert_eq(transport_code(inverse_s1(loop_s1()), 5), 4)
  assert_eq(transport_code(concat_s1(loop_s1(), loop_s1()), 0), 2)
}

// 測試 4：編碼-解碼定理：encode 與 decode 互逆

///|
test "homott_encode_decode" {
  assert_eq(encode_s1(decode_s1(7)), 7)
  assert_eq(encode_s1(decode_s1(-4)), -4)
  assert_eq(decode_s1(encode_s1(loop_s1())).n, 1)
  assert_eq(decode_s1(encode_s1(refl_s1())).n, 0)
  assert_eq(verify_encode_decode(), true)
}

// 測試 5：J 消除子的計算規則 J(refl, c) = c

///|
test "homott_j_computation" {
  for c in -2..<=2 {
    assert_eq(j_elim(refl_s1(), c), c)
  }
  assert_eq(verify_j_computation(), true)
}

// 測試 6：路徑對稱性與全等（congruence）

///|
test "homott_sym_congruence" {
  assert_eq(verify_path_sym(), true)
  assert_eq(congruence_s1(2, loop_s1()).n, 2)
  assert_eq(congruence_s1(3, inverse_s1(loop_s1())).n, -3)
}

// 測試 7：π₁(S¹, base) ≅ ℤ（單射性與同態性窮舉驗證）

///|
test "homott_pi1_circle" {
  assert_eq(loop_pow(3).n, 3)
  assert_eq(loop_pow(-2).n, -2)
  assert_eq(verify_pi1_circle(), true)
}

// 測試 8：單值性陳述（文件層級）

///|
test "homott_univalence_statement" {
  assert_eq(univalence_statement(), "univalence: (A ≃ B) ≃ (A = B)")
}
