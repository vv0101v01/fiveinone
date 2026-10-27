///|
/// 白盒測試：內部不變量與輔助函數。

///|
test "enc-index-layout" {
  // 列主序：idx(i,j) = j(j-1)/2 + i（i<j）；前綴連續性 = B&B 剪枝之基礎
  assert_eq(enc_index(0, 1), 0)
  assert_eq(enc_index(0, 2), 1)
  assert_eq(enc_index(1, 2), 2)
  assert_eq(enc_index(0, 3), 3)
  assert_eq(enc_index(2, 3), 5)
  // 深度 r 之前綴長度 = r(r-1)/2，且恰為前 r 位置對之編碼段
  for r in 0..<8 {
    let plen = r * (r - 1) / 2
    for j in 1..<r {
      for i in 0..<j {
        assert_true(enc_index(i, j) < plen)
      }
    }
    if r < 7 {
      assert_true(enc_index(0, r) >= plen)
    }
  }
}

///|
test "mix-table-deterministic" {
  let a = mix_table(64, 0x9E3779B97F4A7C15L)
  let b = mix_table(64, 0x9E3779B97F4A7C15L)
  assert_eq(a, b)
  let c = mix_table(64, 0xBF58476D1CE4E5B9L)
  // 不同種子 ⇒ 表不同
  let mut diff = 0
  for i in 0..<64 {
    if a[i] != c[i] {
      diff = diff + 1
    }
  }
  assert_true(diff > 60)
  // 全部為正且非零
  for v in a {
    assert_true(v > 0)
  }
}

///|
test "degree-ranks-equivariant" {
  let g = Graph::from_edges(6, [
    (0, 1),
    (0, 2),
    (1, 2),
    (3, 4),
    (4, 5),
    (5, 3),
    (2, 3),
  ])
  let ranks = degree_ranks(g)
  // 秩為 0..k-1 之連續編號
  let mut k = 0
  for r in ranks {
    if r + 1 > k {
      k = r + 1
    }
  }
  let seen = Array::make(k, 0)
  for r in ranks {
    seen[r] = seen[r] + 1
  }
  for i in 0..<k {
    assert_true(seen[i] > 0)
  }
  // 同度 ⇒ 同秩
  for u in 0..<6 {
    for v in (u + 1)..<6 {
      if g.degree(u) == g.degree(v) {
        assert_eq(ranks[u], ranks[v])
      }
    }
  }
}

///|
test "cmp-arr-lex" {
  assert_true(cmp_arr([0, 1, 2], [0, 1, 2]) == 0)
  assert_true(cmp_arr([0, 1], [0, 2]) < 0)
  assert_true(cmp_arr([1], [0, 9]) > 0)
  assert_true(cmp_arr([0, 1], [0, 1, 0]) < 0) // 前綴較短者小
  assert_true(arr_less([0], [1]))
}

///|
test "refine-equitable-converges" {
  // P7 之等價精煉：由內向外分層 [2,2,2,1]
  let p7 = Graph::path(7)
  let part = refine_equitable(p7, Part::trivial(7))
  // 格序 = 簽名序：{0,6} | {1,5} | {3} | {2,4}
  assert_eq(part.cell_sizes(), [2, 2, 1, 2])
  assert_true(part.cells().length() == 4)
  // 穩定性：再精煉不變
  let part2 = refine_equitable(p7, part)
  assert_eq(part2.cell_sizes(), part.cell_sizes())
  // 完全圖：單格
  let k6 = Graph::complete(6)
  assert_eq(refine_equitable(k6, Part::trivial(6)).cell_count(), 1)
  // Part 基本操作
  let d = Part::discrete([2, 0, 1])
  assert_true(d.is_discrete())
  assert_eq(d.cell_of[2], 0)
  assert_eq(d.lab, [2, 0, 1])
  let t = Part::trivial(4)
  assert_eq(t.cell_sizes(), [4])
  assert_eq(t.copy().cells(), [[0, 1, 2, 3]])
}

///|
test "perm-key-hash-consistency" {
  // 數值雜湊：相等置換 ⇒ 相等雜湊
  let a = Perm::from_cycles(6, [[0, 1, 2]])
  let b = Perm::from_cycles(6, [[0, 1, 2]])
  assert_eq(perm_hash(a), perm_hash(b))
  // 去重
  let gens = [a, b, Perm::identity(6), Perm::from_cycles(6, [[3, 4]])]
  let dd = dedupe_gens(gens)
  assert_eq(dd.length(), 2)
}

///|
test "orbit-tree-transversal" {
  let d6 = PermGroup::dihedral(6)
  let (orb, tr) = orbit_tree(d6.generators(), 6, 0)
  assert_eq(orb.length(), 6)
  // 橫截性質：tr[q](0) == q
  for q in orb {
    let u = tr[q].unwrap()
    assert_eq(u.apply(0), q)
  }
}

///|
test "verify-aut-soundness" {
  let pet = Graph::petersen()
  let rot = Perm::from_cycles(10, [[0, 1, 2, 3, 4]])
  // 非自同構 ⇒ verify 失敗
  assert_true(!is_automorphism(pet, rot))
  let real = aut_generators(pet)
  for s in real {
    assert_true(is_automorphism(pet, s))
  }
}

///|
test "search-stats-sane" {
  let g = Graph::petersen()
  let r = search_graph(g, true)
  assert_true(r.nodes >= r.leaves)
  assert_true(r.leaves >= 2)
  assert_true(r.ties >= 1) // 對稱圖必有等編碼葉
  let p = Graph::path(4)
  let rp = search_graph(p, true)
  assert_eq(rp.ties, 1) // P4：恰一次平手（反射）
  // 空圖 / 單點 / 兩點
  let e0 = search_graph(Graph::empty(0), true)
  assert_eq(e0.n, 0)
  let e1 = search_graph(Graph::empty(1), true)
  assert_eq(e1.canon_lab, [0])
  let e2 = search_graph(Graph::empty(2), true)
  assert_eq(e2.canon_enc.length(), 1)
}

///|
test "prefix-greater-and-copy" {
  // copy_into 正確性
  let src = [1, 2, 3, 4]
  let dst = Array::make(4, 0)
  copy_into(src, dst, 4)
  assert_eq(dst, [1, 2, 3, 4])
  let buf = Array::make(8, 0)
  copy_into_range(buf, 0, 4, 4)
  buf[0] = 7
  copy_into_range(buf, 0, 4, 1)
  assert_eq(buf[4], 7)
}

///|
test "wbtest-keylut" {
  // elem_lut_fast（開放定址）必須與 elem_lut（Map[Int64,Int32]）語意一致
  let g = automorphism_group(Graph::petersen())
  let elems = g.elements(200)
  let fast = elem_lut_fast(elems)
  let refmap = Map([])
  for i, e in elems {
    refmap.set(perm_key64(e), i)
  }
  for e in elems {
    let k = perm_key64(e)
    assert_eq(fast.at(k), refmap.get(k).unwrap())
    assert_eq(fast.find(k), refmap.get(k).unwrap())
  }
  // compose_key64 必須等同 perm_key64(x.compose(g))（免配置合成之正確性）
  for a in elems {
    for b in elems {
      assert_eq(compose_key64(a.img, b.img), perm_key64(a.compose(b)))
    }
  }
  // 缺失鍵
  assert_eq(fast.find(0L), -1)
}
