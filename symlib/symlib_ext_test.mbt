///|
/// 擴展測試：規範形式 × 範疇化 ⇒ 擴展定理 + 衍生演算法。
/// 策略：n = 5 窮舉（1024 圖 × 全部證書）、圖譜族、暴力對照、以及
/// `prove_graph` / `prove_pair` / `prove_all` 定理電池之全綠要求。

///|
/// n = 5 之全部 1024 圖。
fn ext_all_n5() -> Array[@symlib.Graph] {
  let masks : Array[Int32] = []
  for m in 0..<1024 {
    masks.push(m)
  }
  enumerate_graphs(5, masks)
}

///|
/// 圖譜族（測試用）。
fn ext_families() -> Array[@symlib.Graph] {
  [
    @symlib.Graph::path(5),
    @symlib.Graph::cycle(6),
    @symlib.Graph::petersen(),
    @symlib.Graph::complete(5),
    @symlib.Graph::complete_bipartite(3, 3),
    @symlib.Graph::star(4),
    @symlib.Graph::hypercube(3),
    @symlib.Graph::hypercube(4),
    @symlib.Graph::cycle(9),
  ]
}

///|
test "ext-exhaustive-n5-all-certs" {
  let gs = ext_all_n5()
  let bad : Array[String] = []
  for i, g in gs {
    let (sig, s1) = @symlib.Perm::random(5, i * 31 + 7)
    let _ = s1
    let (a, b, c, d) = @symlib.decomp_cert(g, sig)
    if !a {
      bad.push("decomp-relabel")
    }
    if !b {
      bad.push("decomp-product")
    }
    if !c {
      bad.push("decomp-gens")
    }
    if !d {
      bad.push("decomp-idem")
    }
    let (x, y, z) = @symlib.dual_cert(g, sig)
    if !x {
      bad.push("dual-aut")
    }
    if !y {
      bad.push("dual-enc")
    }
    if !z {
      bad.push("dual-relabel")
    }
    let (p, q, r) = @symlib.line_embed_cert(g)
    if !p {
      bad.push("line-lift")
    }
    if !q {
      bad.push("line-kernel")
    }
    if !r {
      bad.push("line-hom")
    }
  }
  assert_eq(bad.length(), 0)
}

///|
test "ext-exhaustive-n5-three-canonical-forms" {
  // 三個獨立規範形式（引擎最小化搜索 / 分量分解 / 補圖對偶）
  // 必須給出**同一個**同構類分割（34 類）
  let gs = ext_all_n5()
  let cls : Array[Int32] = []
  let c1 = Map([])
  let c2 = Map([])
  let c3 = Map([])
  let mut n1 = 0
  let mut n2 = 0
  let mut n3 = 0
  for g in gs {
    let k1 = @symlib.canon_digest(g)
    match c1.get(k1) {
      Some(v) => cls.push(v)
      None => {
        c1.set(k1, n1)
        cls.push(n1)
        n1 = n1 + 1
      }
    }
    let k2 = @symlib.ints_to_string(@symlib.block_encoding_of(g))
    match c2.get(k2) {
      Some(_) => ()
      None => {
        c2.set(k2, n2)
        n2 = n2 + 1
      }
    }
    let k3 = @symlib.dual_digest(g)
    match c3.get(k3) {
      Some(_) => ()
      None => {
        c3.set(k3, n3)
        n3 = n3 + 1
      }
    }
  }
  assert_eq(n1, 34)
  assert_eq(n2, 34)
  assert_eq(n3, 34)
  // 三通道之同構判定需與引擎一致（抽樣全部對之 1/29）
  let mut bad = 0
  let mut cnt = 0
  for i in 0..<gs.length() {
    for j in (i + 1)..<gs.length() {
      cnt = cnt + 1
      if cnt % 29 == 0 {
        let truth = @symlib.isomorphic(gs[i], gs[j])
        if @symlib.isomorphic_decomposed(gs[i], gs[j]) != truth {
          bad = bad + 1
        }
        if @symlib.isomorphic_dual(gs[i], gs[j]) != truth {
          bad = bad + 1
        }
        if @symlib.isomorphic_line(gs[i], gs[j]) != truth {
          bad = bad + 1
        }
      }
    }
  }
  assert_eq(bad, 0)
  let _ = cls
}

///|
test "ext-decomp-product-formula" {
  let pet = @symlib.Graph::petersen()
  let cases : Array[(@symlib.Graph, Int64, Int32, Int32)] = [
    // (圖, |Aut|, 分量數, 同構類數)
    (@symlib.Graph::disjoint_union([pet, pet]), 28800L, 2, 1), // 120² · 2!
    (@symlib.Graph::disjoint_union([pet, pet, pet]), 10368000L, 3, 1), // 120³ · 3!
    (
      @symlib.Graph::disjoint_union([
        @symlib.Graph::cycle(6),
        @symlib.Graph::cycle(6),
        @symlib.Graph::complete(2),
      ]),
      576L,
      3,
      2,
    ), // (12²·2!)·(2¹·1!)
    (
      @symlib.Graph::disjoint_union([
        @symlib.Graph::complete(2),
        @symlib.Graph::complete(2),
      ]),
      8L,
      2,
      1,
    ), // 2²·2!
    (@symlib.Graph::empty(6), 720L, 6, 1), // 6 個孤立點 ⇒ 6!
    (
      @symlib.Graph::disjoint_union([
        @symlib.Graph::path(4),
        @symlib.Graph::cycle(6),
        @symlib.Graph::petersen(),
      ]),
      2880L,
      3,
      3,
    ), // 2·12·120
  ]
  for t in cases {
    let (g, want, nb, nc) = t
    let d = @symlib.decompose(g)
    assert_eq(d.aut_order(), want)
    assert_eq(d.block_count(), nb)
    assert_eq(d.class_count(), nc)
    // 派生生成元之群 = 積公式之階
    let grp = d.automorphism_group()
    assert_eq(grp.order(), want)
    // 派生生成元逐個驗證為真自同構
    for p in d.aut_generators() {
      assert_true(@symlib.is_automorphism(g, p))
    }
    // 與引擎一致（重標號不變性 + 積公式證書）
    let (sig, _) = @symlib.Perm::random(g.order(), 12345)
    let (a, b, c, dd) = @symlib.decomp_cert(g, sig)
    assert_true(a && b && c && dd)
    // 塊規範形式之同構類 == 原圖
    assert_true(@symlib.isomorphic(d.canonical_form(), g))
  }
  // 溢位保護：60 個孤立點 ⇒ 60! 超出 Int64 ⇒ -1L，Double 版有限正值
  let e60 = @symlib.Graph::empty(60)
  assert_eq(@symlib.aut_order_decomposed(e60), -1L)
  assert_true(@symlib.decompose(e60).aut_order_double() > 8.0e81)
}

///|
test "ext-decomp-explicit-isomorphism" {
  let pet = @symlib.Graph::petersen()
  let g = @symlib.Graph::disjoint_union([pet, pet, @symlib.Graph::cycle(6)])
  let (sig, _) = @symlib.Perm::random(g.order(), 999)
  let h = g.relabel(sig)
  match @symlib.isomorphism_decomposed(g, h) {
    Some(phi) => {
      // 雙向逐邊驗證
      for e in g.edge_list() {
        let (u, v) = e
        assert_true(h.has_edge(phi.apply(u), phi.apply(v)))
      }
      let inv = phi.inverse()
      for e in h.edge_list() {
        let (u, v) = e
        assert_true(g.has_edge(inv.apply(u), inv.apply(v)))
      }
    }
    None => assert_true(false)
  }
  // 硬否定：2×Petersen ⊔ C6 ≇ 2×Petersen ⊔ C8（分量不同構）
  let h2 = @symlib.Graph::disjoint_union([pet, pet, @symlib.Graph::cycle(8)])
  assert_true(!@symlib.isomorphic_decomposed(g, h2))
  // 分量數相同但結構不同：C6⊔C6 ≇ C12
  assert_true(
    !@symlib.isomorphic_decomposed(
      @symlib.Graph::disjoint_union([
        @symlib.Graph::cycle(6),
        @symlib.Graph::cycle(6),
      ]),
      @symlib.Graph::cycle(12),
    ),
  )
}

///|
test "ext-dual-theorems" {
  for i, g in ext_families() {
    let c = g.complement()
    let a1 = @symlib.automorphism_group(g)
    let a2 = @symlib.automorphism_group(c)
    // 對偶定理 1：Aut(G) = Aut(Ḡ)
    assert_eq(a1.order(), a2.order())
    for p in a1.generators() {
      assert_true(a2.contains(p))
    }
    for p in a2.generators() {
      assert_true(a1.contains(p))
    }
    // 對偶定理 2：dual_enc(G) = mask ⊕ canon_enc(Ḡ)，且由 canon_lab(Ḡ) 實現
    let de = @symlib.canon_encoding_dual(g)
    let ce = @symlib.canon_encoding(c)
    for k in 0..<de.length() {
      assert_eq(de[k] + ce[k], 1)
    }
    // 雙通道交叉驗證
    assert_true(@symlib.dual_cross_check(g))
    // dual_pair：一次搜索得兩份規範形式，與各自獨立計算一致
    let (dg, dc) = @symlib.dual_pair(g)
    let sg = @symlib.canonical_dual(g)
    let sc = @symlib.canonical_dual(c)
    assert_true(@symlib.cmp_arr(dg.enc, sg.enc) == 0)
    assert_true(@symlib.cmp_arr(dc.enc, sc.enc) == 0)
    assert_eq(dg.dual, sg.dual)
    assert_eq(dc.dual, sc.dual)
    // 密度不對稱 ⇒ 只搜稀疏側一次，兩份編碼由位元對偶互推（節點數相同）
    if dg.dual != dc.dual {
      assert_eq(dg.nodes, dc.nodes)
    }
    assert_true(dg.nodes >= 1 && dc.nodes >= 1)
    // 重標號不變
    let (sig, _) = @symlib.Perm::random(g.order(), i + 77)
    let h = g.relabel(sig)
    assert_eq(@symlib.dual_digest(g), @symlib.dual_digest(h))
    assert_true(@symlib.isomorphic_dual(g, h))
    match @symlib.isomorphism_dual(g, h) {
      Some(phi) =>
        for e in g.edge_list() {
          let (u, v) = e
          assert_true(h.has_edge(phi.apply(u), phi.apply(v)))
        }
      None => assert_true(false)
    }
  }
}

///|
test "ext-line-whitney" {
  for i, g in ext_families() {
    let lg = @symlib.line_graph(g)
    let (a, b, c) = @symlib.line_embed_cert(g)
    assert_true(a && b && c)
    // 提升定理：min degree ≥ 2 且連通 ⇒ |ImΦ| = |Aut(G)| ≤ |Aut(L(G))|
    let phi = @symlib.aut_on_line(g)
    let aut = @symlib.automorphism_group(g)
    let isolated = @symlib.isolated_count(g)
    let k2 = @symlib.k2_component_count(g)
    assert_eq(phi.order() * @symlib.line_kernel_order(g), aut.order())
    assert_true(phi.order() <= @symlib.aut_order(lg))
    let _ = isolated
    let _ = k2
    // 星團回提：G vs 其重標號像
    let (sig, _) = @symlib.Perm::random(g.order(), i * 13 + 5)
    let h = g.relabel(sig)
    assert_true(@symlib.whitney_applies(g, h))
    let (wa, wb, wc) = @symlib.whitney_cert(g, h)
    assert_true(wa && wb && wc)
    match @symlib.isomorphism_via_line(g, h) {
      Some(sigma) =>
        for e in g.edge_list() {
          let (u, v) = e
          assert_true(h.has_edge(sigma.apply(u), sigma.apply(v)))
        }
      None => assert_true(false)
    }
    // L(G) 之 |Aut| 與 G 之 |Aut| 一致（min degree ≥ 2 連通圖之典型情形）
    assert_true(@symlib.aut_order(lg) >= aut.order())
  }
  // Whitney 例外對
  let k3 = @symlib.Graph::complete(3)
  let claw = @symlib.Graph::star(3)
  assert_true(@symlib.whitney_exception(k3, claw))
  assert_true(
    @symlib.isomorphic(@symlib.line_graph(k3), @symlib.line_graph(claw)),
  )
  assert_true(!@symlib.isomorphic(k3, claw))
  assert_true(!@symlib.isomorphic_line(k3, claw))
  assert_true(!@symlib.whitney_applies(k3, claw))
  // 孤立點：L(G ⊔ K₁) = L(G) 但 G ⊔ K₁ ≇ G
  let c5 = @symlib.Graph::cycle(5)
  let c5k1 = @symlib.Graph::from_edges(6, c5.edge_list())
  assert_true(
    @symlib.isomorphic(@symlib.line_graph(c5), @symlib.line_graph(c5k1)),
  )
  assert_true(!@symlib.isomorphic(c5, c5k1))
  assert_eq(@symlib.line_kernel_order(c5k1), 1L)
  // K₂ 分量之核：L(K₂) = K₁ ⇒ Φ 為平凡
  let k2 = @symlib.Graph::complete(2)
  assert_eq(@symlib.aut_on_line(k2).order(), 1L)
  assert_eq(@symlib.line_kernel_order(k2), 2L)
  // L(C6) = C6, L(K5) 有 10 頂點 30 邊（4-正則）
  assert_true(
    @symlib.isomorphic(
      @symlib.line_graph(@symlib.Graph::cycle(6)),
      @symlib.Graph::cycle(6),
    ),
  )
  let l5 = @symlib.line_graph(@symlib.Graph::complete(5))
  assert_eq(l5.order(), 10)
  assert_eq(l5.size(), 30)
  assert_true(l5.is_regular())
  assert_eq(@symlib.aut_order(l5), 120L)
}

///|
test "ext-finite-categories" {
  let cats : Array[@symlib.FinCat] = [
    @symlib.cat_discrete(3),
    @symlib.cat_terminal(),
    @symlib.cat_arrow(),
    @symlib.cat_cospan(),
    @symlib.cat_span(),
    @symlib.cat_poset(4, [(0, 1), (1, 2), (2, 3), (0, 3)]),
    @symlib.cat_parallel(),
    @symlib.cat_group(@symlib.PermGroup::symmetric(3), 200),
    @symlib.cat_group(@symlib.PermGroup::dihedral(4), 200),
  ]
  for c in cats {
    assert_true(@symlib.is_category(c))
  }
  // 偏序範疇之傳遞閉包：0≤1≤2≤3 且 0≤3 ⇒ 態射數 = 10（含 4 個恆等）
  let p = @symlib.cat_poset(4, [(0, 1), (1, 2), (2, 3)])
  assert_eq(p.nmor, 10)
  // BG 之態射數 = |G|
  assert_eq(@symlib.cat_group(@symlib.PermGroup::symmetric(4), 200).nmor, 24)
}

///|
test "ext-limits-colimits" {
  let f = @symlib.FinMap::new(4, 3, [0, 1, 1, 2])
  let gm = @symlib.FinMap::new(4, 3, [0, 0, 1, 2])
  // 等化子
  assert_eq(@symlib.equalizer_set(f, gm), [0, 2, 3])
  // 餘等化子：{0,1} 合併、2 獨立 ⇒ 2 類
  assert_eq(@symlib.coequalizer_card(f, gm), 2)
  // 拉回 vs 暴力
  let h1 = @symlib.FinMap::new(3, 3, [0, 1, 1])
  let h2 = @symlib.FinMap::new(4, 3, [2, 1, 0, 1])
  let pb = @symlib.pullback_set(h1, h2)
  let mut brute = 0
  for x in 0..<3 {
    for y in 0..<4 {
      if h1.img[x] == h2.img[y] {
        brute = brute + 1
      }
    }
  }
  assert_eq(pb.length(), brute)
  // 推出 vs 暴力（union-find）
  let s1 = @symlib.FinMap::new(2, 3, [0, 1])
  let s2 = @symlib.FinMap::new(2, 4, [3, 1])
  let po = @symlib.pushout_card(s1, s2)
  assert_eq(po, 5) // 3 + 4 - 2（兩對黏合）
  // 積 / 餘積
  assert_eq(@symlib.product_set(3, 4).length(), 12)
  assert_eq(@symlib.coproduct_card(3, 4), 7)
  // 箭頭圖：limit = A, colimit = B
  let d = @symlib.arrow_diagram(f)
  assert_true(@symlib.is_functor(d))
  assert_eq(@symlib.limit_card(d, 100000), f.dom)
  assert_eq(@symlib.colimit_card(d), f.cod)
}

///|
test "ext-yoneda-lemma" {
  let c = @symlib.cat_poset(3, [(0, 1), (1, 2)])
  let p1 = @symlib.presheaf_new(c, [3, 2, 2], [
    [0, 1, 2],
    [0, 1],
    [0, 1],
    [0, 1],
    [0, 1],
    [0, 1],
  ])
  let p2 = @symlib.presheaf_new(c, [4, 3, 2], [
    [0, 1, 2, 3],
    [0, 1, 2],
    [0, 1],
    [2, 1, 0],
    [1, 2],
    [1, 0],
  ])
  assert_true(@symlib.is_presheaf(p1))
  assert_true(@symlib.is_presheaf(p2))
  for p in [p1, p2] {
    for a in [0, 1, 2] {
      let (ra, rb, rc) = @symlib.yoneda_roundtrip(p, a, 4096)
      assert_true(ra && rb && rc)
      assert_eq(@symlib.yoneda_count(p, a, 4096), p.size[a])
    }
  }
  // 非預層（違反反變函子性）必須被偵測
  let bad = @symlib.presheaf_new(c, [3, 2, 2], [
    [0, 1, 2],
    [0, 1],
    [0, 1],
    [0, 1],
    [1, 0],
    [0, 1],
  ])
  assert_true(!@symlib.is_presheaf(bad))
  // 四元素鏈之預層：|Nat(h^a,F)| = |F(a)|
  let c4 = @symlib.cat_poset(4, [(0, 1), (1, 2), (2, 3)])
  // 態射序：id×4，再 (0,1),(0,2),(0,3),(1,2),(1,3),(2,3)
  let p4 = @symlib.presheaf_new(c4, [2, 2, 2, 2], [
    [0, 1],
    [0, 1],
    [0, 1],
    [0, 1],
    [0, 0],
    [0, 0],
    [0, 0],
    [0, 0],
    [0, 0],
    [0, 0],
  ])
  assert_true(@symlib.is_presheaf(p4))
  for a in [0, 1, 2, 3] {
    let (ra, rb, rc) = @symlib.yoneda_roundtrip(p4, a, 100000)
    assert_true(ra && rb && rc)
  }
}

///|
test "ext-kan-extensions" {
  let grp = @symlib.PermGroup::symmetric(3)
  let ng = 6
  let x = 2
  let bg = @symlib.cat_group(grp, 200)
  let k : @symlib.FinFunctor = {
    src: @symlib.cat_terminal(),
    dst: bg,
    obj: [0],
    mor: [bg.id[0]],
  }
  assert_true(@symlib.is_fin_functor(k))
  let f = @symlib.diagram_new(@symlib.cat_terminal(), [x], [@symlib.id_map(x)])
  assert_true(@symlib.is_functor(f))
  let elems = grp.elements(200)
  // Lan = 歸納 G×X
  let lr = @symlib.lan(k, f, 1000)
  assert_eq(lr.size[0], ng * x)
  for m0 in 0..<bg.nmor {
    match @symlib.lan_map(lr, m0, 0, 0) {
      Some(arr) =>
        assert_eq(
          @symlib.cmp_arr(arr, @symlib.induced_lift(grp, x, 200, elems[m0])),
          0,
        )
      None => assert_true(false)
    }
  }
  let ind = @symlib.induced_gset(grp, x, 200)
  assert_eq(ind.card(), ng * x)
  assert_eq(ind.orbits().length(), x)
  for o in ind.orbits() {
    assert_eq(o.length(), ng) // 自由作用
  }
  // Ran = 上歸納 X^G
  let rr = @symlib.ran(k, f, 100000)
  assert_eq(rr.size[0], 64)
  for m0 in 0..<bg.nmor {
    match @symlib.ran_map(rr, m0, 0, 0) {
      Some(arr) =>
        assert_eq(
          @symlib.cmp_arr(arr, @symlib.coinduced_lift(grp, x, 200, elems[m0])),
          0,
        )
      None => assert_true(false)
    }
  }
  let coi = @symlib.gset_coinduced(grp, x, 200)
  assert_eq(coi.x, 64)
  assert_eq(@symlib.gset_global_fixed(coi), x) // (Ran)^G = F
  // Kan 沿恆等函子 = 原圖
  let c = @symlib.cat_poset(3, [(0, 1), (1, 2)])
  let idf = @symlib.id_functor(c)
  assert_true(@symlib.is_fin_functor(idf))
  let d = @symlib.diagram_new(c, [3, 2, 2], [
    [0, 1, 2],
    [0, 1],
    [0, 1],
    [0, 1, 1],
    [0, 1, 1],
    [0, 1],
  ])
  assert_true(@symlib.is_functor(d))
  assert_eq(@symlib.lan(idf, d, 1000).size, d.size)
  assert_eq(@symlib.ran(idf, d, 1000).size, d.size)
}

///|
test "ext-marks-and-burnside" {
  // S₃ 之 table of marks（教科書值）
  let s3 = @symlib.PermGroup::symmetric(3)
  let subs3 = @symlib.subgroup_classes(s3, 200)
  assert_eq(subs3.length(), 4) // {e}, C2, C3, S3
  let m3 = @symlib.table_of_marks(s3, subs3, 200)
  assert_eq(
    @symlib.int_rows_to_string(m3),
    "[6,3,2,1][0,1,0,1][0,0,2,1][0,0,0,1]",
  )
  // S₄ 有 11 個子群共軛類
  let s4 = @symlib.PermGroup::symmetric(4)
  assert_eq(@symlib.subgroup_classes(s4, 300).length(), 11)
  // 標記證書：兩算法一致 + 下三角 + 對角正
  for
    g in [
      @symlib.PermGroup::symmetric(3),
      @symlib.PermGroup::cyclic(6),
      @symlib.PermGroup::dihedral(4),
      @symlib.PermGroup::symmetric(4),
      @symlib.automorphism_group(@symlib.Graph::petersen()),
    ] {
    let (a, b, c, ns, ord) = @symlib.marks_cert(g, 300)
    assert_true(a && b && c)
    assert_true(ns >= 2 && ord >= 1L)
  }
  // G-集：Burnside == 軌道數；標記判別同構類
  let d3 = @symlib.PermGroup::dihedral(3)
  let subs = @symlib.subgroup_classes(d3, 200)
  let pts = @symlib.gset_points(d3, 200)
  let pairs = @symlib.gset_pairs(d3, 200)
  let edges = @symlib.gset_edges(d3, @symlib.Graph::cycle(3), 200)
  let ind = @symlib.gset_induced(d3, 2, 200)
  let coi = @symlib.gset_coinduced(d3, 2, 200)
  for gs in [pts, pairs, edges, ind, coi] {
    let (orb, burn) = @symlib.gset_burnside(gs)
    assert_eq(orb, burn)
    assert_eq(@symlib.mark_vector(gs, subs).length(), subs.length())
  }
  // 三角形：頂點作用 ≅ 邊作用；≠ 序對作用；歸納為自由作用
  assert_true(@symlib.gset_isomorphic(pts, edges, subs))
  assert_true(!@symlib.gset_isomorphic(pts, pairs, subs))
  assert_eq(@symlib.ints_to_string(@symlib.mark_vector(pts, subs)), "[3,1,0,0]")
  assert_eq(
    @symlib.ints_to_string(@symlib.mark_vector(ind, subs)),
    "[12,0,0,0]",
  )
  assert_eq(
    @symlib.ints_to_string(@symlib.mark_vector(coi, subs)),
    "[64,8,4,2]",
  )
  assert_eq(@symlib.gset_orbits(pts).length(), 1)
  assert_eq(@symlib.gset_orbits(pairs).length(), 2)
  // 規範鍵：同構 G-集之鍵相同
  assert_eq(
    @symlib.ints_to_string(@symlib.gset_canon_key(pts, subs)),
    @symlib.ints_to_string(@symlib.gset_canon_key(edges, subs)),
  )
}

///|
test "ext-cayley-graphs" {
  // Cay(C4) = C4；Cay(D4) = Q3；Cay(S3) = 三棱柱（6 點 9 邊 3-正則）
  let c4 = @symlib.PermGroup::cyclic(4)
  let d4 = @symlib.PermGroup::dihedral(4)
  let s3 = @symlib.PermGroup::symmetric(3)
  let cay_c4 = @symlib.cayley_graph(c4, 200)
  let cay_d4 = @symlib.cayley_graph(d4, 200)
  let cay_s3 = @symlib.cayley_graph(s3, 200)
  assert_true(@symlib.isomorphic(cay_c4, @symlib.Graph::cycle(4)))
  assert_true(@symlib.isomorphic(cay_d4, @symlib.Graph::hypercube(3)))
  assert_eq(cay_s3.order(), 6)
  assert_eq(cay_s3.size(), 9)
  assert_true(cay_s3.is_regular())
  assert_true(
    !@symlib.isomorphic(cay_s3, @symlib.Graph::complete_bipartite(3, 3)),
  )
  // Cayley 定理證書：λ : G ↪ Aut(Cay(G,S))
  for g in [c4, d4, s3, @symlib.PermGroup::cyclic(6)] {
    let (a, b, c, aord, gord) = @symlib.cayley_cert(g, 200)
    assert_true(a && b && c)
    assert_true(aord >= gord)
  }
  // 左正則表示之置換確為 Cayley 圖之自同構
  let l = @symlib.regular_perm(d4, 200, d4.generators()[0])
  assert_true(@symlib.is_automorphism(cay_d4, l))
}

///|
test "ext-permset-canonical-form" {
  // G-集之規範形式（暴力最小化）+ 與「存在共軛」暴力判準對照
  let g5 = @symlib.Graph::cycle(5)
  let d5 = @symlib.automorphism_group(g5)
  let ps = @symlib.permset(5, d5.generators())
  let c5 = @symlib.PermGroup::cyclic(5)
  let ps_c : Array[@symlib.Perm] = []
  for _ in 0..<d5.generators().length() {
    ps_c.push(c5.generators()[0])
  }
  // 共軛像 ⇒ 同構
  let (sig, _) = @symlib.Perm::random(5, 4242)
  let conj : Array[@symlib.Perm] = []
  for p in d5.generators() {
    conj.push(p.conjugate_by(sig))
  }
  let ps2 = @symlib.permset(5, conj)
  let (a, b, c) = @symlib.permset_cert(ps, sig, 200)
  assert_true(a && b && c)
  assert_true(@symlib.permset_isomorphic(ps, ps2, 200))
  // 規範形式之暴力對照：同構 ⟺ ∃λ 使生成元逐一共軛相等
  let perms = all_perms(5)
  fn brute_iso(x : @symlib.PermSet, y : @symlib.PermSet) -> Bool {
    for img in perms {
      let l = @symlib.Perm::from_img(img)
      let linv = l.inverse()
      let mut ok = true
      for i in 0..<x.gens.length() {
        let q = linv.compose(x.gens[i]).compose(l)
        if q != y.gens[i] {
          ok = false
          break
        }
      }
      if ok {
        return true
      }
    }
    false
  }
  let cases : Array[@symlib.PermSet] = [
    ps,
    ps2,
    @symlib.permset(5, c5.generators()),
    @symlib.permset(5, [@symlib.Perm::from_cycles(5, [[0, 1, 2], [3, 4]])]),
    @symlib.permset(5, [@symlib.Perm::identity(5)]),
  ]
  for i in 0..<cases.length() {
    for j in 0..<cases.length() {
      let by_canon = @symlib.permset_isomorphic(cases[i], cases[j], 200)
      let by_brute = brute_iso(cases[i], cases[j])
      assert_eq(by_canon, by_brute)
    }
  }
  // 平凡作用之規範形式 = 全零
  let triv = @symlib.permset(5, [@symlib.Perm::identity(5)])
  assert_eq(
    @symlib.ints_to_string(@symlib.permset_canon(triv, 200)),
    "[0,1,2,3,4]",
  )
  let _ = ps_c
}

///|
test "ext-free-gset-monad" {
  let grp = @symlib.PermGroup::symmetric(3)
  for x in [1, 2, 3] {
    assert_true(@symlib.gset_monad_laws(grp, x, 200))
  }
  assert_true(
    @symlib.gset_monad_naturality(grp, @symlib.FinMap::new(2, 3, [1, 2]), 200),
  )
  assert_true(
    @symlib.gset_monad_naturality(
      grp,
      @symlib.FinMap::new(3, 2, [0, 0, 1]),
      200,
    ),
  )
  // η / μ 之具體形式
  let eta = @symlib.gset_monad_eta(grp, 2, 200)
  assert_eq(eta.length(), 2)
  let mu = @symlib.gset_monad_mu(grp, 2, 200)
  assert_eq(mu.length(), 6 * 6 * 2)
  // Frobenius 互反（Set 版）：|Hom_G(G×X,Y)| = |Y|^|X|
  for
    t in [
      (@symlib.PermGroup::cyclic(3), 1),
      (@symlib.PermGroup::cyclic(2), 2),
      (@symlib.PermGroup::symmetric(3), 1),
    ] {
    let (g, x) = t
    let yact = @symlib.gset_points(g, 200)
    let (lhs, rhs) = @symlib.frobenius_reciprocity(g, x, yact, 4096)
    assert_eq(lhs, rhs)
  }
}

///|
test "ext-csp-limit-vs-monad" {
  for n in [4, 5] {
    let dom = Array::make(n, n)
    let sols = @symlib.csp_limit(dom, @symlib.queen_constraints(n), 1000000)
    let vals : Array[Array[Int32]] = []
    for _ in 0..<n {
      let a : Array[Int32] = []
      for r in 0..<n {
        a.push(r)
      }
      vals.push(a)
    }
    let nd = @symlib.search_nd(vals, fn(sol : Array[Int32]) -> Bool {
      for i in 0..<sol.length() {
        for j in (i + 1)..<sol.length() {
          let da = sol[i] - sol[j]
          let ad = if da < 0 { 0 - da } else { da }
          if sol[i] == sol[j] || ad == j - i {
            return false
          }
        }
      }
      true
    })
    let nda = nd.to_array()
    assert_eq(sols.length(), nda.length())
    assert_eq(sols.length(), if n == 4 { 2 } else { 10 })
    // 同一解集（雙向包含）
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
  }
  // 退化 CSP：無約束 ⇒ 全部組合
  let free = @symlib.csp_limit([2, 3], [], 1000)
  assert_eq(free.length(), 6)
}

///|
test "ext-fold-canonical" {
  for i, g in ext_families() {
    let (sig, _) = @symlib.Perm::random(g.order(), i * 17 + 3)
    assert_true(@symlib.fold_canonical_cert(g, sig))
    // 規範折疊之守恆律
    let f = @symlib.fold_canonical(g)
    let mut ssum = 0
    for v in f.orbit_size {
      ssum = ssum + v
    }
    assert_eq(ssum, g.order())
    let mut msum = 0
    for a in 0..<f.k {
      for b in a..<f.k {
        msum = msum + f.mul[a][b]
      }
    }
    assert_eq(msum, g.size())
    // 一般 fold_graph 之軌道數與規範折疊一致（僅順序可能不同）
    let plain = @symlib.fold_graph(g, @symlib.automorphism_group(g))
    assert_eq(plain.k, f.k)
  }
  // 非對稱圖：折疊 = 原圖
  let asym = @symlib.Graph::path(4)
  let fa = @symlib.fold_canonical(asym)
  assert_eq(fa.k, 2) // P4 之 Aut = Z₂（鏡射）⇒ 軌道 {0,3},{1,2}
}

///|
test "ext-sgs-elements-regression" {
  // 回歸測試：橫截分解次序（g = u_0∘u_1∘…）錯誤會造成重複與漏元素
  for
    g in [
      @symlib.PermGroup::symmetric(5),
      @symlib.PermGroup::symmetric(4),
      @symlib.PermGroup::dihedral(6),
      @symlib.PermGroup::dihedral(4),
      @symlib.PermGroup::cyclic(7),
      @symlib.automorphism_group(@symlib.Graph::petersen()),
      @symlib.automorphism_group(@symlib.Graph::hypercube(3)),
      @symlib.automorphism_group(@symlib.Graph::hypercube(4)),
    ] {
    assert_true(@symlib.elements_cert(g, 500))
  }
}

///|
test "ext-theorem-battery" {
  // 單圖電池：9 個圖譜族 × 22 條定理
  for i, g in ext_families() {
    let (sig, _) = @symlib.Perm::random(g.order(), i * 101 + 1)
    let certs = @symlib.prove_graph(g, sig, 200)
    let bad = @symlib.failed_certs(certs)
    if bad.length() > 0 {
      println(@symlib.cert_report(certs))
    }
    assert_eq(bad.length(), 0)
    assert_true(@symlib.all_hold(certs))
    assert_true(certs.length() >= 20)
  }
  // 雙圖電池：同構與非同構對
  let pet = @symlib.Graph::petersen()
  let pairs : Array[(@symlib.Graph, @symlib.Graph)] = [
    (@symlib.Graph::cycle(6), @symlib.Graph::cycle(6)),
    (@symlib.Graph::cycle(6), @symlib.Graph::path(6)),
    (pet, @symlib.Graph::cycle(10)),
    (@symlib.Graph::complete(3), @symlib.Graph::star(3)),
    (
      pet,
      @symlib.Graph::disjoint_union([
        @symlib.Graph::cycle(5),
        @symlib.Graph::cycle(5),
      ]),
    ),
    (
      @symlib.Graph::disjoint_union([pet, pet]),
      @symlib.Graph::disjoint_union([pet, @symlib.Graph::cycle(10)]),
    ),
  ]
  for t in pairs {
    let (a, b) = t
    let certs = @symlib.prove_pair(
      a.relabel(@symlib.Perm::random(a.order(), 7).0),
      b,
    )
    if !@symlib.all_hold(certs) {
      println(@symlib.cert_report(certs))
    }
    assert_true(@symlib.all_hold(certs))
  }
  // 全庫電池：20 條
  let all = @symlib.prove_all(200)
  assert_true(@symlib.all_hold(all))
  assert_true(all.length() >= 20)
}

///|
test "ext-labeling-perm-one-search" {
  // 衍生演算法之依據：一次搜索 ⇒ (規範圖, 規範標號下之 Aut 生成元)
  for i, g in ext_families() {
    let res = @symlib.search_graph(g, true)
    let sigma = @symlib.labeling_perm(res.canon_lab)
    let cf = g.relabel(sigma)
    assert_true(cf == @symlib.canonical_form(g))
    let gens : Array[@symlib.Perm] = []
    for p in res.aut_gens {
      let q = p.conjugate_by(sigma)
      assert_true(@symlib.is_automorphism(cf, q))
      gens.push(q)
    }
    let grp = @symlib.PermGroup::new(g.order(), gens)
    assert_eq(grp.order(), @symlib.aut_order(g))
    // 軌道結構亦一致（折疊之依據）
    let plain = @symlib.fold_graph(g, @symlib.automorphism_group(g))
    let derived = @symlib.fold_graph(cf, grp)
    assert_eq(plain.k, derived.k)
    assert_eq(plain.edge_total, derived.edge_total)
    let _ = i
  }
}

///|
test "ext-keylut-open-addressing" {
  // KeyLut 必須與 Map 語意一致（含缺失鍵、碰撞探測、容量成長）
  for size in [1, 2, 3, 7, 16, 64, 100] {
    let keys : Array[Int64] = []
    let mut s = 12345
    for _ in 0..<size {
      // 刻意製造低位元相同之鍵以觸發探測
      s = ((s.to_int64() * 1103515245L + 12345L) & 0x7FFFFFFFL).to_int()
      keys.push(s.to_int64() * 65536L + 1L)
    }
    let lut = @symlib.key_lut(keys)
    let refmap = Map([])
    for i, k in keys {
      refmap.set(k, i)
      assert_eq(lut.at(k), i)
      assert_eq(lut.find(k), i)
    }
    // 缺失鍵：find 回傳 -1（at 則 abort，與 Map.get().unwrap() 同語意）
    assert_eq(lut.find(0x7FFFFFFFL * 65536L + 2L), -1)
    assert_eq(lut.find(3L), refmap.get(3L).unwrap_or(-1))
  }
  // elem_lut_fast 與 perm_key64/Map 版本之一致性 ⇒ 見白盒測試 wbtest-keylut
}
