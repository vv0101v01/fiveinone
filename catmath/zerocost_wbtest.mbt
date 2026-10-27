// zerocost.mbt 白盒測試：零成本抽象與編譯期計算。

// 測試 1：單態化正確性——泛型與特化版本結果一致

///|
test "zerocost_monomorphization" {
  assert_eq(verify_monomorphization(), true)
  assert_eq(generic_sum([1, 2, 3]), 6)
  assert_eq(generic_sum([10L, 20L, 30L]), 60L)
}

// 測試 2：#inline 函數正確性

///|
test "zerocost_inline" {
  assert_eq(verify_inline(), true)
  assert_eq(inline_double(21), 42)
  assert_eq(inline_triple(14), 42)
  assert_eq(inline_sextuple(7), 42)
  assert_eq(zero_cost_demo(), 36)
}

// 測試 3：trait 方法直接呼叫

///|
test "zerocost_trait_dispatch" {
  assert_eq(Addable::add(20, 22), 42)
  assert_eq(Addable::zero(), 0)
  assert_eq(Addable::add(20L, 22L), 42L)
  assert_eq(Addable::zero(), 0L)
}

// 測試 4：抽象與特化效能相同（結果層級驗證）

///|
test "zerocost_equivalence" {
  let xs = Array::makei(100, fn(i) { i * i })
  assert_eq(generic_sum(xs), int_sum(xs))
  let xs64 = [1L, 4L, 9L, 16L, 25L, 36L, 49L, 64L, 81L, 100L]
  assert_eq(generic_sum(xs64), int64_sum(xs64))
}
