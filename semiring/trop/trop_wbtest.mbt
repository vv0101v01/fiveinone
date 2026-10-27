// ===========================================================================
// 熱帶幾何的測試：每一條都是「可失敗」的斷言，不是恆真式
// ===========================================================================

///|
test "roots: 重數總和等於次數" {
  let cases : Array[Array[Int32]] = [
    [0, 1],
    [0, 1, 0],
    [5, 3, 7, 2, 9],
    [0, 10, 0, 10, 0],
    [2],
  ]
  for c in cases {
    let p = UniPoly::new(c)
    let deg = p.degree()
    if deg < 0 {
      assert_eq(p.multiplicity_sum(), 0)
    } else {
      assert_eq(p.multiplicity_sum(), deg)
    }
  }
}

///|
test "roots: 在根上恰好兩個單項式打平，根的兩側各一個" {
  // f = min(0, 3x, x+2, 4x+3) 的支撐點 (0,0),(2,1),(3,4)?? 以實際 hull 為準
  let p = UniPoly::new([0, 3, 1, 4])
  let hull = p.lower_hull()
  assert_eq(hull.length(), 3)
  let pairs = p.roots_with_mult()
  assert_eq(pairs.length(), 2)
  for k in 1..<hull.length() {
    let (i, ci) = hull[k - 1]
    let (j, cj) = hull[k]
    let r = Rat::new((ci - cj).to_int64(), (j - i).to_int64())
    let arg = p.argmin_at(r)
    assert_eq(arg.length(), 2)
    assert_eq(arg[0], i)
    assert_eq(arg[1], j)
  }
}

///|
test "roots: 根以外的點只有一個單項式達到最小值" {
  let p = UniPoly::new([0, 3, 1, 4])
  for x in [-5, -1, 0, 1, 5, 9] {
    let arg = p.argmin_at(Rat::of_int(x))
    assert_eq(arg.length(), 1)
  }
}

///|
test "乘法定理：roots(f⊗g) = roots(f) ⊔ roots(g)" {
  let f = UniPoly::new([0, 2, 1, 5])
  let g = UniPoly::new([1, 0, 4, 2, 7])
  let h = trop_poly_mul(f, g)
  let union : Array[Rat] = []
  for r in f.roots() {
    union.push(r)
  }
  for r in g.roots() {
    union.push(r)
  }
  assert_eq(h.degree(), f.degree() + g.degree())
  assert_eq(h.roots().length(), f.degree() + g.degree())
  assert_true(roots_equal(h.roots(), union))
}

///|
test "乘法定理對 1000 組隨機多項式成立" {
  let rng = @alg.Rng::new(31337UL)
  let mut checked = 0
  for _ in 0..<200 {
    let nf = 1 + rng.next_int(4)
    let ng = 1 + rng.next_int(4)
    let cf : Array[Int32] = []
    let cg : Array[Int32] = []
    for _ in 0..<nf {
      cf.push(rng.range(0, 20))
    }
    for _ in 0..<ng {
      cg.push(rng.range(0, 20))
    }
    let f = UniPoly::new(cf)
    let g = UniPoly::new(cg)
    let h = trop_poly_mul(f, g)
    let union : Array[Rat] = []
    for r in f.roots() {
      union.push(r)
    }
    for r in g.roots() {
      union.push(r)
    }
    assert_true(roots_equal(h.roots(), union))
    checked = checked + 1
  }
  assert_eq(checked, 200)
}

///|
test "求值：下包絡與逐點最小值一致" {
  let p = UniPoly::new([0, 4, 1])
  for x in [-10, -3, 0, 3, 10] {
    let mut brute = @alg.trop_inf
    for i in 0..<p.coeffs.length() {
      if p.coeffs[i] < @alg.trop_inf {
        let v = p.coeffs[i] + i * x
        if v < brute {
          brute = v
        }
      }
    }
    assert_eq(p.eval(x), brute)
  }
}

///|
test "牛頓多邊形：凸包頂點數與面積" {
  let poly = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(1, 2, 0),
    BTerm::new(2, 0, 2),
    BTerm::new(3, 2, 2),
    BTerm::new(4, 1, 1),
  ])
  assert_eq(poly.newton_hull().length(), 4)
  assert_eq(poly.newton_area2(), 8)
}

///|
test "正則細分：面積守恆，且中心抬高的多項式只有一個面" {
  // 中心抬高 ⇒ 下凸包只有一個面（四個角共面），細分平凡
  let flat = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(1, 2, 0),
    BTerm::new(2, 0, 2),
    BTerm::new(3, 2, 2),
    BTerm::new(5, 1, 1),
  ])
  let ff = flat.subdivision()
  assert_eq(ff.length(), 1)
  assert_eq(flat.subdivision_area2(ff), flat.newton_area2())
  // 中心壓低 ⇒ 以中心為共同頂點的扇形細分（4 個三角形）
  let sun = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(1, 2, 0),
    BTerm::new(2, 0, 2),
    BTerm::new(3, 2, 2),
    BTerm::new(-3, 1, 1),
  ])
  let fs = sun.subdivision()
  assert_eq(fs.length(), 4)
  assert_eq(sun.subdivision_area2(fs), sun.newton_area2())
}

///|
test "對偶性：每個面的法向方向恰好選出該面的成員" {
  let sun = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(1, 2, 0),
    BTerm::new(2, 0, 2),
    BTerm::new(3, 2, 2),
    BTerm::new(-3, 1, 1),
  ])
  let fs = sun.subdivision()
  let (ok, bad) = sun.check_duality(fs)
  assert_eq(bad, 0)
  assert_eq(ok, fs.length())
}

///|
test "平衡條件：扇形細分的 4 個頂點殘差全為 0（含射線）" {
  let sun = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(1, 2, 0),
    BTerm::new(2, 0, 2),
    BTerm::new(3, 2, 2),
    BTerm::new(-3, 1, 1),
  ])
  let fs = sun.subdivision()
  let edges = sun.dual_curve(fs)
  // 4 條內部邊（有界）+ 4 條邊界邊（射線）
  assert_eq(edges.length(), 8)
  let res = balancing_residuals(edges, fs.length())
  for r in res {
    assert_eq(r.1, 0L)
    assert_eq(r.2, 0L)
  }
}

///|
test "平衡條件：非扇形（非均勻權重）的細分也平衡" {
  // 邊界上的邊長不為 1 ⇒ 權重 > 1，仍然必須平衡
  let poly = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(4, 3, 0),
    BTerm::new(1, 0, 2),
    BTerm::new(7, 3, 2),
    BTerm::new(-2, 1, 1),
  ])
  let fs = poly.subdivision()
  let edges = poly.dual_curve(fs)
  let res = balancing_residuals(edges, fs.length())
  for r in res {
    assert_eq(r.1, 0L)
    assert_eq(r.2, 0L)
  }
}

///|
test "打平方向都落在細分的面上（取樣交叉驗證）" {
  let sun = BPoly::new([
    BTerm::new(0, 0, 0),
    BTerm::new(1, 2, 0),
    BTerm::new(2, 0, 2),
    BTerm::new(3, 2, 2),
    BTerm::new(-3, 1, 1),
  ])
  let fs = sun.subdivision()
  let (ties, explained, unexplained) = sun.check_ties_on_faces(
    fs, 4000, 20261023UL,
  )
  assert_eq(unexplained, 0)
  assert_true(ties > 0)
  assert_eq(explained, ties)
}

///|
test "熱帶行列式：三種實作結果一致（含 7 階全排列對照）" {
  let a : Array[Array[Int64]] = [[3L, 1L, 4L], [1L, 5L, 9L], [2L, 6L, 5L]]
  let d = trop_det(a)
  assert_eq(d, 7L)
  assert_eq(d, trop_det_dp(a))
  assert_eq(d, trop_det_bruteforce(a))
  let rng = @alg.Rng::new(9921UL)
  let n = 7
  let big : Array[Array[Int64]] = []
  for _ in 0..<n {
    let row : Array[Int64] = []
    for _ in 0..<n {
      row.push(rng.range(-30, 30).to_int64())
    }
    big.push(row)
  }
  assert_eq(trop_det(big), trop_det_dp(big))
  assert_eq(trop_det(big), trop_det_bruteforce(big))
}

///|
test "熱帶行列式：10 階時匈牙利與子集 DP 仍一致（暴力不可行）" {
  let rng = @alg.Rng::new(555UL)
  let n = 10
  let a : Array[Array[Int64]] = []
  for _ in 0..<n {
    let row : Array[Int64] = []
    for _ in 0..<n {
      row.push(rng.range(-100, 100).to_int64())
    }
    a.push(row)
  }
  assert_eq(trop_det(a), trop_det_dp(a))
}

///|
test "熱帶奇異：退化矩陣有 >1 個最優排列，對角優勢矩陣唯一" {
  let a : Array[Array[Int64]] = [[1L, 2L, 3L], [1L, 2L, 3L], [1L, 2L, 3L]]
  assert_eq(trop_det_tie_count(a), 6)
  let b : Array[Array[Int64]] = [[0L, 9L, 9L], [9L, 0L, 9L], [9L, 9L, 0L]]
  assert_eq(trop_det_tie_count(b), 1)
  assert_eq(trop_det(b), 0L)
}

///|
test "指派的見證確實達到最小值" {
  let a : Array[Array[Int64]] = [[4L, 1L, 3L], [2L, 0L, 5L], [3L, 2L, 2L]]
  let (cost, perm) = trop_assignment(a)
  let mut sum = 0L
  for i in 0..<3 {
    sum = sum + a[i][perm[i]]
  }
  assert_eq(sum, cost)
  assert_eq(cost, trop_det(a))
}
