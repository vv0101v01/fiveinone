// topology.mbt 白盒測試：有限拓撲空間（Alexandrov 預序）。

// 測試 1：Sierpiński 空間（0 ≤ 1）

///|
test "topology_sierpinski" {
  let tt = make_top(2, [[false, true], [false, false]])
  assert_eq(tt.n, 2)
  assert_eq(check_preorder(tt), true)
  // 專化預序：0 ≤ 1
  assert_eq(tt.le[0][1], true)
  assert_eq(tt.le[1][0], false)
  // 開集（上集）：∅, {1}, {0,1}
  assert_eq(is_open(tt, [false, false]), true)
  assert_eq(is_open(tt, [false, true]), true)
  assert_eq(is_open(tt, [true, true]), true)
  assert_eq(is_open(tt, [true, false]), false)
  // 閉集（下集）：{0} 是閉集
  assert_eq(is_closed(tt, [true, false]), true)
  assert_eq(is_closed(tt, [false, true]), false)
}

// 測試 2：閉包與內部

///|
test "topology_closure_interior" {
  let tt = make_top(2, [[false, true], [false, false]])
  // cl({1}) = {x : x ≤ 1} = {0, 1}
  assert_eq(closure(tt, [false, true]), [true, true])
  // cl({0}) = {0}
  assert_eq(closure(tt, [true, false]), [true, false])
  // int({0}) = ∅（最大含於 {0} 的開集）
  assert_eq(interior(tt, [true, false]), [false, false])
  // int({0,1}) = {0,1}
  assert_eq(interior(tt, [true, true]), [true, true])
}

// 測試 3：開集枚舉（Sierpiński：3 個開集）

///|
test "topology_open_sets" {
  let tt = make_top(2, [[false, true], [false, false]])
  assert_eq(open_sets(tt).length(), 3)
}

// 測試 4：連續 ⟺ 單調

///|
test "topology_continuity" {
  let tt = make_top(2, [[false, true], [false, false]])
  // 恆等映射連續
  assert_eq(is_continuous(tt, tt, [0, 1]), true)
  // 交換映射不單調（0 ≤ 1 但 f(0)=1 ≰ f(1)=0）
  assert_eq(is_continuous(tt, tt, [1, 0]), false)
  // 常值映射連續
  assert_eq(is_continuous(tt, tt, [0, 0]), true)
}

// 測試 5：同胚 ⟺ 預序同構

///|
test "topology_homeomorphism" {
  let tt = make_top(2, [[false, true], [false, false]])
  let uu = make_top(2, [[false, true], [false, false]])
  assert_eq(is_homeomorphism(tt, uu, [0, 1]), true)
  assert_eq(is_homeomorphism(tt, uu, [1, 0]), false)
  // Sierpiński 與離散二點空間不同胚
  let disc = make_top(2, [[false, false], [false, false]])
  assert_eq(are_homeomorphic(tt, disc), false)
  assert_eq(are_homeomorphic(tt, uu), true)
}

// 測試 6：T0 與 T0 化

///|
test "topology_t0" {
  let tt = make_top(2, [[false, true], [false, false]])
  assert_eq(is_t0(tt), true)
  // 不可區別二點空間（le 全真）
  let indiscrete = make_top(2, [[false, true], [true, false]])
  assert_eq(is_t0(indiscrete), false)
  // T0 化：商掉不可區別點 → 1 點空間
  let q = t0_quotient(indiscrete)
  assert_eq(q.n, 1)
  assert_eq(is_t0(q), true)
}

// 測試 7：連通分支（union-find 代表元為分支中最大索引）

///|
test "topology_connected_components" {
  // Sierpiński 空間連通（預序弱連通）：单一分支
  let tt = make_top(2, [[false, true], [false, false]])
  assert_eq(connected_components(tt), [1, 1])
  // 離散二點空間：兩個分支
  let disc = make_top(2, [[false, false], [false, false]])
  assert_eq(connected_components(disc), [0, 1])
  // 三點鏈 0 ≤ 1 ≤ 2：連通
  let chain = make_top(3, [
    [false, true, true],
    [false, false, true],
    [false, false, false],
  ])
  assert_eq(connected_components(chain), [2, 2, 2])
}

// 測試 8：離散空間的開集 = 冪集

///|
test "topology_discrete" {
  let disc = make_top(3, [
    [false, false, false],
    [false, false, false],
    [false, false, false],
  ])
  // 離散拓撲：2³ = 8 個開集
  assert_eq(open_sets(disc).length(), 8)
}
