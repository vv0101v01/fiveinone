// ===========================================================================
// 連帶相信（BP）的測試
// ===========================================================================

///|
/// 三變數鏈 0—f1—1—f2—2，每個變數二元，因子用固定種子隨機。
fn chain_graph(seed : UInt64) -> FactorGraph[Prob] {
  let rng = @alg.Rng::new(seed)
  let card : Array[Int32] = [2, 2, 2]
  let f1 = Factor::new([0, 1], [
    Prob::new(rng.range(1, 9).to_double() / 10.0),
    Prob::new(rng.range(1, 9).to_double() / 10.0),
    Prob::new(rng.range(1, 9).to_double() / 10.0),
    Prob::new(rng.range(1, 9).to_double() / 10.0),
  ])
  let f2 = Factor::new([1, 2], [
    Prob::new(rng.range(1, 9).to_double() / 10.0),
    Prob::new(rng.range(1, 9).to_double() / 10.0),
    Prob::new(rng.range(1, 9).to_double() / 10.0),
    Prob::new(rng.range(1, 9).to_double() / 10.0),
  ])
  { nvar: 3, card, factors: [f1, f2], }
}

///|
test "因子表索引：混合進位解碼與編碼互逆" {
  let card : Array[Int32] = [3, 2, 4]
  let f = Factor::new([2, 0], [Prob::new(1.0), Prob::new(2.0)])
  let assign : Array[Int32] = [3 % 4, 1]
  let idx = table_index(f, card, assign)
  // 索引 = a2 * card[0] + a0 = 3 * 3 + 1 = 10
  assert_eq(idx, 10)
}

///|
test "樹：sum-product 的邊緣與 q^n 暴力法完全相同" {
  for seed in [11UL, 22UL, 33UL, 44UL] {
    let g = chain_graph(seed)
    assert_true(is_tree(g))
    let (bp, ops_bp) = marginals_sum_product(g, rounds=8)
    let (bf, ops_bf) = brute_force_sum_product(g)
    for v in 0..<3 {
      let mut z = 0.0
      for x in 0..<2 {
        let d = bp[v][x] - bf[v][x]
        let ad = if d < 0.0 { -d } else { d }
        assert_true(ad < 1.0e-12)
        z = z + bp[v][x]
      }
      // 邊緣必須正規化（和為 1）
      assert_true(
        if z - 1.0 < 0.0 {
          1.0 - z < 1.0e-12
        } else {
          z - 1.0 < 1.0e-12
        },
      )
    }
    // 訊息傳遞的乘法次數不該爆炸
    assert_true(ops_bp > 0L)
    assert_true(ops_bf > 0L)
  }
}

///|
test "max-product（log 域 = max-plus）：MAP 邊緣與暴力法相同" {
  let rng = @alg.Rng::new(777UL)
  let card : Array[Int32] = [2, 2, 2]
  let mk = fn(scope : Array[Int32]) {
    let t : Array[TropMax] = []
    for _ in 0..<4 {
      t.push(TropMax::new(rng.range(-20, 0)))
    }
    Factor::new(scope, t)
  }
  let g : FactorGraph[TropMax] = {
    nvar: 3,
    card,
    factors: [mk([0, 1]), mk([1, 2])],
  }
  assert_true(is_tree(g))
  let (bp, _) = marginals_max_product(g, rounds=8)
  let (bf, _) = brute_force_max_product(g)
  for v in 0..<3 {
    for x in 0..<2 {
      assert_eq(bp[v][x], bf[v][x])
    }
  }
}

///|
test "有環的因子圖：BP 只是近似（誤差必須看得見，不能被假裝成精確）" {
  // 三個變數兩兩相連（三角形），二元
  let rng = @alg.Rng::new(4242UL)
  let card : Array[Int32] = [2, 2, 2]
  let mk = fn(scope : Array[Int32]) {
    let t : Array[Prob] = []
    for _ in 0..<4 {
      t.push(Prob::new(0.1 + rng.range(0, 9).to_double() / 10.0))
    }
    Factor::new(scope, t)
  }
  let g : FactorGraph[Prob] = {
    nvar: 3,
    card,
    factors: [mk([0, 1]), mk([1, 2]), mk([0, 2])],
  }
  assert_false(is_tree(g))
  let (bp, _) = marginals_sum_product(g, rounds=64)
  let (bf, _) = brute_force_sum_product(g)
  let mut worst = 0.0
  for v in 0..<3 {
    for x in 0..<2 {
      let d = bp[v][x] - bf[v][x]
      let ad = if d < 0.0 { -d } else { d }
      if ad > worst {
        worst = ad
      }
    }
  }
  // 文件與報告都必須承認：這裡不會是 0
  assert_true(worst > 1.0e-9)
  assert_true(worst < 0.5)
}

///|
test "複雜度：訊息傳遞的乘法次數遠少於暴力列舉" {
  // 16 個變數的鏈，二元 ⇒ 暴力 2^16 = 65536 個賦值；BP 只依賴 |scope| = 2
  let rng = @alg.Rng::new(9090UL)
  let n = 16
  let card : Array[Int32] = []
  for _ in 0..<n {
    card.push(2)
  }
  let factors : Array[Factor[Prob]] = []
  for v in 0..<(n - 1) {
    let t : Array[Prob] = []
    for _ in 0..<4 {
      t.push(Prob::new(0.1 + rng.range(0, 9).to_double() / 10.0))
    }
    factors.push(Factor::new([v, v + 1], t))
  }
  let g : FactorGraph[Prob] = { nvar: n, card, factors, }
  assert_true(is_tree(g))
  let (bp, ops_bp) = marginals_sum_product(g, rounds=40)
  let (bf, ops_bf) = brute_force_sum_product(g)
  // 兩者答案一致
  for v in 0..<n {
    for x in 0..<2 {
      let d = bp[v][x] - bf[v][x]
      let ad = if d < 0.0 { -d } else { d }
      assert_true(ad < 1.0e-12)
    }
  }
  // 運算量：暴力法的乘法次數是 q^n × |F| 量級，訊息傳遞只依賴 |scope|
  assert_eq(ops_bf, 65536L * 15L)
  assert_true(ops_bp * 10L < ops_bf)
}
