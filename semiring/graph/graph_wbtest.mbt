// ===========================================================================
// graph 套件測試
//
// 交叉驗證策略：每一個「快」的演算法都要和一個「慢但獨立」的實作或
// 暴力法對照。特別是可達性（bitset 位元平行）與多目標（Pareto 剪枝），
// 這兩處最容易寫出看起來對、其實漏解的東西。
// ===========================================================================

///|
test "Dijkstra 與 Kleene 閉包結果完全一致（隨機圖）" {
  let rng = @alg.Rng::new(0xABCD_0001UL)
  for n in [4, 9, 16] {
    let g = Graph::random(rng, n, 45, 20)
    let d_dij = apsp_dijkstra(g)
    let (d_kleene, neg) = apsp_kleene(g)
    assert_false(neg)
    for i in 0..<n {
      for j in 0..<n {
        assert_eq(d_dij.d[i * n + j].value(), d_kleene[i][j])
      }
    }
  }
}

///|
test "Dijkstra 對負邊明確報錯（前提檢查）" {
  let g = Graph::build(3, [0, 1], [1, 2], [5, -2])
  let (_, has_neg) = dijkstra(g, 0)
  assert_true(has_neg)
  // Kleene 在同一輸入上仍可計算（但若形成負環則必須被偵測）
  let g2 = Graph::build(2, [0, 1], [1, 0], [-1, -1])
  let (_, neg) = apsp_kleene(g2)
  assert_true(neg)
}

///|
test "位元平行閉包 == 純量 Kleene 閉包 == BFS" {
  let rng = @alg.Rng::new(0xABCD_0002UL)
  for n in [1, 5, 17, 70] {
    let g = Graph::random(rng, n, 12, 5)
    let bc = closure_bitset(g)
    // 純量矩陣 Kleene（布林半環）
    let bm = @mat.Mat::new(n, n, @alg.BoolSr::of(false))
    for u in 0..<n {
      for e in g.offsets[u]..<g.offsets[u + 1] {
        bm.d[u * n + g.to[e]] = @alg.BoolSr::of(true)
      }
    }
    let cl = @mat.closure_fw_inplace(bm)
    for i in 0..<n {
      for j in 0..<n {
        assert_true(bc.get(i, j) == cl.d[i * n + j].b)
      }
    }
    // BFS 對照（隨機抽幾個源點）
    for s in 0..<n.min(6) {
      let seen = Array::make(n, false)
      let q = Array(capacity=n)
      seen[s] = true
      q.push(s)
      let mut h = 0
      while h < q.length() {
        let u = q[h]
        h = h + 1
        for e in g.offsets[u]..<g.offsets[u + 1] {
          let v = g.to[e]
          if !seen[v] {
            seen[v] = true
            q.push(v)
          }
        }
      }
      for j in 0..<n {
        assert_true(bc.get(s, j) == seen[j])
      }
    }
  }
}

///|
test "位元平行閉包的字運算量：約為純量 Kleene 的 1/64" {
  let rng = @alg.Rng::new(0xABCD_0003UL)
  let n = 64
  let g = Graph::random(rng, n, 80, 5)
  let ob = Ops::new()
  let _ = closure_bitset(g, row_ops=ob)
  let bm = @mat.Mat::new(n, n, @alg.BoolSr::of(false))
  for u in 0..<n {
    for e in g.offsets[u]..<g.offsets[u + 1] {
      bm.d[u * n + g.to[e]] = @alg.BoolSr::of(true)
    }
  }
  let os = Ops::new()
  let _ = @mat.closure_fw_inplace(bm, ops=os)
  // 布林矩陣的純量版本每個 (i,k,j) 一次 ⊗；位元版本每個 (i,k) 一次列 OR
  assert_true(ob.total() * 32L < os.total())
}

///|
test "功能圖分解：環與尾巴的可達點數與閉包一致" {
  let rng = @alg.Rng::new(0xABCD_0004UL)
  for n in [5, 12, 40] {
    // 每點出度 ≤ 1
    let from : Array[Int32] = []
    let to : Array[Int32] = []
    let w : Array[Int32] = []
    for i in 0..<n {
      if rng.next_int(100) < 85 {
        from.push(i)
        to.push(rng.next_int(n))
        w.push(1)
      }
    }
    let g = Graph::build(n, from, to, w)
    let dec = functional_decompose(g)
    let bc = closure_bitset(g)
    for v in 0..<n {
      assert_eq(dec.reach_count(v), bc.row_count(v))
    }
  }
}

///|
test "最寬路徑（瓶頸）與瓶頸半環閉包一致" {
  let rng = @alg.Rng::new(0xABCD_0005UL)
  for n in [6, 14] {
    let g = Graph::random(rng, n, 50, 30)
    let bm = @mat.Mat::new(n, n, @alg.Bottleneck::new(0))
    for u in 0..<n {
      for e in g.offsets[u]..<g.offsets[u + 1] {
        bm.d[u * n + g.to[e]] = @alg.Bottleneck::new(g.w[e])
      }
    }
    let cl = @mat.closure_fw_inplace(bm)
    for s in 0..<n {
      let widest = widest_path(g, s)
      for v in 0..<n {
        // 瓶頸半環的 zero 是 0（不連通）；widest_path 用 0 表示不可達
        assert_eq(widest[v], cl.d[s * n + v].value())
      }
    }
  }
}

///|
test "多目標最短路：Pareto 前沿與「列舉所有簡單路徑」一致" {
  let rng = @alg.Rng::new(0xABCD_0006UL)
  for trial in 0..<6 {
    let n = 5 + trial % 2
    let g = Graph::random_two(rng, n, 55, 9)
    let (dist, conv) = pareto_sssp(g, 0)
    assert_true(conv)
    for tgt in 0..<n {
      let brute = brute_pareto(g, 0, tgt)
      assert_true(dist[tgt] == brute)
    }
  }
}

///|
/// 暴力法：DFS 列舉所有簡單路徑（n ≤ 6 可行），收集成本向量後做支配剪枝。
fn brute_pareto(g : Graph, src : Int32, dst : Int32) -> ParetoSet {
  let visited = Array::make(g.n, false)
  dfs_pareto(g, src, dst, 0, 0, visited)
}

///|
fn dfs_pareto(
  g : Graph,
  u : Int32,
  dst : Int32,
  c1 : Int32,
  c2 : Int32,
  visited : Array[Bool],
) -> ParetoSet {
  let mut acc = ParetoSet::empty(2)
  if u == dst {
    acc = ParetoSet::plus(acc, ParetoSet::point([c1, c2]))
  }
  visited[u] = true
  for e in g.offsets[u]..<g.offsets[u + 1] {
    let v = g.to[e]
    if !visited[v] {
      acc = ParetoSet::plus(
        acc,
        dfs_pareto(g, v, dst, c1 + g.w[e], c2 + g.w2[e], visited),
      )
    }
  }
  visited[u] = false
  acc
}

///|
test "Pareto 標籤數受支配剪枝控制（單目標退化情形標籤只有 1 個）" {
  let rng = @alg.Rng::new(0xABCD_0007UL)
  let n = 12
  let g = Graph::random(rng, n, 35, 20)
  // 第二維全為 0 ⇒ 所有標籤在同一維上可比，前沿大小必為 1
  let w2 = Array::make(g.edges(), 0)
  let g1 = g.with_second(w2)
  let (dist, _) = pareto_sssp(g1, 0)
  for v in 0..<n {
    assert_true(dist[v].size() <= 1)
  }
}
