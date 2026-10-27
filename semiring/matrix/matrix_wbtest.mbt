// ===========================================================================
// matrix 套件測試
//
// 每一個「演算法變體」都必須與另一個獨立實作或暴力法一致；
// 另外必須證明：把冪等前提拿掉後，原地演算法**真的會錯**
// （否則「型別約束」就只是裝飾）。
// ===========================================================================

///|
/// 產生 n×n 隨機 min-plus 矩陣（密度 density%，權值 [0, maxw]）。
fn rand_trop(
  rng : @alg.Rng,
  n : Int32,
  density : Int32,
  maxw : Int32,
) -> Mat[@alg.Trop] {
  let m = Mat::new(n, n, @alg.Trop::inf())
  for i in 0..<n {
    for j in 0..<n {
      if i != j && rng.next_int(100) < density {
        m.d[i * n + j] = @alg.Trop::new(rng.next_int(maxw + 1))
      }
    }
  }
  m
}

///|
fn rand_bool(rng : @alg.Rng, n : Int32, density : Int32) -> Mat[@alg.BoolSr] {
  let m = Mat::new(n, n, @alg.BoolSr::of(false))
  for i in 0..<n {
    for j in 0..<n {
      if i != j && rng.next_int(100) < density {
        m.d[i * n + j] = @alg.BoolSr::of(true)
      }
    }
  }
  m
}

///|
test "三種乘法變體結果完全一致（min-plus / boolean / bottleneck）" {
  let rng = @alg.Rng::new(0x1111UL)
  for n in [1, 2, 5, 12] {
    let a = rand_trop(rng, n, 60, 20)
    let b = rand_trop(rng, n, 60, 20)
    let c0 = mul_naive(a, b)
    let c1 = mul_ikj(a, b)
    let c2 = mul_blocked(a, b, block=3)
    let c3 = mul_trop(a, b)
    assert_true(mat_equal(c0, c1))
    assert_true(mat_equal(c0, c2))
    assert_true(mat_equal(c0, c3))
    let ab = rand_bool(rng, n, 50)
    let bb = rand_bool(rng, n, 50)
    assert_true(mat_equal(mul_naive(ab, bb), mul_blocked(ab, bb, block=2)))
    let an = Mat::new(n, n, @alg.Bottleneck::new(0))
    let bn = Mat::new(n, n, @alg.Bottleneck::new(0))
    for i in 0..<n {
      for j in 0..<n {
        an.d[i * n + j] = @alg.Bottleneck::new(rng.next_int(100))
        bn.d[i * n + j] = @alg.Bottleneck::new(rng.next_int(100))
      }
    }
    assert_true(mat_equal(mul_naive(an, bn), mul_ikj(an, bn)))
  }
}

///|
test "矩陣乘法結合律（多個半環）" {
  let rng = @alg.Rng::new(0x2222UL)
  for n in [2, 4, 7] {
    let a = rand_trop(rng, n, 70, 9)
    let b = rand_trop(rng, n, 70, 9)
    let c = rand_trop(rng, n, 70, 9)
    let l = mul_ikj(mul_ikj(a, b), c)
    let r = mul_ikj(a, mul_ikj(b, c))
    assert_true(mat_equal(l, r))
  }
}

///|
test "熱帶剪枝：結果相同、運算量嚴格更少" {
  let rng = @alg.Rng::new(0x3333UL)
  let n = 24
  let a = rand_trop(rng, n, 40, 30)
  let b = rand_trop(rng, n, 40, 30)
  let o1 = @alg.Ops::new()
  let c1 = mul_trop_plain(a, b, ops=o1)
  let o2 = @alg.Ops::new()
  let c2 = mul_trop(a, b, ops=o2)
  assert_true(mat_equal(c1, c2))
  assert_true(o2.total() < o1.total())
  // plain 版本的運算量恰好是 n³（每個 (i,k,j) 一次 ⊗）
  assert_eq(o1.times, (n * n * n).to_int64())
}

///|
test "三種 closure 變體一致（min-plus，無負權）" {
  let rng = @alg.Rng::new(0x4444UL)
  for n in [1, 3, 8, 17, 40] {
    let e = rand_trop(rng, n, 35, 15)
    let c_inplace = closure_fw_inplace(e)
    let c_snap = closure_lehmann(e)
    let c_block = closure_blocked(e, threshold=4)
    assert_true(mat_equal(c_inplace, c_snap))
    assert_true(mat_equal(c_inplace, c_block))
  }
}

///|
test "boolean 傳遞閉包：三種演算法一致，且與暴力可達性一致" {
  let rng = @alg.Rng::new(0x5555UL)
  for n in [2, 6, 15] {
    let e = rand_bool(rng, n, 25)
    let c = closure_fw_inplace(e)
    let c2 = closure_blocked(e, threshold=3)
    assert_true(mat_equal(c, c2))
    // 暴力：從每個點做 BFS
    for s in 0..<n {
      let seen = Array::make(n, false)
      let queue = Array::make(n, 0)
      let mut head = 0
      let mut tail = 0
      seen[s] = true
      queue[tail] = s
      tail = tail + 1
      while head < tail {
        let u = queue[head]
        head = head + 1
        for v in 0..<n {
          if e.d[u * n + v].b && !seen[v] {
            seen[v] = true
            queue[tail] = v
            tail = tail + 1
          }
        }
      }
      for v in 0..<n {
        assert_true(c.d[s * n + v].b == seen[v])
      }
    }
  }
}

///|
test "非冪等半環：Lehmann 版本計數正確，原地版本會重複累加" {
  // 有向圖 0→1→2，另外 0→2；路徑總數（含長度 0）
  //   0→0:1, 0→1:1, 0→2:2(直接 + 經 1), 1→1:1, 1→2:1, 2→2:1
  let n = 3
  let e = Mat::new(n, n, @alg.Counting::new(0L))
  e.d[0 * n + 1] = @alg.Counting::new(1L)
  e.d[1 * n + 2] = @alg.Counting::new(1L)
  e.d[0 * n + 2] = @alg.Counting::new(1L)
  let snap = closure_lehmann(e)
  assert_eq(snap.d[0 * n + 0].value(), 1L)
  assert_eq(snap.d[0 * n + 1].value(), 1L)
  assert_eq(snap.d[0 * n + 2].value(), 2L)
  assert_eq(snap.d[1 * n + 2].value(), 1L)
  // 原地版本（把冪等當前提的演算法）在同一輸入上會給出不同答案 ⇒
  // 這就是為什麼原地版本在型別上要求 IdempotentSemiring。
  let rng = @alg.Rng::new(0x6666UL)
  let n2 = 6
  let e2 = Mat::new(n2, n2, @alg.Counting::new(0L))
  for i in 0..<n2 {
    for j in 0..<n2 {
      if i < j && rng.next_int(100) < 45 {
        e2.d[i * n2 + j] = @alg.Counting::new(1L)
      }
    }
  }
  let snap2 = closure_lehmann(e2)
  let naive = inplace_counting(e2)
  assert_false(mat_equal(snap2, naive))
  // 且 snapshot 版本與暴力列舉一致
  let brute = brute_count_paths(e2, n2)
  assert_true(mat_equal(snap2, brute))
}

///|
/// 把非冪等半環硬塞進「原地」演算法（繞過型別約束），示範錯誤結果。
fn inplace_counting(e : Mat[@alg.Counting]) -> Mat[@alg.Counting] {
  let n = e.rows
  let m = e.copy()
  for i in 0..<n {
    m.d[i * n + i] = @alg.Counting::plus(m.d[i * n + i], @alg.Counting::one())
  }
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        let t = @alg.Counting::times(m.d[i * n + k], m.d[k * n + j])
        m.d[i * n + j] = @alg.Counting::plus(m.d[i * n + j], t)
      }
    }
  }
  m
}

///|
/// 暴力：對每個起點 DFS 列舉所有路（DAG，長度 ≤ n）並計數。
fn brute_count_paths(e : Mat[@alg.Counting], n : Int32) -> Mat[@alg.Counting] {
  let out = Mat::new(n, n, @alg.Counting::new(0L))
  for s in 0..<n {
    out.d[s * n + s] = @alg.Counting::new(1L)
  }
  for s in 0..<n {
    let stack = Array(capacity=n * n)
    stack.push(s)
    while stack.length() > 0 {
      let u = stack.pop().unwrap()
      for v in 0..<n {
        if e.d[u * n + v].value() > 0L {
          let add = out.d[s * n + u].value() * e.d[u * n + v].value()
          out.d[s * n + v] = @alg.Counting::new(out.d[s * n + v].value() + add)
          if v > u {
            stack.push(v)
          }
        }
      }
    }
  }
  out
}

///|
test "closure_series 對非封閉半環的收斂判據" {
  // 機率半環：0→1 機率 0.5、1→1 機率 0.5
  let n = 2
  let e = Mat::new(n, n, @alg.Prob::new(0.0))
  e.d[0 * n + 1] = @alg.Prob::new(0.5)
  e.d[1 * n + 1] = @alg.Prob::new(0.5)
  let (acc, conv) = closure_series(e, k=40, is_small=fn(x) {
    x.value().abs() < 0.000000000001
  })
  assert_true(conv)
  // 0→1 的無窮和 = 0.5·(1/(1-0.5)) = 1.0
  let v = acc.d[0 * n + 1].value()
  assert_true((v - 1.0).abs() < 0.000001)
}

///|
test "Ops 計數器：naive 與 blocked 的 ⊗ 次數相同（只差存取順序）" {
  let rng = @alg.Rng::new(0x7777UL)
  let n = 9
  let a = rand_trop(rng, n, 50, 10)
  let b = rand_trop(rng, n, 50, 10)
  let o1 = @alg.Ops::new()
  let o2 = @alg.Ops::new()
  let _ = mul_naive(a, b, ops=o1)
  let _ = mul_blocked(a, b, block=4, ops=o2)
  assert_eq(o1.total(), o2.total())
  assert_eq(o1.times, (n * n * n).to_int64())
}

///|
test "closure 的實測規模律：n 加倍 ⇒ 運算量約 8 倍（Θ(n³)）" {
  let rng = @alg.Rng::new(0x8888UL)
  let mut prev = 0L
  let ratios : Array[Double] = []
  for n in [16, 32, 64] {
    let e = rand_trop(rng, n, 90, 10)
    let o = @alg.Ops::new()
    let _ = closure_fw_inplace(e, ops=o)
    if prev > 0L {
      ratios.push(o.total().to_double() / prev.to_double())
    }
    prev = o.total()
  }
  // n 加倍時 Θ(n³) 的比值應接近 8；密度 90% 下容許 [6.5, 9.5]
  for r in ratios {
    assert_true(r > 6.5 && r < 9.5)
  }
}

///|
test "star 定律：矩陣星在熱帶半環上滿足 a* = 1 ⊕ a·a*" {
  let rng = @alg.Rng::new(0x9999UL)
  let n = 5
  let e = rand_trop(rng, n, 40, 8)
  let s = closure_fw_inplace(e)
  let lhs = mul_trop(closure_fw_inplace(e), Mat::identity(n))
  assert_true(mat_equal(s, lhs))
  // 閉包後再閉包 = 閉包（冪等）
  assert_true(mat_equal(s, closure_fw_inplace(s)))
}
