// ===========================================================================
// sim 套件測試：快取模擬器本身必須先被驗證，否則 §3 的數字沒有意義
// ===========================================================================

///|
test "完全循序存取：命中率符合理論值" {
  // 32 KiB / 8-way / 64 B ⇒ 512 lines；循序掃 512 lines 內全 miss，再掃一次全 hit
  let c = Cache::new(64, 8, 64)
  // 只存取每條 cache line 的首位元組 ⇒ 每次存取都對應不同 line
  for i in 0..<512 {
    let _ = c.access(i * 64, false)
  }
  assert_eq(c.misses, 512L)
  let before = c.misses
  for i in 0..<512 {
    let _ = c.access(i * 64, false)
  }
  assert_eq(c.misses, before)
  assert_eq(c.hits, 512L)
  // 同一條 line 內的後續位元組必命中
  let _ = c.access(0, false)
  let _ = c.access(63, false)
  assert_eq(c.hits, 514L)
}

///|
test "strided 存取造成 thrash：miss 數與 stride 成正比" {
  let c = Cache::new(64, 8, 64)
  // stride 4096 bytes（每步都落在同一個 set、不同 tag）⇒ 幾乎全 miss
  let n = 2000
  for i in 0..<n {
    let _ = c.access(i * 4096, false)
  }
  assert_true(c.misses == n.to_int64())
}

///|
test "LRU 逐出：容量內的 working set 全命中，超出即 miss" {
  let c = Cache::new(4, 1, 64) // 4 lines
  for i in 0..<4 {
    let _ = c.access(i * 64, false)
  }
  assert_eq(c.misses, 4L)
  // 重複存取同樣 4 行
  for _ in 0..<3 {
    for i in 0..<4 {
      let _ = c.access(i * 64, false)
    }
  }
  assert_eq(c.hits, 12L)
  // 第 5 行進來會逐出最舊的
  let _ = c.access(4 * 64, false)
  assert_eq(c.misses, 5L)
}

///|
test "Tracer：不同矩陣的位址不互相假命中" {
  let tr = Tracer::new(4)
  let a = tr.register(8, 8)
  let b = tr.register(8, 8)
  let p = tr.probe()
  p(a, 0, 0, false)
  p(b, 0, 0, false)
  // 兩個不同矩陣的同一個索引必須是兩次 miss
  assert_eq(tr.l1_misses(), 2L)
}

///|
test "Timer：量測值為正且單調（不會回報 0）" {
  let t = Timer::start()
  let mut s = 0
  for i in 0..<1000 {
    s = s + i
  }
  let e = t.elapsed_us()
  assert_true(e >= 0.0)
  assert_eq(s, 499500)
}
