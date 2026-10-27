// ===========================================================================
// 範疇化的測試：四條獨立路徑必須給出同一個數字
// ===========================================================================

///|
fn dag_example() -> DiGraph {
  // 0 → 1, 0 → 2, 1 → 3, 2 → 3, 1 → 2
  let g = DiGraph::new(4)
  g.edge(0, 1)
  g.edge(0, 2)
  g.edge(1, 3)
  g.edge(2, 3)
  g.edge(1, 2)
  g
}

///|
test "自由範疇：|Hom(i,j)| = 計數半環的 Kleene 星" {
  let g = dag_example()
  assert_true(g.is_dag())
  let hom = g.hom_sets()
  let dp = g.path_counts()
  let pw = g.path_counts_by_powers()
  let cl = g.path_counts_by_closure()
  for i in 0..<4 {
    for j in 0..<4 {
      assert_eq(hom[i][j].length().to_int64(), dp[i][j])
      assert_eq(dp[i][j], pw[i][j])
      assert_eq(dp[i][j], cl[i][j])
    }
  }
  // 具體值：0→3 有 3 條路徑（0-1-3, 0-2-3, 0-1-2-3）
  assert_eq(dp[0][3], 3L)
  assert_eq(dp[0][0], 1L)
}

///|
test "自由範疇：見證不重複（基數就是路徑個數，不是重複計數）" {
  let g = dag_example()
  let mat = g.hom_setmat()
  for i in 0..<4 {
    for j in 0..<4 {
      let ws = mat.get(i, j)
      assert_eq(distinct_witnesses(ws), ws.length())
    }
  }
  // 0→3 的三條路徑必須真的不同
  let ws = mat.get(0, 3)
  assert_eq(ws.length(), 3)
  for a in 0..<ws.length() {
    for b in (a + 1)..<ws.length() {
      assert_false(witness_equal(ws[a], ws[b]))
    }
  }
}

///|
test "有環的圖不是自由範疇（Hom 無限）" {
  let g = DiGraph::new(3)
  g.edge(0, 1)
  g.edge(1, 2)
  g.edge(2, 0)
  assert_false(g.is_dag())
  assert_eq(g.topo_order().length(), 0)
}

///|
test "基數是同態：|A⊗B| = |A|·|B|，|A⊕B| = |A|+|B|" {
  let rng = @alg.Rng::new(2024UL)
  let n = 4
  let a = SetMat::new(n, n)
  let b = SetMat::new(n, n)
  for i in 0..<n {
    for j in 0..<n {
      let ka = rng.next_int(3)
      for l in 0..<ka {
        a.add(i, j, [i, j, l])
      }
      let kb = rng.next_int(3)
      for l in 0..<kb {
        b.add(i, j, [j, i, l])
      }
    }
  }
  let prod = smat_mul(a, b)
  let sum = smat_plus(a, b)
  let da = decategorify(a)
  let db = decategorify(b)
  let dp = decategorify(prod)
  let ds = decategorify(sum)
  let sem_prod = @mat.mul_ikj(da, db)
  let sem_sum = @mat.mat_plus(da, db)
  for i in 0..<n {
    for j in 0..<n {
      assert_eq(dp.get(i, j).value(), sem_prod.get(i, j).value())
      assert_eq(ds.get(i, j).value(), sem_sum.get(i, j).value())
    }
  }
}

///|
test "範疇化的路徑數 < 解範疇化後直接乘（ℕ 上）—— 兩者相同" {
  let g = dag_example()
  let mat = g.hom_setmat()
  let lhs = decategorify(mat)
  let rhs = @mat.closure_lehmann(g.adjacency())
  for i in 0..<4 {
    for j in 0..<4 {
      assert_eq(lhs.get(i, j).value(), rhs.get(i, j).value())
    }
  }
}

///|
test "解量化：h → 0 時 −h·ln Σ exp(−x/h) → min" {
  let xs : Array[Double] = [3.0, 1.0, 4.0, 1.5, 9.0, 2.6]
  let mut prev = 1.0e300
  let mut h = 1.0
  let mut steps = 0
  for _ in 0..<8 {
    let e = dequant_error(xs, h)
    assert_true(e <= prev)
    prev = e
    h = h * 0.1
    steps = steps + 1
  }
  assert_eq(steps, 8)
  // 穩定版在 h = 1e-8 時仍然收斂到 min（誤差 → 0）
  assert_true(prev < 1.0e-6)
  assert_true(prev >= 0.0)
  // 樸素版在同一個 h 上已經下溢（ln(0) = −∞）：這是它被換掉的原因
  let naive = dequantize_naive(xs, 1.0e-8)
  assert_true(naive > 1.0e299)
}

///|
test "解量化：min-plus 乘積 = 一般乘積的 h → 0 極限（逐格）" {
  let a : Array[Array[Double]] = [[0.0, 3.0], [7.0, 0.0]]
  let b : Array[Array[Double]] = [[0.0, 2.0], [1.0, 0.0]]
  let mp = minplus_mul(a, b)
  let e1 = max_abs_diff(dequantized_mul(a, b, 0.1), mp)
  let e2 = max_abs_diff(dequantized_mul(a, b, 0.01), mp)
  let e3 = max_abs_diff(dequantized_mul(a, b, 0.001), mp)
  // 誤差隨 h 下降而不增；最後落到機器精度以下（不是「變成 0」，
  // 而是小於 double 在該量級的解析度——這一點報告裡會誠實寫出來）
  assert_true(e1 >= e2)
  assert_true(e2 >= e3)
  assert_true(e1 > 1.0e-6)
  assert_true(e3 < 1.0e-6)
}

///|
test "解量化保留 argmin 結構（領先項不變）" {
  let rng = @alg.Rng::new(4711UL)
  let k = 8
  let a : Array[Double] = Array::make(k, 0.0)
  let b : Array[Double] = Array::make(k, 0.0)
  for i in 0..<k {
    a[i] = rng.range(0, 50).to_double()
    b[i] = rng.range(0, 50).to_double()
  }
  let idx = argmin_k(a, b)
  // 以 h = 1e-6 解量化：最大權重的 k 必須與 min-plus 的 argmin 相同
  let mut m = 1.0e300
  for i in 0..<k {
    if a[i] + b[i] < m {
      m = a[i] + b[i]
    }
  }
  let mut best = -1.0
  let mut best_k : Int32 = -1
  for i in 0..<k {
    let w = @math.exp(-(a[i] + b[i] - m) / 1.0e-6)
    if w > best {
      best = w
      best_k = i
    }
  }
  assert_eq(best_k, idx)
}
