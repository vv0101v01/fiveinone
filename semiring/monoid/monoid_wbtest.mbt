// ===========================================================================
// monoid 套件測試
// ===========================================================================

///|
test "前綴掃描（Hillis–Steele）與逐項累加完全一致" {
  let rng = @alg.Rng::new(0xF00D_0001UL)
  for n in [0, 1, 2, 3, 7, 16, 33, 64] {
    let data = Array::makei(n, fn(_i) {
      SumI64::of(rng.next_int(1000).to_int64())
    })
    let a : Array[SumI64] = []
    let b : Array[SumI64] = []
    prefix_scan(data, out=a)
    prefix_scan_sequential(data, out=b)
    assert_eq(a.length(), n)
    for i in 0..<n {
      assert_true(a[i] == b[i])
    }
  }
}

///|
test "segment tree：區間和 == 暴力（含單點更新）" {
  let rng = @alg.Rng::new(0xF00D_0002UL)
  let n = 37
  let data = Array::makei(n, fn(_i) { SumI64::of(rng.next_int(100).to_int64()) })
  let t = SegTree::build(data)
  for _ in 0..<40 {
    let l = rng.next_int(n)
    let r = l + 1 + rng.next_int(n - l)
    let mut brute = 0L
    for i in l..<r {
      brute = brute + data[i].v
    }
    assert_eq(t.query(l, r).v, brute)
  }
  // 單點更新後仍然正確
  let idx = rng.next_int(n)
  data[idx] = SumI64::of(999L)
  t.set(idx, SumI64::of(999L))
  let mut brute = 0L
  for i in 0..<n {
    brute = brute + data[i].v
  }
  assert_eq(t.query(0, n).v, brute)
}

///|
test "sparse table：O(1) 區間 max == 暴力（冪等才合法）" {
  let rng = @alg.Rng::new(0xF00D_0003UL)
  for n in [1, 2, 5, 17, 64] {
    let data = Array::makei(n, fn(_i) {
      MaxI64::{ v: rng.next_int(1000).to_int64(), }
    })
    let st = SparseTable::build(data)
    for _ in 0..<30 {
      let l = rng.next_int(n)
      let r = l + 1 + rng.next_int(n - l)
      let mut brute = data[l].v
      for i in l..<r {
        brute = brute.max(data[i].v)
      }
      assert_eq(st.query(l, r).v, brute)
    }
  }
}

///|
test "fenwick：前綴/區間和與暴力一致" {
  let rng = @alg.Rng::new(0xF00D_0004UL)
  let n = 29
  let data = Array::makei(n, fn(_i) { SumI64::of(rng.next_int(50).to_int64()) })
  let f = Fenwick::build(data)
  for _ in 0..<30 {
    let l = rng.next_int(n)
    let r = l + 1 + rng.next_int(n - l)
    let mut brute = 0L
    for i in l..<r {
      brute = brute + data[i].v
    }
    assert_eq(f.range(l, r).v, brute)
  }
  f.add(3, SumI64::of(7L))
  assert_eq(f.prefix(4).v, data[0].v + data[1].v + data[2].v + data[3].v + 7L)
}

///|
test "仿射么半群：合成順序與前綴掃描" {
  let f = AffineM::new(2.0, 1.0) // 2x+1
  let g = AffineM::new(3.0, 0.0) // 3x
  // combine(f, g) = f∘g → f(g(x)) = 2(3x)+1 = 6x+1
  let h = Monoid::combine(f, g)
  assert_true((h.apply(1.0) - 7.0).abs() < 0.000000000001)
  // 前綴掃描 = 逐步合成
  let steps = [f, g, f, g, f]
  let out : Array[AffineM] = []
  prefix_scan(steps, out~)
  let mut acc = Monoid::empty()
  for s in steps {
    acc = Monoid::combine(acc, s)
  }
  assert_true((out[4].apply(2.0) - acc.apply(2.0)).abs() < 0.000000000001)
}
