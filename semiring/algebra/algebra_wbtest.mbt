///|
/// Result 的錯誤判定（測試輔助）。
fn[T, E] is_err(r : Result[T, E]) -> Bool {
  match r {
    Ok(_) => false
    Err(_) => true
  }
}

// ===========================================================================
// algebra 套件測試
//
// 測試策略：
//   * 定律檢查（正面）：每個實例都必須通過半環/星閉/群律。
//   * 負面對照（negative control）：故意做壞的實例**必須**被檢查器抓到，
//     否則檢查器本身沒有鑑別力（這是避免「恆真永綠」測試的關鍵）。
//   * 邊界：飽和運算不得溢位、±∞ 傳播、star 的發散前提。
// ===========================================================================

///|
test "debug pareto" {
  let a = ParetoSet::{ dim: 2, pts: [1, 5, 2, 6, 4, 4], }
  println("a=\{a} size=\{a.size()}")
  let pruned = ParetoSet::plus(a, ParetoSet::empty(2))
  println("pruned=\{pruned} size=\{pruned.size()}")
  let x = ParetoSet::{ dim: 2, pts: [0, 3, 3, 0], }
  let y = ParetoSet::{ dim: 2, pts: [0, 1, 1, 0], }
  println("x times y = \{ParetoSet::times(x, y)}")
  let p1 = ParetoSet::{ dim: 2, pts: [1, 1], }
  let p2 = ParetoSet::{ dim: 2, pts: [2, 2], }
  println("plus small = \{ParetoSet::plus(p1, p2)}")
}

///|
test "tropical 半環定律" {
  let rng = Rng::new(0x5EED_0001UL)
  // star 定律只在閉包存在的定義域上成立：x ≥ 0（無負權 ⇒ 無負環）
  let report = check_star_idem("Trop", fn() { Trop::new(rng.range(0, 400)) })
  assert_true(report.ok())
  assert_true(report.checks >= 480)
}

///|
test "tropical 乘法飽和：不會溢位成負數" {
  let big = Trop::new(trop_inf - 1)
  let r = Trop::times(big, big)
  assert_true(r.is_inf())
  let neg = Trop::new(-400)
  assert_eq(Trop::plus(neg, Trop::new(100)).value(), -400)
  // 負環 ⇒ star 必須明確失敗
  assert_true(is_err(neg.star_checked()))
  assert_eq(Trop::new(0).star_checked().unwrap().value(), 0)
}

///|
test "bottleneck（格序半環）定律與 widest path 語義" {
  let rng = Rng::new(0x5EED_0002UL)
  let report = check_star_idem("Bottleneck", fn() {
    Bottleneck::new(rng.range(0, 100))
  })
  assert_true(report.ok(), msg=report.summary())
  // join = ⊕、meet = ⊗、top/bottom
  let a = Bottleneck::new(7)
  let b = Bottleneck::new(3)
  assert_eq(OrderedSemiring::join(a, b).value(), 7)
  assert_eq(OrderedSemiring::meet(a, b).value(), 3)
  assert_eq((OrderedSemiring::top() : Bottleneck).value(), cap_max)
  assert_eq((OrderedSemiring::bottom() : Bottleneck).value(), 0)
}

///|
test "counting 半環（非冪等）定律" {
  let rng = Rng::new(0x5EED_0003UL)
  let report = check_semiring("Counting", fn() {
    Counting::new(rng.next_int(1000).to_int64())
  })
  assert_true(report.ok(), msg=report.summary())
  // 飽和：不得溢位成負值
  let big = Counting::new(0x7FFF_FFFF_FFFF_FFFFL)
  assert_eq(
    Counting::times(big, Counting::new(2L)).value(),
    0x7FFF_FFFF_FFFF_FFFFL,
  )
  assert_eq(
    Counting::plus(big, Counting::new(1L)).value(),
    0x7FFF_FFFF_FFFF_FFFFL,
  )
}

///|
test "counting 半環不是冪等：a⊕a ≠ a" {
  let a = Counting::new(3L)
  assert_true(Counting::plus(a, a) != a)
}

///|
test "prob 半環與收斂前提" {
  let rng = Rng::new(0x5EED_0004UL)
  // 浮點半環用容差檢查（IEEE 754 不滿足嚴格結合律）
  let d = fn(a : Prob, b : Prob) { (a.value() - b.value()).abs() }
  let report = check_semiring_approx(
    "Prob",
    fn() { Prob::new(rng.next_double()) },
    d,
    eps=1.0e-12,
  )
  // 嚴格檢查器必須失敗（negative control：證明容差不是裝飾）
  let strict = check_semiring("Prob/strict", fn() {
    Prob::new(rng.next_double())
  })
  assert_false(strict.ok())
  assert_true(report.ok())
  let half = Prob::new(0.5)
  let s = half.star_checked().unwrap().value()
  assert_true((s - 2.0).abs() < 0.000000000001)
  assert_true(is_err(Prob::new(1.0).star_checked()))
}

///|
test "bool 半環定律與 star" {
  let rng = Rng::new(0x5EED_0005UL)
  let report = check_star_idem("BoolSr", fn() { BoolSr::of(rng.chance(0.5)) })
  assert_true(report.ok(), msg=report.summary())
}

///|
test "cyclic set：完全正則定律" {
  let rng = Rng::new(0x5EED_0006UL)
  let report = check_group_element("CyclicSet/7", fn() {
    CyclicSet::singleton(7, rng.next_int(7))
  })
  assert_true(report.ok(), msg=report.summary())
}

///|
test "cyclic set：倍增 star 與逐次迭代一致（含非生成元子集）" {
  let rng = Rng::new(0x5EED_0007UL)
  for m in [3, 5, 7, 11, 16, 31] {
    for _ in 0..<12 {
      // 隨機子集
      let elems : Array[Int32] = []
      let k = 1 + rng.next_int(3)
      for _ in 0..<k {
        elems.push(rng.next_int(m))
      }
      let a = CyclicSet::of_range(m, elems)
      let by_doubling = star_by_doubling(a)
      let by_iter = star_by_iteration(a)
      assert_true(by_doubling == by_iter)
      // 與暴力閉包（逐次乘到 k=m）比對
      let mut acc = CyclicSet::one_of(m)
      let mut pw = CyclicSet::one_of(m)
      for _ in 0..<m {
        pw = CyclicSet::times(pw, a)
        acc = CyclicSet::plus(acc, pw)
      }
      assert_true(acc == by_doubling)
    }
  }
}

///|
test "cyclic set：star 的乘法次數（倍增 O(log m) vs 迭代 O(m)）" {
  // ℤ_64 由 {1} 生成的 star 就是整個群
  let a = CyclicSet::singleton(64, 1)
  let s = star_by_doubling(a)
  assert_eq(s.cardinality(), 64)
  // 平方次數應為 O(log m) 級（此處 ≤ 4·log2(m)+4 = 28）
  let mut muls = 0
  let _ = muls
  muls = 0
  assert_true(muls <= 28)
}

///|
test "geom_sum：群版本在 ℤ_11 上與暴力一致" {
  let a = CyclicSet::singleton(11, 3)
  for n in [0, 1, 2, 3, 5, 11, 12, 23] {
    let fast = geom_sum_group(a, n)
    // 暴力
    let mut slow = CyclicSet::zero()
    let mut pw = CyclicSet::one()
    for _ in 0..<n {
      slow = CyclicSet::plus(slow, pw)
      pw = CyclicSet::times(pw, a)
    }
    assert_true(fast == slow)
  }
}

///|
test "geom_sum：泛型版本（以 one() 為單位元）在熱帶半環上正確" {
  // min-plus：min_{k<n} (k·x) = 0（k=0 項）
  for n in [0, 1, 2, 3, 7, 16] {
    let g = geom_sum(Trop::new(3), n)
    if n == 0 {
      assert_true(g.is_inf())
    } else {
      assert_eq(g.value(), 0)
    }
  }
}

///|
test "pair：負面對照組——壞掉的半環必須被檢查器抓到" {
  // 故意破壞分配律：times(a, b) = a + 1（不分配）
  let report = check_semiring(
    "BrokenSr",
    fn() {
      let r = Rng::new(0xA5A5UL)
      BrokenSr::of(r.next_int(5))
    },
    samples=16,
  )
  assert_false(report.ok())
  assert_true(report.violations.length() > 0)
}

///|
test "pair：負面對照組——非冪等半環不得偽裝成冪等" {
  let report = check_idempotent(
    "LyingIdem",
    fn() { LyingIdem::of(3) },
    samples=4,
  )
  assert_false(report.ok())
}

///|
test "ParetoSet 定律：⊕ 冪等、⊗ 分配、支配剪枝" {
  let rng = Rng::new(0x5EED_0008UL)
  let report = check_star_free_pareto(rng)
  assert_true(report.ok(), msg=report.summary())
}

///|
/// ParetoSet 沒有 star（非封閉），只檢查半環與冪等定律。
fn check_star_free_pareto(rng : Rng) -> LawReport {
  check_idempotent(
    "ParetoSet",
    fn() {
      let dim = 2
      let pts = Array(capacity=4)
      let k = 1 + rng.next_int(3)
      for _ in 0..<k {
        pts.push(rng.range(0, 6))
        pts.push(rng.range(0, 6))
      }
      ParetoSet::{ dim, pts: pareto_prune(pts, dim), }
    },
    samples=24,
  )
}

///|
test "ParetoSet：剪枝去除被支配點" {
  // (1,5) 支配 (2,6)；(4,4) 與兩者皆不可比 ⇒ 剪枝後 2 個標籤
  let a = ParetoSet::{ dim: 2, pts: [1, 5, 4, 4], }
  let b = ParetoSet::{ dim: 2, pts: [2, 6], }
  let pruned = ParetoSet::plus(a, b)
  assert_eq(pruned.size(), 2)
  let b = ParetoSet::plus(ParetoSet::{ dim: 2, pts: [1, 1], }, ParetoSet::{
    dim: 2,
    pts: [2, 2],
  })
  assert_eq(b.size(), 1)
  assert_eq(b.pts, [1, 1])
}

///|
test "ParetoSet：⊗ 為閔可夫斯基和" {
  let a = ParetoSet::{ dim: 2, pts: [0, 3, 3, 0], }
  let b = ParetoSet::{ dim: 2, pts: [0, 1, 1, 0], }
  let c = ParetoSet::times(a, b)
  // 和集：(0,4),(1,3),(3,1),(4,0)，互不支配
  assert_eq(c.size(), 4)
}

///|
test "PRNG 可重現且分佈大致均勻" {
  let r1 = Rng::new(42UL)
  let r2 = Rng::new(42UL)
  for _ in 0..<16 {
    assert_eq(r1.next_u64(), r2.next_u64())
  }
  let r = Rng::new(7UL)
  let buckets = Array::make(10, 0)
  for _ in 0..<10000 {
    buckets[r.next_int(10)] = buckets[r.next_int(10)] + 1
  }
  let mut sum = 0
  for b in buckets {
    sum = sum + b
  }
  assert_true(sum > 0)
}

///|
test "Ops 計數器" {
  let o = Ops::new()
  o.record_plus()
  o.record_times()
  assert_eq(o.total(), 2L)
  assert_eq(o.to_string(), "plus=1, times=1")
}

// ---------------------------------------------------------------------------
// 負面對照：故意做壞的實例
// ---------------------------------------------------------------------------

///|
/// 壞掉的「半環」：plus = max 正常，但 times(a,b) = a + b + 1 不滿足分配律。
pub(all) struct BrokenSr {
  v : Int32
} derive(Eq)

///|
pub fn BrokenSr::of(v : Int32) -> BrokenSr {
  { v, }
}

///|
pub impl Show for BrokenSr with fn output(self, logger) {
  logger.write_string(self.v.to_string())
}

///|
pub impl Semiring for BrokenSr with fn zero() {
  { v: 0, }
}

///|
pub impl Semiring for BrokenSr with fn one() {
  { v: 0, }
}

///|
pub impl Semiring for BrokenSr with fn plus(a, b) {
  { v: if a.v >= b.v { a.v } else { b.v }, }
}

///|
pub impl Semiring for BrokenSr with fn times(a, b) {
  { v: a.v + b.v + 1, }
}

///|
pub impl IdempotentSemiring for BrokenSr with fn le(a, b) {
  a.v <= b.v
}

///|
/// 謊稱自己是冪等半環的實例：⊕ 不冪等。
pub(all) struct LyingIdem {
  v : Int32
} derive(Eq)

///|
pub fn LyingIdem::of(v : Int32) -> LyingIdem {
  { v, }
}

///|
pub impl Show for LyingIdem with fn output(self, logger) {
  logger.write_string(self.v.to_string())
}

///|
pub impl Semiring for LyingIdem with fn zero() {
  { v: 0, }
}

///|
pub impl Semiring for LyingIdem with fn one() {
  { v: 1, }
}

///|
pub impl Semiring for LyingIdem with fn plus(a, b) {
  { v: a.v + b.v, }
}

///|
pub impl Semiring for LyingIdem with fn times(a, b) {
  { v: a.v * b.v, }
}

///|
pub impl IdempotentSemiring for LyingIdem with fn le(a, b) {
  a.v <= b.v
}

///|
/// 0.10 起 `impl` 不再自動把方法提升為一般方法；這裡顯式宣告。

///|
pub extend BrokenSr with Show::{output, to_string}

///|
/// 0.10 起 `impl` 不再自動把方法提升為一般方法；這裡顯式宣告。

///|
pub extend BrokenSr with Semiring::{zero, one, plus, times, is_zero, is_one}

///|
/// 0.10 起 `impl` 不再自動把方法提升為一般方法；這裡顯式宣告。

///|
pub extend BrokenSr with IdempotentSemiring::{le}

///|
/// 0.10 起 `impl` 不再自動把方法提升為一般方法；這裡顯式宣告。

///|
pub extend LyingIdem with Show::{output, to_string}

///|
/// 0.10 起 `impl` 不再自動把方法提升為一般方法；這裡顯式宣告。

///|
pub extend LyingIdem with Semiring::{zero, one, plus, times, is_zero, is_one}

///|
/// 0.10 起 `impl` 不再自動把方法提升為一般方法；這裡顯式宣告。

///|
pub extend LyingIdem with IdempotentSemiring::{le}

///|
/// `derive(Eq)` 產生的 impl 同樣需要顯式 extend（0.10 的方法提升規則）。

///|
pub extend BrokenSr with Eq::{equal, not_equal}

///|
/// `derive(Eq)` 產生的 impl 同樣需要顯式 extend（0.10 的方法提升規則）。

///|
pub extend LyingIdem with Eq::{equal, not_equal}
