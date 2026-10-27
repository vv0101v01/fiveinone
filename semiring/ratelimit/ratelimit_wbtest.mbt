// ===========================================================================
// ratelimit 套件測試
//
// 這些測試同時扮演「攻擊模擬」：兩個攻擊面各有一個決定性（虛擬時鐘）的
// 情境，斷言的是**不變量**而不是某個特定數字：
//   * 單點狂按：2 秒內 20 萬次 ⇒ 放行量 ≤ burst + rate × 2s，且被拒的有退避
//   * 多點齊發：同一微秒內 5 萬個不同鍵 ⇒ 全域閘門把它壓到 burst 以內，
//     且絕大多數請求在雜湊前就被丟棄（shedded 佔多數）
// ===========================================================================

///|
/// 單點狂按：200k 次請求、2 秒虛擬時間、1000 rps、burst 20。
test "單點狂按：放行量受 GCRA 上限約束" {
  let lim = Limiter::new(1000.0, 20, 1024)
  let mut now = 0L
  let mut allowed = 0
  for i in 0..<200000 {
    // 每 10 µs 一次請求 ⇒ 2 秒內 20 萬次（每鍵 100k rps 的極端值）
    now = (i * 10).to_int64()
    match lim.admit(42UL, now) {
      Allowed => allowed = allowed + 1
      _ => ()
    }
  }
  // 上限 = burst + rate·時間 = 20 + 1000 × 2 = 2020（攻擊者最多只能拿到這個量）
  assert_true(allowed <= 2020)
  // 連續被拒會觸發指數退避，因此實際放行量更低（這是刻意的減速）
  assert_true(allowed < 2020)
  // 但仍不得餓死正常流量：至少要有 burst 的量通過
  assert_true(allowed >= 20)
  let (a, t, s) = lim.stats()
  assert_eq(a, allowed.to_int64())
  assert_eq(a + t + s, 200000L)
  assert_true(t > 190000L)
}

///|
test "多點齊發：全域閘門在雜湊前丟棄絕大多數請求" {
  let lim = Limiter::with_gate(1000.0, 20, 50000.0, 100, 4096)
  let mut allowed = 0
  let mut shedded = 0
  // 同一微秒內 5 萬個不同鍵
  for k in 0..<50000 {
    match lim.admit(k.to_uint64(), 1000L) {
      Allowed => allowed = allowed + 1
      Shedded => shedded = shedded + 1
      Throttled(_) => ()
    }
  }
  // 全域閘門的 burst 是 100 ⇒ 放行量不可超過 100（+ 已累積的時間預算）
  assert_true(allowed <= 100)
  assert_true(shedded > 49000)
}

///|
test "有界鍵表：容量固定、逐出計數、記憶體不成長" {
  let lim = Limiter::new(1000000.0, 1000, 256)
  let mut now = 0L
  for k in 0..<20000 {
    now = (k * 10).to_int64()
    let _ = lim.admit(k.to_uint64(), now)
  }
  assert_true(lim.table_used() <= 256)
  assert_true(lim.table_evictions() > 19000L)
}

///|
test "階層限流：鍵被拒時不得消耗租戶額度（preview/commit 分離）" {
  // 租戶 10 rps / burst 2；鍵 1 rps / burst 1
  let h = HierLimiter::new(10.0, 2, 1.0, 1, 64)
  let mut now = 0L
  let mut allowed = 0
  for i in 0..<50 {
    now = (i * 1000).to_int64() // 每 1 ms 一次（鍵層級 1 rps ⇒ 幾乎全被拒）
    match h.admit(7UL, 99UL, now) {
      Allowed => allowed = allowed + 1
      _ => ()
    }
  }
  // 鍵層 burst=1、rate=1/s，50 ms 內最多放行 1 個
  assert_true(allowed <= 1)
  let (a, t, s) = h.stats()
  assert_eq(a, allowed.to_int64())
  assert_true(t >= 48L)
  let _ = s
}

///|
test "階層限流：租戶額度不會被拒絕的鍵請求吃掉" {
  // 租戶 1000 rps / burst 50；鍵 1 rps / burst 1
  let h = HierLimiter::new(1000.0, 50, 1.0, 1, 64)
  // 先讓某個鍵密集被拒 200 次（同一時間點）
  for _ in 0..<200 {
    let _ = h.admit(1UL, 5UL, 0L)
  }
  // 前面 200 次中已有 1 次成功（鍵 burst = 1），消耗了租戶 1 個額度；
  // 因此同一時間點剩下的額度是 49。重點是：被拒的 199 次**沒有**吃掉租戶預算。
  let mut allowed = 0
  for k in 0..<100 {
    match h.admit(1UL, (100 + k).to_uint64(), 0L) {
      Allowed => allowed = allowed + 1
      _ => ()
    }
  }
  assert_eq(allowed, 49)
}

///|
test "時間倒退（NTP 調時）被夾住，不會把鍵永久鎖死" {
  let lim = Limiter::new(1000.0, 1, 64)
  let _ = lim.admit(1UL, 1000000L)
  // 時間倒退 10 秒
  match lim.admit(1UL, -9000000L) {
    Throttled(_) => assert_true(true)
    _ => abort("expected throttle under clock rollback")
  }
  // 時間回到正常軸並前進，應可再次放行
  match lim.admit(1UL, 1001000L) {
    Allowed => assert_true(true)
    _ => abort("expected allow after clock recovery")
  }
}

///|
test "退避：連續被拒時 retry_after 單調增加" {
  let g = Gcra::new(1000.0, 2)
  let mut prev = 0L
  let mut strikes = 1
  for _ in 0..<8 {
    match g.preview(1000000L, 0L, strikes) {
      Throttled(r) => {
        assert_true(r >= prev)
        prev = r
      }
      _ => abort("expected guarded")
    }
    strikes = strikes + 1
  }
  // 上限為 64×interval（interval = 1000 µs ⇒ 64 ms）
  assert_true(prev <= 1000000L + 64000L)
}

///|
test "決定性：相同請求序列產生完全相同結果" {
  let run = fn() {
    let lim = Limiter::with_gate(500.0, 10, 5000.0, 200, 128)
    let mut sig = 0L
    let mut now = 0L
    for i in 0..<5000 {
      now = (i * 37).to_int64()
      let key = (i * 7919 % 1000).to_uint64()
      let code = match lim.admit(key, now) {
        Allowed => 1L
        Throttled(_) => 2L
        Shedded => 3L
      }
      sig = sig * 31L + code
    }
    sig
  }
  assert_eq(run(), run())
}

///|
test "鍵表雜湊：不同鍵不會互相覆蓋到同一槽（未滿時）" {
  let t = KeyTable::new(1024)
  for k in 0..<500 {
    let idx = t.get_or_insert(k.to_uint64(), 0L)
    assert_true(idx >= 0 && idx < t.capacity())
  }
  assert_eq(t.used, 500)
  // 全部可尋回
  for k in 0..<500 {
    let (found, idx) = t.locate(k.to_uint64())
    assert_true(found)
    assert_eq(t.slots[idx].key, k.to_uint64())
  }
}
