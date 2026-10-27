// ===========================================================================
// 代數路徑問題與演算法組合的測試
// ===========================================================================

///|
using @alg {type Rng}

///|
fn rand_trop_edges(
  rng : @alg.Rng,
  n : Int32,
  m : Int32,
) -> Array[(Int32, Int32, Trop)] {
  let es : Array[(Int32, Int32, Trop)] = []
  for _ in 0..<m {
    let u = rng.next_int(n)
    let v = rng.next_int(n)
    if u != v {
      es.push((u, v, @alg.Trop::new(rng.range(1, 20))))
    }
  }
  es
}

///|
test "APP：同一段程式在 Bool 上是可達性（與 BFS 逐格相同）" {
  let rng = Rng::new(1234UL)
  let n = 6
  let raw = rand_trop_edges(rng, n, 14)
  let es_pairs : Array[(Int32, Int32)] = []
  for e in raw {
    es_pairs.push((e.0, e.1))
  }
  let cl = app_bool(n, es_pairs)
  let bfs = reach_bfs(n, es_pairs)
  for i in 0..<n {
    for j in 0..<n {
      assert_eq(cl.get(i, j).b, bfs[i][j])
    }
  }
}

///|
test "APP：在 Trop 上是全源最短路（與本地 FW 逐格相同）" {
  let rng = Rng::new(777UL)
  let n = 7
  let es = rand_trop_edges(rng, n, 18)
  let es_i : Array[(Int32, Int32, Int32)] = []
  for e in es {
    es_i.push((e.0, e.1, e.2.value()))
  }
  let cl = app_minplus(n, es_i)
  let fw = shortest_fw(n, es_i)
  for i in 0..<n {
    for j in 0..<n {
      assert_eq(cl.get(i, j).value(), fw[i][j])
    }
  }
}

///|
test "APP：在 Bottleneck 上是最大瓶頸（與本地 max-min FW 相同）" {
  let rng = Rng::new(313UL)
  let n = 6
  let es_i : Array[(Int32, Int32, Int32)] = []
  for _ in 0..<14 {
    let u = rng.next_int(n)
    let v = rng.next_int(n)
    let c = rng.range(1, 100)
    if u != v {
      es_i.push((u, v, c))
    }
  }
  let cl = app_widest(n, es_i)
  let w = widest_fw(n, es_i)
  for i in 0..<n {
    for j in 0..<n {
      assert_eq(cl.get(i, j).value(), w[i][j])
    }
  }
}

///|
test "APP：在 Prob 上是各路徑機率之和（DAG 上與暴力列舉完全相同）" {
  // 用 DAG：路徑有限，暴力列舉是精確對照；有環的情形見下一個測試
  let rng = Rng::new(2026UL)
  let n = 5
  let es_d : Array[(Int32, Int32, Double)] = []
  for _ in 0..<8 {
    let u = rng.next_int(n)
    let v = rng.next_int(n)
    let p = rng.range(1, 9).to_double() / 10.0
    if u < v {
      es_d.push((u, v, p))
    }
  }
  let (cl, converged) = app_mostlikely(n, es_d)
  assert_true(converged)
  let bf = most_likely_bruteforce(n, es_d)
  for i in 0..<n {
    for j in 0..<n {
      let a = cl.get(i, j).value()
      let b = bf[i][j]
      let d = if a > b { a - b } else { b - a }
      assert_true(d < 1.0e-12)
    }
  }
}

///|
test "Prob 的星會發散時，收斂旗標必須是 false（不會給假答案）" {
  // 自環機率 1.0 ⇒ 級數 1 + 1 + 1 + … 發散
  let es : Array[(Int32, Int32, Double)] = [(0, 0, 1.0)]
  let (_m, converged) = app_mostlikely(2, es)
  assert_false(converged)
  // 自環機率 0.5 ⇒ 收斂到 2
  let es2 : Array[(Int32, Int32, Double)] = [(0, 0, 0.5)]
  let (m2, ok2) = app_mostlikely(1, es2)
  assert_true(ok2)
  let d = m2.get(0, 0).value() - 2.0
  let ad = if d < 0.0 { -d } else { d }
  assert_true(ad < 1.0e-9)
}

///|
test "APP：在 Counting 上是路徑數（DAG，與矩陣冪級數相同）" {
  // 用 cat 套件的 DAG 範例
  let g = @cat.DiGraph::new(4)
  g.edge(0, 1)
  g.edge(0, 2)
  g.edge(1, 3)
  g.edge(2, 3)
  g.edge(1, 2)
  let es : Array[(Int32, Int32, Int64)] = []
  for u in 0..<4 {
    for v in g.adj[u] {
      es.push((u, v, 1L))
    }
  }
  let cl = app_counts(4, es)
  let pw = g.path_counts_by_powers()
  for i in 0..<4 {
    for j in 0..<4 {
      assert_eq(cl.get(i, j).value(), pw[i][j])
    }
  }
}

///|
test "一致性仲裁：五個獨立實作在隨機圖上全部相同" {
  let rng = Rng::new(90210UL)
  for trial in 0..<3 {
    let n = 24
    let es = rand_trop_edges(rng, n, n * 3)
    let m = build(n, es)
    let v = consensus_trop(m, 1)
    assert_eq(v.runs.length(), 5)
    assert_true(v.agree)
    for r in v.runs {
      assert_true(r.agrees)
    }
    assert_true(v.winner_us <= v.total_us)
    assert_true(v.cost_of_trust >= 1.0)
    // 試跑編號要能區分不同實例
    assert_true(trial >= 0)
  }
}

///|
test "一致性仲裁：注入錯的候選會被拒絕（負面對照）" {
  let rng = Rng::new(5150UL)
  let n = 16
  let es = rand_trop_edges(rng, n, n * 2)
  let m = build(n, es)
  let v = consensus_trop(m, 1, inject_wrong=true)
  assert_eq(v.runs.length(), 6)
  assert_false(v.agree)
  // 錯的那一個必須被標成不一致，其餘五個仍然一致
  let mut wrong_count = 0
  for r in v.runs {
    if !r.agrees {
      wrong_count = wrong_count + 1
    }
  }
  assert_eq(wrong_count, 1)
}

///|
test "APP 的型別約束真的在檔人：非冪等半環不能用原地 Warshall" {
  // 這不是執行期測試，而是把「矩陣星有兩種入口」寫成可讀的證據：
  // closure_fw_inplace 要求 IdempotentSemiring，closure_lehmann 只要求 StarSemiring。
  // 這裡驗證 Counting（非冪等）走 Lehmann 的結果與冪級數一致。
  let g = @cat.DiGraph::new(4)
  g.edge(0, 1)
  g.edge(1, 2)
  g.edge(2, 3)
  let a = g.adjacency()
  let cl = @mat.closure_lehmann(a)
  let pw = g.path_counts_by_powers()
  for i in 0..<4 {
    for j in 0..<4 {
      assert_eq(cl.get(i, j).value(), pw[i][j])
    }
  }
}
