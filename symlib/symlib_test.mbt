///|
/// 黑盒測試：symlib 公共 API 的正確性。
/// 核心策略：小圖（n ≤ 5）窮舉 × 暴力法對照；n = 6,7 隨機抽樣對照；
/// 經典圖譜已知 |Aut| 值；重標號不變性；範疇/單子定律。

///|
/// 列舉 {0..n-1} 的全部置換（像陣列表示；n ≤ 7 用）。
fn all_perms(n : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let cur = Array::make(n, 0)
  let used = Array::make(n, false)
  fn rec(d : Int32) -> Unit {
    if d == n {
      out.push(cur.copy())
      return
    }
    for v in 0..<n {
      if !used[v] {
        used[v] = true
        cur[d] = v
        rec(d + 1)
        used[v] = false
      }
    }
  }
  rec(0)
  out
}

///|
/// 暴力自同構計數。
fn brute_aut_count(g : @symlib.Graph, perms : Array[Array[Int32]]) -> Int32 {
  let n = g.order()
  let mut c = 0
  for p in perms {
    let mut ok = true
    for u in 0..<n {
      for v in (u + 1)..<n {
        if g.has_edge(u, v) != g.has_edge(p[u], p[v]) {
          ok = false
          break
        }
      }
      if !ok {
        break
      }
    }
    if ok {
      c = c + 1
    }
  }
  c
}

///|
/// 暴力全局最小編碼（列主序，與引擎同布局）。
fn brute_min_enc(
  g : @symlib.Graph,
  perms : Array[Array[Int32]],
) -> Array[Int32] {
  let n = g.order()
  let mut best : Array[Int32] = []
  for p in perms {
    let enc : Array[Int32] = []
    for j in 1..<n {
      for i in 0..<j {
        enc.push(if g.has_edge(p[i], p[j]) { 1 } else { 0 })
      }
    }
    if best.length() == 0 || @symlib.cmp_arr(enc, best) < 0 {
      best = enc
    }
  }
  best
}

///|
/// 編碼 → 字串鍵。
fn enc_key(enc : Array[Int32]) -> String {
  let mut s = ""
  for b in enc {
    s = s + b.to_string()
  }
  s
}

///|
/// n 頂點全部無向圖的邊列表（按位遮罩枚舉）。
fn enumerate_graphs(n : Int32, masks : Array[Int32]) -> Array[@symlib.Graph] {
  let pairs : Array[(Int32, Int32)] = []
  for u in 0..<n {
    for v in (u + 1)..<n {
      pairs.push((u, v))
    }
  }
  let out : Array[@symlib.Graph] = []
  for mask in masks {
    let edges : Array[(Int32, Int32)] = []
    for i, _ in pairs {
      if (mask & (1 << i)) != 0 {
        edges.push(pairs[i])
      }
    }
    out.push(@symlib.Graph::from_edges(n, edges))
  }
  out
}

///|
test "bitvec-ops" {
  let bv = @symlib.BitVec::make(130)
  bv.set(0)
  bv.set(63)
  bv.set(64)
  bv.set(129)
  assert_eq(bv.count_ones(), 4)
  assert_eq(bv.to_array(), [0, 63, 64, 129])
  let full = @symlib.BitVec::make_full(130)
  assert_eq(full.count_ones(), 130)
  let cp = full.copy()
  cp.and_not_in_place(bv)
  assert_eq(cp.count_ones(), 126)
  cp.and_in_place(bv)
  assert_eq(cp.count_ones(), 0)
  assert_true(cp.is_empty())
  cp.or_in_place(bv)
  assert_true(cp.equal(bv))
  assert_true(bv.contains(@symlib.BitVec::make(130)))
}

///|
test "perm-algebra" {
  let a = @symlib.Perm::from_cycles(5, [[0, 1, 2]])
  let b = @symlib.Perm::from_cycles(5, [[2, 3]])
  let ab = a.compose(b) // 先 b 後 a：ab(3) = a(b(3)) = a(2) = 0；ab(2) = a(3) = 3
  assert_eq(ab.apply(3), 0)
  assert_eq(ab.apply(2), 3)
  let inv = ab.inverse()
  assert_true(ab.compose(inv).is_identity())
  assert_eq(a.order(), 3)
  assert_eq(a.pow(3).is_identity(), true)
  assert_eq(a.pow(-1).apply(1), 0)
  assert_eq(a.sign(), 1) // 3-輪 = 偶
  assert_eq(b.sign(), -1) // 對換 = 奇
  let conj = a.conjugate_by(b)
  assert_eq(conj.nontrivial_cycles().length(), 1)
  assert_eq(b.orbit_of(2), [2, 3])
}

///|
test "group-known-orders" {
  assert_eq(@symlib.PermGroup::symmetric(5).order(), 120L)
  assert_eq(@symlib.PermGroup::symmetric(6).order(), 720L)
  assert_eq(@symlib.PermGroup::cyclic(7).order(), 7L)
  assert_eq(@symlib.PermGroup::dihedral(6).order(), 12L)
  assert_eq(@symlib.PermGroup::trivial(5).order(), 1L)
}

///|
test "sgs-elements-match-order" {
  let s5 = @symlib.PermGroup::symmetric(5)
  let elems = s5.elements(200)
  assert_eq(elems.length(), 120)
  // 唯一性：全部元素互異且都在群內（橫截分解 g = u_0∘u_1∘… 之次序必須正確，
  // 次序反轉會產生重複且漏元素 ⇒ 此處必須逐對比較）
  for i in 0..<elems.length() {
    assert_true(s5.contains(elems[i]))
    for j in (i + 1)..<elems.length() {
      assert_true(elems[i] != elems[j])
    }
  }
  // 乘法封閉（抽樣）
  for i in 0..<12 {
    for j in 0..<12 {
      assert_true(s5.contains(elems[i].compose(elems[j])))
    }
  }
  let d6 = @symlib.PermGroup::dihedral(6)
  assert_eq(d6.elements(50).length(), 12)
}

///|
test "group-contains-and-stabilizer" {
  let d6 = @symlib.PermGroup::dihedral(6)
  assert_true(d6.contains(@symlib.Perm::identity(6)))
  let rot = @symlib.Perm::from_cycles(6, [[0, 1, 2, 3, 4, 5]])
  assert_true(d6.contains(rot))
  let not_sym = @symlib.Perm::from_cycles(6, [[0, 1]])
  assert_true(!d6.contains(not_sym))
  // 軌道-穩定子定理：|G_x| · |Orb(x)| = |G|
  let st = d6.stabilizer(0)
  assert_eq(st.order() * d6.orbit(0).length().to_int64(), d6.order())
  assert_true(d6.is_transitive())
  // 逐點穩定子
  let st01 = d6.pointwise_stabilizer([0, 1])
  assert_eq(st01.order(), 1L)
}

///|
test "aut-known-families" {
  // |Aut| 已知值：K_n = n!, C_n = 2n, P_n = 2, Q_k = 2^k·k!, Petersen = 120
  assert_eq(@symlib.aut_order(@symlib.Graph::complete(6)), 720L)
  assert_eq(@symlib.aut_order(@symlib.Graph::cycle(7)), 14L)
  assert_eq(@symlib.aut_order(@symlib.Graph::path(9)), 2L)
  assert_eq(@symlib.aut_order(@symlib.Graph::hypercube(4)), 384L)
  assert_eq(@symlib.aut_order(@symlib.Graph::petersen()), 120L)
  assert_eq(@symlib.aut_order(@symlib.Graph::empty(5)), 120L)
  assert_eq(@symlib.aut_order(@symlib.Graph::star(5)), 120L)
  assert_eq(@symlib.aut_order(@symlib.Graph::complete_bipartite(3, 3)), 72L)
  assert_true(@symlib.is_vertex_transitive(@symlib.Graph::petersen()))
  assert_true(@symlib.is_edge_transitive(@symlib.Graph::petersen()))
  assert_true(!@symlib.is_vertex_transitive(@symlib.Graph::path(5)))
  assert_true(!@symlib.is_asymmetric(@symlib.Graph::cycle(5)))
}

///|
test "exhaustive-n5-aut-vs-brute" {
  // 5 頂點全部 1024 個圖：引擎 |Aut| == 暴力計數
  let perms5 = all_perms(5)
  let masks : Array[Int32] = []
  for m in 0..<1024 {
    masks.push(m)
  }
  for g in enumerate_graphs(5, masks) {
    let engine = @symlib.aut_order(g)
    let brute = brute_aut_count(g, perms5).to_int64()
    assert_eq(engine, brute)
  }
}

///|
test "exhaustive-n5-canon-classes" {
  // 引擎規範指紋之分類 == 暴力全局最小編碼之分類（雙射）
  let perms5 = all_perms(5)
  let brute_to_engine : Map[String, String] = Map([])
  let engine_to_brute : Map[String, String] = Map([])
  let masks : Array[Int32] = []
  for m in 0..<1024 {
    masks.push(m)
  }
  for g in enumerate_graphs(5, masks) {
    let bk = enc_key(brute_min_enc(g, perms5))
    let ek = @symlib.canon_digest(g)
    match brute_to_engine.get(bk) {
      Some(prev) => assert_eq(prev, ek)
      None => brute_to_engine.set(bk, ek)
    }
    match engine_to_brute.get(ek) {
      Some(prev) => assert_eq(prev, bk)
      None => engine_to_brute.set(ek, bk)
    }
  }
  assert_eq(brute_to_engine.length(), engine_to_brute.length())
}

///|
test "random-n6-n7-aut-vs-brute" {
  let perms6 = all_perms(6)
  let perms7 = all_perms(7)
  let mut seed = 42
  for _ in 0..<25 {
    let (g6, s1) = @symlib.Graph::random(6, 50, seed)
    seed = s1
    assert_eq(@symlib.aut_order(g6), brute_aut_count(g6, perms6).to_int64())
  }
  for _ in 0..<12 {
    let (g7, s1) = @symlib.Graph::random(7, 40, seed)
    seed = s1
    assert_eq(@symlib.aut_order(g7), brute_aut_count(g7, perms7).to_int64())
  }
}

///|
test "canon-relabel-invariance" {
  let graphs : Array[@symlib.Graph] = [
    @symlib.Graph::petersen(),
    @symlib.Graph::cycle(9),
    @symlib.Graph::hypercube(4),
    @symlib.Graph::complete_bipartite(3, 4),
    @symlib.Graph::path(8),
    @symlib.Graph::star(6),
  ]
  let mut seed = 1234
  for g in graphs {
    let d0 = @symlib.canon_digest(g)
    for _ in 0..<5 {
      let (sigma, s1) = @symlib.Perm::random(g.order(), seed)
      seed = s1
      let g2 = g.relabel(sigma)
      assert_eq(@symlib.canon_digest(g2), d0)
      assert_true(@symlib.isomorphic(g, g2))
      match @symlib.isomorphism(g, g2) {
        Some(_) => ()
        None => abort("expected isomorphism")
      }
    }
  }
}

///|
test "isomorphism-hard-negative" {
  // Petersen vs C10：同為 3/2-正則、同頂點邊數 — 度序列法無法區分
  assert_true(
    !@symlib.isomorphic(@symlib.Graph::petersen(), @symlib.Graph::cycle(10)),
  )
  // C6 vs 2×C3：同度序列同 WL 顏色 — 需完整規範形式
  let c6 = @symlib.Graph::cycle(6)
  let two_c3 = @symlib.Graph::from_edges(6, [
    (0, 1),
    (1, 2),
    (2, 0),
    (3, 4),
    (4, 5),
    (5, 3),
  ])
  assert_eq(@symlib.graph_invariant(c6), @symlib.graph_invariant(two_c3))
  assert_true(!@symlib.isomorphic(c6, two_c3))
  // C8 vs 2×C4
  let c8 = @symlib.Graph::cycle(8)
  let two_c4 = @symlib.Graph::from_edges(8, [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 0),
    (4, 5),
    (5, 6),
    (6, 7),
    (7, 4),
  ])
  assert_true(!@symlib.isomorphic(c8, two_c4))
  assert_true(
    @symlib.isomorphic(
      two_c4,
      two_c4.relabel(@symlib.Perm::from_cycles(8, [[0, 4, 1, 5, 2, 6, 3, 7]])),
    ),
  )
  // 自同構判定
  let rot = @symlib.Perm::from_cycles(6, [[0, 1, 2, 3, 4, 5]])
  assert_true(@symlib.is_automorphism(c6, rot))
  assert_true(
    !@symlib.is_automorphism(c6, @symlib.Perm::from_cycles(6, [[0, 1]])),
  )
}

///|
test "canonical-form-is-relabeled-graph" {
  let g = @symlib.Graph::petersen()
  let cf = @symlib.canonical_form(g)
  assert_eq(cf.order(), 10)
  assert_eq(cf.size(), 15)
  assert_true(@symlib.isomorphic(g, cf))
  // 規範形式之規範形式 = 自身（冪等）
  let cf2 = @symlib.canonical_form(cf)
  assert_eq(@symlib.canon_digest(cf2), @symlib.canon_digest(cf))
  assert_true(cf == cf2)
}

///|
test "action-orbits-and-burnside" {
  let c6 = @symlib.Graph::cycle(6)
  let grp = @symlib.automorphism_group(c6)
  let act = @symlib.FinAction::of_group(grp)
  assert_eq(act.orbit_count(), 1)
  assert_true(act.is_transitive())
  // Burnside：#軌道 = 平均不動點數
  assert_eq(act.burnside_orbit_count(grp, 100), 1)
  // 序對作用：C6 之 D6 在 36 個序對上 → 軌道數
  let pairs = @symlib.FinAction::on_pairs(grp)
  assert_eq(pairs.card(), 36)
  assert_eq(pairs.orbit_count(), pairs.burnside_orbit_count(grp, 100))
  // P5：頂點軌道 = 3（{0,4},{1,3},{2}）
  let p5 = @symlib.Graph::path(5)
  let act5 = @symlib.FinAction::of_group(@symlib.automorphism_group(p5))
  assert_eq(act5.orbit_count(), 3)
  // 軌道按代表元升序編號：{0,4}→0, {1,3}→1, {2}→2
  assert_eq(act5.orbit_of(), [0, 1, 2, 1, 0])
  assert_eq(act5.fundamental_domain(), [0, 1, 2])
}

///|
test "edge-orbits-conservation" {
  let p5 = @symlib.Graph::path(5)
  let (reps, sizes) = @symlib.edge_orbits(p5)
  assert_eq(reps.length(), 2)
  let mut total = 0
  for s in sizes {
    total = total + s
  }
  assert_eq(total, p5.size()) // 邊軌道分割全部邊
  let pet = @symlib.Graph::petersen()
  let (reps2, sizes2) = @symlib.edge_orbits(pet)
  assert_eq(reps2.length(), 1)
  assert_eq(sizes2[0], 15)
}

///|
test "fold-conservation" {
  let graphs : Array[@symlib.Graph] = [
    @symlib.Graph::petersen(),
    @symlib.Graph::cycle(8),
    @symlib.Graph::path(7),
    @symlib.Graph::hypercube(3),
    @symlib.Graph::complete_bipartite(2, 3),
  ]
  for g in graphs {
    let grp = @symlib.automorphism_group(g)
    let f = @symlib.fold_graph(g, grp)
    // 軌道大小和 = n
    let mut vsum = 0
    for s in f.orbit_size {
      vsum = vsum + s
    }
    assert_eq(vsum, g.order())
    // 邊重數和 = m
    let mut esum = 0
    for i in 0..<f.k {
      for j in i..<f.k {
        esum = esum + f.multiplicity(i, j)
      }
    }
    assert_eq(esum, g.size())
    assert_eq(f.edge_total, g.size())
    // 可遷圖 ⇒ 單點商
    if grp.is_transitive() {
      assert_true(f.is_single_orbit())
      assert_eq(f.rep.length(), 1)
    }
    assert_true(f.ratio() <= 1.0)
  }
}

///|
test "fold-candidates-prunes-search-space" {
  // 搜索空間折疊：候選集在 Aut 下之軌道代表
  let c6 = @symlib.Graph::cycle(6)
  let grp = @symlib.automorphism_group(c6)
  let pts = [0, 1, 2, 3, 4, 5]
  let (reps, ratio) = @symlib.fold_candidates(grp, pts)
  assert_eq(reps.length(), 1) // 可遷 ⇒ 折疊為單點
  assert_true(ratio < 0.2)
  let dom = @symlib.fundamental_domain(grp, pts)
  assert_eq(dom, [0])
  // 子集折疊
  let (reps2, _) = @symlib.fold_candidates(grp, [0, 1, 2])
  assert_eq(reps2.length(), 1)
}

///|
test "list-monad-laws" {
  let f = fn(x : Int32) -> @symlib.ListM[Int32] {
    @symlib.ListM::from_array([x, x + 10])
  }
  let g = fn(x : Int32) -> @symlib.ListM[Int32] {
    @symlib.ListM::from_array([x * 2])
  }
  // 左單位：pure(a) >>= f == f(a)
  assert_eq(@symlib.ListM::pure(3).bind(f).to_array(), f(3).to_array())
  // 右單位：m >>= pure == m
  let m = @symlib.ListM::from_array([1, 2, 3])
  assert_eq(m.bind(fn(x) { @symlib.ListM::pure(x) }).to_array(), m.to_array())
  // 結合律：(m >>= f) >>= g == m >>= (f >=> g)
  assert_eq(
    m.bind(f).bind(g).to_array(),
    m.bind(@symlib.kleisli_list(f, g)).to_array(),
  )
  // mplus / filter / guard / fold
  assert_eq(m.mplus(@symlib.ListM::pure(4)).to_array(), [1, 2, 3, 4])
  assert_eq(m.filter(fn(x) { x % 2 == 1 }).to_array(), [1, 3])
  assert_eq(@symlib.nd_guard(true).to_array().length(), 1)
  assert_eq(@symlib.nd_guard(false).to_array().length(), 0)
  assert_eq(m.fold(0, fn(acc, x) { acc + x }), 6)
  assert_eq(m.map(fn(x) { x + 1 }).to_array(), [2, 3, 4])
}

///|
test "state-option-monad-laws" {
  let f = fn(x : Int32) -> @symlib.StateM[Int32, Int32] {
    @symlib.StateM::modify(fn(s) { s + x }).bind(fn(_) {
      @symlib.StateM::pure(x * 2)
    })
  }
  let g = fn(x : Int32) -> @symlib.StateM[Int32, Int32] {
    @symlib.StateM::pure(x + 1)
  }
  // 左單位
  assert_eq(@symlib.StateM::pure(5).bind(f).eval(0), f(5).eval(0))
  assert_eq(@symlib.StateM::pure(5).bind(f).exec(0), f(5).exec(0))
  // 右單位
  let m : @symlib.StateM[Int32, Int32] = @symlib.StateM::pure(7)
  assert_eq(m.bind(fn(x) { @symlib.StateM::pure(x) }).eval(3), m.eval(3))
  // 結合律
  assert_eq(
    m.bind(f).bind(g).eval(0),
    m.bind(@symlib.kleisli_state(f, g)).eval(0),
  )
  // get / put
  let prog : @symlib.StateM[Int32, Int32] = @symlib.StateM::put(9).bind(fn(_) {
    @symlib.StateM::get()
  })
  assert_eq(prog.eval(0), 9)
  // Option 單子
  assert_eq(@symlib.opt_bind(Some(3), fn(x) { Some(x + 1) }), Some(4))
  assert_eq(@symlib.opt_bind(None, fn(x) { Some(x + 1) }), None)
  assert_eq(@symlib.opt_pure(2), Some(2))
}

///|
test "search-nd-monadic-backtracking" {
  // 非決定性搜索：4 皇后之單子式回溯（候選 = 每列可行位置）
  let cands : Array[Array[Int32]] = [
    [0, 1, 2, 3],
    [0, 1, 2, 3],
    [0, 1, 2, 3],
    [0, 1, 2, 3],
  ]
  let sols = @symlib.search_nd(cands, fn(q) {
    // 對角線衝突檢查
    for i in 0..<4 {
      for j in (i + 1)..<4 {
        if q[i] == q[j] || (q[i] - q[j]).abs() == (i - j).abs() {
          return false
        }
      }
    }
    true
  })
  assert_eq(sols.to_array().length(), 2) // 4 皇后有 2 解
}

///|
test "finset-category-laws" {
  let f = @symlib.FinMap::new(3, 4, [1, 2, 3])
  let g = @symlib.FinMap::new(4, 3, [0, 1, 2, 0])
  let h = @symlib.FinMap::new(3, 3, [2, 0, 1])
  // 恆等律
  assert_true(f.compose(@symlib.FinMap::id(3)).equal(f))
  assert_true(@symlib.FinMap::id(4).compose(f).equal(f))
  // 結合律
  let i3 = @symlib.FinMap::id(3)
  assert_true(h.compose(g).compose(f).equal(h.compose(g.compose(f))))
  assert_true(i3.compose(i3).equal(i3))
  // 單射/滿射/同構
  assert_true(f.is_mono())
  assert_true(!f.is_epi())
  assert_true(h.is_iso())
  assert_true(h.compose(h.inverse()).equal(@symlib.FinMap::id(3)))
  assert_true(!g.is_mono())
  assert_true(g.is_epi())
}

///|
test "powerset-monad-laws-and-naturality" {
  // 單子律（FinSet 層面，n = 0..3）
  for n in 0..<=3 {
    assert_true(@symlib.pow_monad_laws(n))
  }
  // 自然性：μ_Y ∘ P(P(f)) = P(f) ∘ μ_X
  let fs : Array[@symlib.FinMap] = [
    @symlib.FinMap::new(3, 3, [1, 2, 0]),
    @symlib.FinMap::new(2, 3, [2, 0]),
    @symlib.FinMap::new(3, 2, [0, 1, 1]),
    @symlib.FinMap::id(3),
  ]
  for f in fs {
    assert_true(@symlib.pow_naturality(f))
  }
  // P 保持恆等與複合（函子律）：P(f ∘ g) = P(f) ∘ P(g)
  let pf = @symlib.pow_fmap(fs[0])
  assert_true(pf.compose(@symlib.pow_fmap(@symlib.FinMap::id(3))).equal(pf))
  let f2 = @symlib.FinMap::new(3, 2, [1, 0, 1])
  let g2 = @symlib.FinMap::new(2, 3, [2, 0])
  let lhs = @symlib.pow_fmap(g2.compose(f2))
  let rhs = @symlib.pow_fmap(g2).compose(@symlib.pow_fmap(f2))
  assert_true(lhs.equal(rhs))
}

///|
test "aut-functoriality" {
  let c6 = @symlib.Graph::cycle(6)
  let grp = @symlib.automorphism_group(c6)
  let rot = @symlib.Perm::from_cycles(6, [[0, 1, 2, 3, 4, 5]])
  let refl = @symlib.Perm::from_img([0, 5, 4, 3, 2, 1])
  // F(φ2 ∘ φ1) = F(φ2) ∘ F(φ1)（以生成元像比較）
  let (composed, stepped) = @symlib.aut_functorial(rot, refl, grp)
  assert_eq(composed.order(), grp.order())
  assert_eq(stepped.order(), grp.order())
  // 共軛像之生成元互相包含
  for gen in composed.generators() {
    assert_true(stepped.contains(gen))
  }
  // F(id) = id
  let (idc, _) = @symlib.aut_functorial(
    @symlib.Perm::identity(6),
    @symlib.Perm::identity(6),
    grp,
  )
  assert_eq(idc.order(), grp.order())
  // 同構誘導：Aut(G1) 經 φ 共軛 == Aut(G2)
  let sig = @symlib.Perm::from_cycles(6, [[0, 2, 4, 1, 3, 5]])
  let c6r = c6.relabel(sig)
  match @symlib.isomorphism(c6, c6r) {
    Some(phi) => {
      let mapped = @symlib.aut_map(phi, grp)
      let direct = @symlib.automorphism_group(c6r)
      assert_eq(mapped.order(), direct.order())
      for gen in mapped.generators() {
        assert_true(direct.contains(gen))
      }
    }
    None => abort("expected iso")
  }
}

///|
test "action-groupoid-cardinality" {
  // |X//G| = Σ_{軌道代表} 1/|G_x| = |X|/|G|
  let c6 = @symlib.Graph::cycle(6)
  let gs = @symlib.GSet::of(@symlib.automorphism_group(c6))
  let card = gs.groupoid_cardinality()
  assert_true((card - 0.5).abs() < 0.000000001) // 6/12
  // Burnside 形式：Σ_x 1/|Orb(x)| = #軌道 = 1
  assert_true((gs.orbit_sum_cardinality() - 1.0).abs() < 0.000000001)
  // 平凡群：|X//1| = |X|
  let triv = @symlib.GSet::of(@symlib.PermGroup::trivial(5))
  assert_true((triv.groupoid_cardinality() - 5.0).abs() < 0.000000001)
  assert_true((triv.orbit_sum_cardinality() - 5.0).abs() < 0.000000001)
  // 連通分量 = 軌道；迷向群 = 穩定子
  assert_eq(gs.components().length(), 1)
  assert_eq(gs.isotropy(0).order(), 2L)
  assert_eq(gs.hom(0, 3, 100).length(), 2) // C6 中 0→3 之對稱：2 個
}

///|
test "search-modes-agree" {
  // 三種剪枝模式之規範指紋必須一致；動態模式見證必須合法
  let graphs : Array[@symlib.Graph] = [
    @symlib.Graph::petersen(),
    @symlib.Graph::cycle(7),
    @symlib.Graph::hypercube(3),
    @symlib.Graph::complete_bipartite(2, 3),
    @symlib.Graph::path(6),
  ]
  for g in graphs {
    let r0 = @symlib.search_graph_mode(g, 0)
    let r1 = @symlib.search_graph_mode(g, 1)
    let r2 = @symlib.search_graph_mode(g, 2)
    let d0 = @symlib.digest_from(r0.n, r0.canon_enc)
    let d1 = @symlib.digest_from(r1.n, r1.canon_enc)
    let d2 = @symlib.digest_from(r2.n, r2.canon_enc)
    assert_eq(d0, d1)
    assert_eq(d1, d2)
    assert_eq(@symlib.search_bad_witness(g), 0)
    // 剪枝單調性：無剪枝節點數 ≥ 靜態 ≥ 動態
    assert_true(r0.nodes >= r1.nodes)
    assert_true(r1.nodes >= r2.nodes)
  }
}

///|
test "isomorphisms-m-count" {
  // 全部同構之個數 = |Aut|（g1 == g2 時）
  let c4 = @symlib.Graph::cycle(4)
  let isos = @symlib.isomorphisms_m(c4, c4, 100)
  assert_eq(isos.to_array().length(), 8) // |Aut(C4)| = 8
  // 每個都是合法同構
  for s in isos.to_array() {
    assert_true(@symlib.is_automorphism(c4, s))
  }
  // 非同構 ⇒ 空單子
  let c6 = @symlib.Graph::cycle(6)
  let two_c3 = @symlib.Graph::from_edges(6, [
    (0, 1),
    (1, 2),
    (2, 0),
    (3, 4),
    (4, 5),
    (5, 3),
  ])
  assert_eq(@symlib.isomorphisms_m(c6, two_c3, 100).to_array().length(), 0)
}

///|
test "analyze-pipeline-and-state-monad" {
  let g = @symlib.Graph::petersen()
  let r = @symlib.analyze(g)
  assert_eq(r.order, 120L)
  assert_eq(r.vertex_orbits.length(), 1)
  assert_eq(r.edge_orbits.length(), 1)
  assert_eq(r.folded.k, 1)
  assert_true(r.nodes > 0)
  // StateM 管線：統計線程化
  let init : @symlib.SearchStats = { nodes: 0, leaves: 0, autos: 0, }
  let prog = @symlib.analyze_m(g).bind(fn(rep) {
    @symlib.analyze_m(@symlib.Graph::cycle(6)).bind(fn(rep2) {
      @symlib.StateM::pure((rep, rep2))
    })
  })
  let ((rep_a, rep_b), stats) = (prog.run)(init)
  assert_eq(rep_a.order, 120L)
  assert_eq(rep_b.order, 12L)
  assert_true(stats.nodes >= rep_a.nodes + rep_b.nodes)
  assert_true(stats.leaves > 0)
  // 報告文字
  let s = r.to_report_string()
  assert_true(s.length() > 50)
}

///|
test "refine-colors-invariant" {
  // 精煉顏色多重集 = 重標號不變量
  let g = @symlib.Graph::petersen()
  let sig = @symlib.Perm::from_cycles(10, [[0, 7, 3, 9, 1, 6, 8, 2, 5, 4]])
  let g2 = g.relabel(sig)
  let c1 = @symlib.refine_colors(g)
  let c2 = @symlib.refine_colors(g2)
  // 顏色分區之大小多重集一致
  let hist1 = color_hist(c1)
  let hist2 = color_hist(c2)
  assert_eq(hist1, hist2)
  // 等價分割精煉：Petersen 之平凡精煉仍為單格（距離正則）
  let part = @symlib.refine_equitable(g, @symlib.Part::trivial(10))
  assert_eq(part.cell_count(), 1)
  // P5：精煉分出對稱層
  let p5 = @symlib.Graph::path(5)
  let part5 = @symlib.refine_equitable(p5, @symlib.Part::trivial(5))
  // 分裂序：{0,4} | {2} | {1,3}（格序 = 簽名序，中心點先分出來）
  assert_eq(part5.cell_sizes(), [2, 1, 2])
}

///|
/// 顏色直方圖（排序後的類大小序列）。
fn color_hist(colors : Array[Int32]) -> Array[Int32] {
  let mut k = 0
  for c in colors {
    if c + 1 > k {
      k = c + 1
    }
  }
  let hist = Array::make(k, 0)
  for c in colors {
    hist[c] = hist[c] + 1
  }
  hist.sort()
  hist
}

///|
test "graph-builders-consistent" {
  let k5 = @symlib.Graph::complete(5)
  assert_eq(k5.order(), 5)
  assert_eq(k5.size(), 10)
  assert_true(k5.is_regular())
  assert_eq(k5.degree_seq(), [4, 4, 4, 4, 4])
  let q3 = @symlib.Graph::hypercube(3)
  assert_eq(q3.size(), 12)
  assert_eq(q3.components().length(), 1)
  let comp = q3.complement()
  assert_eq(comp.size(), 28 - 12)
  // 補圖之補圖 = 原圖
  assert_true(comp.complement() == q3)
  // 重標號保持邊數與度序列
  let sig = @symlib.Perm::from_cycles(8, [[0, 3, 6, 1, 4, 7, 2, 5]])
  let q3r = q3.relabel(sig)
  assert_eq(q3r.size(), q3.size())
  assert_eq(q3r.degree_seq(), q3.degree_seq())
  // 導出子圖
  let sub = q3.induced_subgraph([0, 1, 2, 3])
  assert_eq(sub.order(), 4)
  assert_eq(sub.size(), 4) // Q3 的一半是 C4
  assert_true(@symlib.isomorphic(sub, @symlib.Graph::cycle(4)))
  // 自環與重邊被忽略
  let messy = @symlib.Graph::from_edges(3, [(0, 0), (0, 1), (1, 0), (1, 2)])
  assert_eq(messy.size(), 2)
}
