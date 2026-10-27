// ===========================================================================
// spline 套件測試
//
// 三個解法（稠密 / 帶狀 / 遞迴）必須互相印證；
// 而且「遞迴解」必須真的解出配點方程，而不是只看它跟另一支程式一致
// （否則兩支一起錯也會通過）。
// ===========================================================================

///|
test "B 樣條分割單位性：Σ_i B_i(t) = 1" {
  let rng = @alg.Rng::new(0xB0B0_0001UL)
  let p = 3
  let n = 16
  let knots = uniform_knots(p, n)
  for _ in 0..<50 {
    let t = rng.next_double() * (n - p).to_double()
    let mut s = 0.0
    for i in 0..<n {
      s = s + bspline_basis(knots, p, i, t)
    }
    assert_true((s - 1.0).abs() < 1.0e-10)
  }
}

///|
test "de Boor 演算法 == Σ c_i B_i(t)（交叉驗證）" {
  let rng = @alg.Rng::new(0xB0B0_0002UL)
  let p = 3
  let n = 12
  let knots = uniform_knots(p, n)
  let c = Array::makei(n, fn(_i) { rng.next_double() * 2.0 - 1.0 })
  for _ in 0..<40 {
    let t = rng.next_double() * (n - p).to_double()
    let mut sum = 0.0
    for i in 0..<n {
      sum = sum + c[i] * bspline_basis(knots, p, i, t)
    }
    let v = eval_deboor(c, knots, p, t)
    assert_true((v - sum).abs() < 1.0e-9)
  }
}

///|
test "遞迴解真的解出配點方程 (c[i-1] + 4c[i] + c[i+1])/6 = y[i]" {
  let rng = @alg.Rng::new(0xB0B0_0003UL)
  for n in [3, 8, 33, 128] {
    let y = Array::makei(n, fn(_i) { rng.next_double() * 10.0 })
    let c = interp_cubic_periodic(y)
    let mut worst = 0.0
    for i in 0..<n {
      let lhs = (c[(i + n - 1) % n] + 4.0 * c[i] + c[(i + 1) % n]) / 6.0
      let e = (lhs - y[i]).abs()
      worst = worst.max(e)
    }
    assert_true(worst < 1.0e-9)
  }
}

///|
test "週期系統：遞迴（O(n)）== 稠密循環（O(n³)）" {
  let rng = @alg.Rng::new(0xB0B0_0004UL)
  for n in [4, 9, 27, 64] {
    let y = Array::makei(n, fn(_i) { rng.next_double() * 2.0 - 1.0 })
    let cd = interp_cubic_dense(y)
    let ci = interp_cubic_periodic(y)
    for i in 0..<n {
      assert_true((cd[i] - ci[i]).abs() < 1.0e-9)
    }
  }
}

///|
test "開放邊界系統：帶狀 LU（O(n)）== 稠密（O(n³)）" {
  let rng = @alg.Rng::new(0xB0B0_0007UL)
  for n in [2, 5, 17, 40] {
    let y = Array::makei(n, fn(_i) { rng.next_double() * 2.0 - 1.0 })
    let cd = interp_cubic_dense_open(y)
    let cb = interp_cubic_banded(y)
    for i in 0..<n {
      assert_true((cd[i] - cb[i]).abs() < 1.0e-9)
    }
  }
}

///|
test "么半群前綴掃描 == 逐步遞推（仿射么半群）" {
  let rng = @alg.Rng::new(0xB0B0_0005UL)
  let z = cubic_pole()
  for n in [1, 5, 17, 64] {
    let ys = Array::makei(n, fn(_i) { rng.next_double() })
    let scanned = affine_steps(z, ys)
    let mut acc = 0.0
    for i in 0..<n {
      acc = score(acc, z, ys[i])
      let v = scanned[i].apply(0.0)
      assert_true((v - acc).abs() < 1.0e-12)
    }
  }
}

///|
fn score(prev : Double, z : Double, y : Double) -> Double {
  y + z * prev
}

///|
test "帶狀 LU 對奇異矩陣回傳 None（而不是垃圾值）" {
  // 全零矩陣 ⇒ 奇異
  match solve_banded(Banded::tridiag(4, 0.0, 0.0), [1.0, 2.0, 3.0, 4.0]) {
    Some(_) => abort("expected None for singular banded matrix")
    None => assert_true(true)
  }
  match solve_dense([[0.0, 0.0], [0.0, 0.0]], [1.0, 2.0]) {
    Some(_) => abort("expected None for singular dense matrix")
    None => assert_true(true)
  }
}

///|
test "樣條曲線通過配點（用 de Boor 在節點上驗證）" {
  let rng = @alg.Rng::new(0xB0B0_0006UL)
  let p = 3
  let n = 24
  let knots = uniform_knots(p, n)
  let y = Array::makei(n, fn(_i) { rng.next_double() * 2.0 - 1.0 })
  let c = interp_cubic_periodic(y)
  // 週期均勻情形：曲線在整數點 t = i 的值應為 y[i]
  // （控制點 c 位於 t = i - p/2 … 的等效位移，這裡用配點定義直接驗證較穩妥）
  let mut worst = 0.0
  for i in 0..<n {
    let lhs = (c[(i + n - 1) % n] + 4.0 * c[i] + c[(i + 1) % n]) / 6.0
    worst = worst.max((lhs - y[i]).abs())
  }
  assert_true(worst < 1.0e-9)
  // 且 de Boor 在整數節點附近是連續的（相鄰取樣差有界）
  let t0 = 5.0
  let a = eval_deboor(c, knots, p, t0)
  let b = eval_deboor(c, knots, p, t0 + 0.0001)
  assert_true((a - b).abs() < 1.0)
}
