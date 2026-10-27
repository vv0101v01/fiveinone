// systems.mbt 白盒測試：有限動力系統（Dyn 範疇）。

// 測試 1：基本運算與軌道

///|
test "systems_orbit" {
  // 循環系統：f = (0→1→2→3→0)
  let ds = make_dyn(4, [1, 2, 3, 0])
  assert_eq(ds_size(ds), 4)
  assert_eq(ds_apply(ds, 0), 1)
  assert_eq(orbit(ds, 0, 4), [0, 1, 2, 3, 0])
  assert_eq(ds_iterate(ds, 0, 6), 2)
}

// 測試 2：Floyd 龜兔——ρ 形系統 0→1→2→3→3

///|
test "systems_floyd" {
  let ds = make_dyn(4, [1, 2, 3, 3])
  let (mu, lambda) = floyd_cycle(ds, 0)
  assert_eq(mu, 3)
  assert_eq(lambda, 1)
  // 從環上點出發：μ = 0
  let (mu3, lambda3) = floyd_cycle(ds, 3)
  assert_eq(mu3, 0)
  assert_eq(lambda3, 1)
}

// 測試 3：環分解 O(n)——ρ 形系統

///|
test "systems_cycle_decompose" {
  let ds = make_dyn(4, [1, 2, 3, 3])
  let dec = cycle_decompose(ds)
  // 點 3：環點（尾長 0，環長 1）
  assert_eq(dec[3].1, 0)
  assert_eq(dec[3].2, 1)
  // 點 0,1,2：尾點（尾長 3,2,1）
  assert_eq(dec[0].1, 3)
  assert_eq(dec[1].1, 2)
  assert_eq(dec[2].1, 1)
  // 全部同屬一個分量
  assert_eq(dec[0].0, dec[1].0)
  assert_eq(dec[1].0, dec[2].0)
  assert_eq(dec[2].0, dec[3].0)
}

// 測試 4：環分解——雙環系統
// 0→1→0（環長 2），2→3→2（環長 2）

///|
test "systems_two_cycles" {
  let ds = make_dyn(4, [1, 0, 3, 2])
  let dec = cycle_decompose(ds)
  assert_eq(dec[0].1, 0)
  assert_eq(dec[0].2, 2)
  assert_eq(dec[2].1, 0)
  assert_eq(dec[2].2, 2)
  // 兩個不同分量
  assert_eq(dec[0].0 != dec[2].0, true)
  assert_eq(is_permutation(ds), true)
  assert_eq(periodic_points(ds), [0, 1, 2, 3])
}

// 測試 5：雙射判定

///|
test "systems_permutation" {
  assert_eq(is_permutation(make_dyn(4, [1, 2, 3, 0])), true)
  assert_eq(is_permutation(make_dyn(4, [1, 2, 3, 3])), false)
}

// 測試 6：二進制提升 O(log m) 與樸素疊代一致

///|
test "systems_jump_table" {
  let ds = make_dyn(6, [1, 2, 3, 4, 5, 0])
  let jt = make_jump(ds, 8)
  for x in 0..<6 {
    for m in 0..<40 {
      assert_eq(ds_iterate_pow(jt, x, m), ds_iterate(ds, x, m))
    }
  }
}

// 測試 7：自然變換（交換圖）檢查

///|
test "systems_morphism" {
  // f：ρ 形 0→1→2→3→3；g：ρ 形 0→1→2→2
  let ds1 = make_dyn(4, [1, 2, 3, 3])
  let ds2 = make_dyn(3, [1, 2, 2])
  // h 壓縮尾部：h∘f = g∘h ✓
  let h = [0, 1, 2, 2]
  assert_eq(is_dyn_morphism(ds1, ds2, h), true)
  // h' 使 3↦0：破壞交換圖
  let h2 = [0, 1, 2, 0]
  assert_eq(is_dyn_morphism(ds1, ds2, h2), false)
  // 恆等態射
  let id = [0, 1, 2, 3]
  assert_eq(is_dyn_morphism(ds1, ds1, id), true)
}

// 測試 8：Dyn 範疇之積

///|
test "systems_product" {
  // f = 交換 (0 1)，g = 恆等
  let ds1 = make_dyn(2, [1, 0])
  let ds2 = make_dyn(2, [0, 1])
  let pp = ds_product(ds1, ds2)
  assert_eq(ds_size(pp), 4)
  // (a,b) ↦ (f(a), g(b))
  assert_eq(ds_apply(pp, 0), 2) // (0,0) ↦ (1,0) = 1*2+0
  assert_eq(ds_apply(pp, 1), 3) // (0,1) ↦ (1,1)
  assert_eq(ds_apply(pp, 2), 0) // (1,0) ↦ (0,0)
  assert_eq(ds_apply(pp, 3), 1) // (1,1) ↦ (0,1)
}

// 測試 9：自由動力系統的萬有性質
// 註：截断自由系統 Free(k) 之萬有性質對
// 「所有軌道在 k 步內抵達不動點」的系統成立
// （無限自由系統 (ℕ, succ) 對所有系統成立）

///|
test "systems_free_universal" {
  let ds = make_dyn(3, [1, 2, 2])
  assert_eq(verify_free_dyn_universal(ds, 5), true)
  let ds2 = make_dyn(5, [1, 2, 3, 4, 4])
  assert_eq(verify_free_dyn_universal(ds2, 6), true)
}

// 測試 10：Dyn 範疇公理（態射複合封閉、恆等）

///|
test "systems_dyn_category" {
  assert_eq(verify_dyn_category(), true)
}

// 測試 11：共軛（同構）判定

///|
test "systems_conjugate" {
  // 同構重標號：ρ 形 0→1→2→3→3 與 3→2→1→0→0
  let ds1 = make_dyn(4, [1, 2, 3, 3])
  let ds2 = make_dyn(4, [3, 0, 1, 3])
  // ds2: 0↦3, 1↦0, 2↦1, 3↦3 —— 即 3→2→1→0→3？——重標號 ρ 形
  assert_eq(are_conjugate(ds1, ds2), true)
  // 不同構：環長不同
  let ds3 = make_dyn(4, [1, 0, 3, 2])
  assert_eq(are_conjugate(ds1, ds3), false)
}

// 測試 12：不動點

///|
test "systems_fixed_points" {
  let ds = make_dyn(4, [1, 2, 3, 3])
  assert_eq(fixed_points(ds), [3])
  let ds2 = make_dyn(3, [0, 1, 2])
  assert_eq(fixed_points(ds2), [0, 1, 2])
}
