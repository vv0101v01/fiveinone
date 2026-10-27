///|
/// API 健檢測試：**每一個公開入口都必須被使用且被驗證**（清死碼之後的回歸網）。
/// 涵蓋：共用工具（不交併/偽隨機/字串）、作用與折疊之跨模組一致性、
/// 單子管線、分解包裝、Kan 擴張之 FinAction 視角、隨機 CSP、搜索引擎之單一入口。
test "api-shared-utils" {
  // 不交併：n/m/分量數/|Aut| 積公式
  let u = @symlib.Graph::disjoint_union([
    @symlib.Graph::petersen(),
    @symlib.Graph::cycle(6),
    @symlib.Graph::empty(3),
  ])
  assert_eq(u.order(), 19)
  assert_eq(u.size(), 15 + 6)
  assert_eq(u.components().length(), 5) // Petersen, C6, 3 個孤立點
  assert_eq(@symlib.aut_order_decomposed(u), 120L * 12L * 6L) // 3! 個孤立點
  // 空陣列 ⇒ 空圖
  assert_eq(@symlib.Graph::disjoint_union([]).order(), 0)
  // 單元素 ⇒ 同構於原圖
  assert_true(
    @symlib.isomorphic(
      @symlib.Graph::disjoint_union([@symlib.Graph::cycle(5)]),
      @symlib.Graph::cycle(5),
    ),
  )
  // 偽隨機：同種子 ⇒ 同圖；種子鏈可串接
  let (g1, s1) = @symlib.Graph::random(12, 50, 7)
  let (g2, s2) = @symlib.Graph::random(12, 50, 7)
  assert_eq(@symlib.canon_digest(g1), @symlib.canon_digest(g2))
  assert_true(s1 == s2 && s1 != 7)
  let (g3, _) = @symlib.Graph::random(12, 50, 8)
  assert_true(@symlib.canon_digest(g1) != @symlib.canon_digest(g3))
  // 邊數落在合理範圍（p=50% ⇒ 約 33 條）
  assert_true(g1.size() > 10 && g1.size() < 56)
  // 偽隨機置換：確為置換且確定
  let (p1, ps1) = @symlib.Perm::random(9, 11)
  let (p2, _) = @symlib.Perm::random(9, 11)
  assert_eq(p1, p2)
  assert_true(ps1 != 11)
  let seen = Array::make(9, false)
  for v in 0..<9 {
    let w = p1.apply(v)
    assert_true(w >= 0 && w < 9 && !seen[w])
    seen[w] = true
  }
  // 隨機整數序列：值域正確 + 確定
  let (xs, xs_seed) = @symlib.random_ints(20, 4, 3)
  assert_eq(xs.length(), 20)
  for v in xs {
    assert_true(v >= 0 && v < 4)
  }
  let (ys, _) = @symlib.random_ints(20, 4, 3)
  assert_eq(@symlib.ints_to_string(xs), @symlib.ints_to_string(ys))
  assert_true(xs_seed != 3)
  // LCG：範圍 [0, 2^31)、確定、非定點
  let a = @symlib.lcg_step(1)
  assert_true(a >= 0 && a < 2147483647)
  assert_eq(a, @symlib.lcg_step(1))
  assert_true(a != 1)
  // 字串工具
  assert_eq(@symlib.ints_to_string([1, 2, 3]), "[1,2,3]")
  assert_eq(@symlib.ints_to_string([]), "[]")
  assert_eq(@symlib.int_rows_to_string([[1, 2], [3]]), "[1,2][3]")
  assert_eq(@symlib.int_rows_to_string([]), "")
}

///|
test "api-action-fold-consistency" {
  for
    g in [
      @symlib.Graph::cycle(6),
      @symlib.Graph::petersen(),
      @symlib.Graph::path(5),
      @symlib.Graph::star(4),
      @symlib.Graph::complete_bipartite(3, 3),
    ] {
    let grp = @symlib.automorphism_group(g)
    let act = @symlib.FinAction::of_group(grp)
    // orbit_sizes：與 orbits 逐一相符，且 Σ = |X|（軌道分割之守恆律）
    let orbs = act.orbits()
    let sizes = act.orbit_sizes()
    assert_eq(sizes.length(), orbs.length())
    let mut sum = 0
    for i, o in orbs {
      assert_eq(sizes[i], o.length())
      sum = sum + sizes[i]
    }
    assert_eq(sum, g.order())
    // fold_ratio（作用视角）== FoldedGraph::ratio（折疊视角）⇒ 跨模組一致性
    let folded = @symlib.fold_graph(g, grp)
    let d = act.fold_ratio() - folded.ratio()
    assert_true(d < 0.000000001 && 0.0 - d < 0.000000001)
    // orbit_rep = 軌道之最小點；fundamental_domain(全部點) = 各軌道代表（升冪）
    let all : Array[Int32] = []
    for v in 0..<g.order() {
      all.push(v)
    }
    let fd = @symlib.fundamental_domain(grp, all)
    let reps : Array[Int32] = []
    for v in all {
      let r = grp.orbit_rep(v)
      assert_true(fd.contains(r))
      // 同軌道 ⇒ 同代表
      for w in grp.orbit(v) {
        assert_eq(grp.orbit_rep(w), r)
      }
      if !reps.contains(r) {
        reps.push(r)
      }
    }
    reps.sort()
    assert_eq(@symlib.ints_to_string(fd), @symlib.ints_to_string(reps))
    assert_eq(fd.length(), folded.k)
  }
}

///|
test "api-monad-pipeline" {
  for
    g in [
      @symlib.Graph::cycle(6),
      @symlib.Graph::path(5),
      @symlib.Graph::petersen(),
    ] {
    // StateM 管線之規範標號必須與直接調用一致，且統計被正確線程化
    let init : @symlib.SearchStats = { nodes: 0, leaves: 0, autos: 0, }
    let (lab, stats) = (@symlib.canonical_labeling_m(g).run)(init)
    assert_eq(
      @symlib.ints_to_string(lab),
      @symlib.ints_to_string(@symlib.canonical_labeling(g)),
    )
    let direct = @symlib.search_graph(g, true)
    assert_eq(stats.nodes, direct.nodes)
    assert_eq(stats.leaves, direct.leaves)
    // analyze_m 之統計與 analyze 一致
    let (rep, st2) = (@symlib.analyze_m(g).run)(init)
    assert_eq(st2.nodes, direct.nodes)
    assert_eq(rep.order, @symlib.aut_order(g))
  }
}

///|
test "api-decomp-wrappers" {
  for
    g in [
      @symlib.Graph::disjoint_union([
        @symlib.Graph::petersen(),
        @symlib.Graph::petersen(),
      ]),
      @symlib.Graph::disjoint_union([
        @symlib.Graph::cycle(6),
        @symlib.Graph::cycle(6),
        @symlib.Graph::complete(2),
      ]),
      @symlib.Graph::cycle(7),
    ] {
    let d = @symlib.decompose(g)
    // 三個包裝必須與結構体方法一致
    assert_true(@symlib.canonical_form_decomposed(g) == d.canonical_form())
    assert_eq(@symlib.aut_order_decomposed(g), d.aut_order())
    assert_eq(
      @symlib.ints_to_string(@symlib.block_encoding_of(g)),
      @symlib.ints_to_string(d.block_encoding()),
    )
    assert_true(@symlib.isomorphic(@symlib.canonical_form_decomposed(g), g))
    // 摘要字串可show（Show impl 走同一路徑）
    assert_true(d.summary().length() > 10)
    assert_eq(d.to_string(), d.summary())
    // decomp_key_equal 之自反性
    assert_true(@symlib.decomp_key_equal(d, @symlib.decompose(g)))
  }
}

///|
test "api-kan-finaction-view" {
  let grp = @symlib.PermGroup::symmetric(3)
  let x = 2
  // FinAction 视角（yoneda）與 GSetOf 视角（gset）必須描述同一個 (co)induced G-集
  let coi_act = @symlib.coinduced_gset(grp, x, 400)
  let coi_gs = @symlib.gset_coinduced(grp, x, 400)
  assert_eq(coi_act.card(), @symlib.coinduced_card(grp, x, 400))
  assert_eq(coi_act.card(), coi_gs.x)
  assert_eq(coi_act.orbits().length(), @symlib.gset_orbits(coi_gs).length())
  assert_eq(coi_act.orbit_count(), @symlib.gset_burnside(coi_gs).0)
  // 不動點：FinAction::fixed_points(img) vs G-集之 X^G
  let elems = grp.elements(400)
  let mut fixed_all = coi_act.card()
  for e in elems {
    let img = @symlib.coinduced_lift(grp, x, 400, e)
    let f = coi_act.fixed_points(img)
    if f < fixed_all {
      fixed_all = f
    }
  }
  assert_true(fixed_all >= @symlib.gset_global_fixed(coi_gs))
  // 歸納側同一檢查
  let ind_act = @symlib.induced_gset(grp, x, 400)
  let ind_gs = @symlib.gset_induced(grp, x, 400)
  assert_eq(ind_act.card(), ind_gs.x)
  assert_eq(ind_act.orbits().length(), @symlib.gset_orbits(ind_gs).length())
  for o in ind_act.orbits() {
    assert_eq(o.length(), 6) // 自由作用
  }
  assert_true(ind_act.is_transitive() == false)
}

///|
test "api-csp-random-vs-monad" {
  // 隨機 CSP：極限（範疇）== search_nd（ListM 單子）
  for seed in [1, 2, 3, 5, 8] {
    let k = 4
    let d = 3
    let dom = Array::make(k, d)
    // 以 random_ints 產生 3 條二元約束之允許對
    let (rs, _) = @symlib.random_ints(3 * 8, d * d, seed)
    let cons : Array[(Int32, Int32, Array[(Int32, Int32)])] = []
    for c in 0..<3 {
      let i = c % k
      let j = (c + 1) % k
      let allowed : Array[(Int32, Int32)] = []
      for t in 0..<8 {
        let v = rs[c * 8 + t]
        allowed.push((v / d, v % d))
      }
      cons.push((i, j, allowed))
    }
    let sols = @symlib.csp_limit(dom, cons, 100000)
    // search_nd 對照
    let vals : Array[Array[Int32]] = []
    for _ in 0..<k {
      let col : Array[Int32] = []
      for v in 0..<d {
        col.push(v)
      }
      vals.push(col)
    }
    let nd = @symlib.search_nd(vals, fn(sol : Array[Int32]) -> Bool {
      for c in cons {
        let (i, j, allowed) = c
        let mut ok = false
        for pr in allowed {
          let (a, b) = pr
          if sol[i] == a && sol[j] == b {
            ok = true
            break
          }
        }
        if !ok {
          return false
        }
      }
      true
    })
    let nda = nd.to_array()
    assert_eq(sols.length(), nda.length())
    for s in sols {
      let mut found = false
      for t2 in nda {
        if @symlib.cmp_arr(s, t2) == 0 {
          found = true
          break
        }
      }
      assert_true(found)
    }
    // 每個解都滿足約束（健全性）
    for s in sols {
      for c in cons {
        let (i, j, allowed) = c
        let mut ok = false
        for pr in allowed {
          let (a, b) = pr
          if s[i] == a && s[j] == b {
            ok = true
            break
          }
        }
        assert_true(ok)
      }
    }
  }
}

///|
test "api-search-single-funnel" {
  for
    g in [
      @symlib.Graph::petersen(),
      @symlib.Graph::cycle(8),
      @symlib.Graph::hypercube(3),
    ] {
    let r_main = @symlib.search_graph(g, true)
    let r_mode = @symlib.search_graph_mode(g, 1)
    let r_flag = @symlib.search_graph_flags(g, 1, true)
    // 三個入口委派至同一實作 ⇒ 逐項相同
    assert_eq(r_main.nodes, r_mode.nodes)
    assert_eq(r_main.nodes, r_flag.nodes)
    assert_eq(
      @symlib.ints_to_string(r_main.canon_enc),
      @symlib.ints_to_string(r_flag.canon_enc),
    )
    assert_eq(
      @symlib.canon_digest(g),
      @symlib.digest_from(r_flag.n, r_flag.canon_enc),
    )
    // 前綴剪枝旗標確有作用：關掉 ⇒ 節點數不減，規範編碼不變
    let r_nobb = @symlib.search_graph_flags(g, 1, false)
    assert_true(r_nobb.nodes >= r_flag.nodes)
    assert_eq(
      @symlib.ints_to_string(r_nobb.canon_enc),
      @symlib.ints_to_string(r_flag.canon_enc),
    )
    // 無剪枝模式之指紋亦一致
    let r0 = @symlib.search_graph_flags(g, 0, true)
    assert_eq(@symlib.digest_from(r0.n, r0.canon_enc), @symlib.canon_digest(g))
  }
}

///|
test "api-dual-group-and-keylut" {
  // 對偶群（取代已移除之 aut_order_dual 包裝）：|Aut(Ḡ)| == |Aut(G)| 且互含
  for
    g in [
      @symlib.Graph::cycle(6),
      @symlib.Graph::petersen(),
      @symlib.Graph::path(6),
    ] {
    let a1 = @symlib.automorphism_group(g)
    let a2 = @symlib.automorphism_group_dual(g)
    assert_eq(a1.order(), a2.order())
    for p in a1.generators() {
      assert_true(a2.contains(p))
    }
    for p in a2.generators() {
      assert_true(a1.contains(p))
    }
  }
  // KeyLut 之成對建構子必須與 key_lut 一致
  let keys : Array[Int64] = [5L, 3L, 99L, 7L]
  let vals : Array[Int32] = [10, 11, 12, 13]
  let lut = @symlib.key_lut_pairs(keys, vals)
  let lut2 = @symlib.key_lut(keys)
  for i, k in keys {
    assert_eq(lut.at(k), vals[i])
    assert_eq(lut2.at(k), i)
    assert_eq(lut.find(k), vals[i])
  }
  assert_eq(lut.find(1234L), -1)
}
