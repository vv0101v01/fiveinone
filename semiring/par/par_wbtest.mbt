// ===========================================================================
// 平行層的測試：結果必須與序列版本**逐位元**相同
//
// 「平行」不是免責條款：分段、歸約順序、掃描深度都固定，
// 因此同一份輸入在任何後端上都會給出同一個答案。
// ===========================================================================

///|
test "par_map_chunks 覆蓋每一格且只寫一次" {
  let n = 1000
  let hits : Array[Int32] = Array::make(n, 0)
  @par.par_map_chunks(n, 7, fn(lo, hi) {
    for i in lo..<hi {
      hits[i] = hits[i] + 1
    }
  })
  let mut ok = true
  for h in hits {
    if h != 1 {
      ok = false
    }
  }
  inspect(ok, content="true")
}

///|
test "par_sum 與序列相加完全相同（固定歸約順序）" {
  let n = 5000
  let mut seq = 0L
  for i in 0..<n {
    seq = seq + i.to_int64() * 3L
  }
  let par = @par.par_sum(n, 64, fn(i) { i.to_int64() * 3L })
  inspect(par, content="\{seq}")
  // 改變切塊數不改變結果
  inspect(@par.par_sum(n, 7, fn(i) { i.to_int64() * 3L }), content="\{seq}")
  inspect(@par.par_sum(n, 1024, fn(i) { i.to_int64() * 3L }), content="\{seq}")
}

///|
test "par_scan（Hillis–Steele）與序列掃描逐位元相同" {
  let rng = @alg.Rng::new(0xF00D_0001UL)
  let n = 3000
  let vals : Array[Int64] = Array::makei(n, fn(_i) {
    rng.next_u64().reinterpret_as_int64() % 1000L
  })
  let seq = @par.scan_sequential(vals)
  let par = @par.par_scan(vals)
  let mut same = true
  for i in 0..<n {
    if seq[i] != par[i] {
      same = false
    }
  }
  inspect(same, content="true")
  // 深度是 ceil(log2 n) 層：n=3000 ⇒ 12 層
  inspect(@par.scan_depth(n), content="12")
}

///|
test "chunk_size 的邊界" {
  inspect(@par.chunk_size(10, 3), content="4")
  inspect(@par.chunk_size(10, 10), content="1")
  inspect(@par.chunk_size(0, 4), content="0")
  inspect(@par.chunk_size(5, 0), content="5")
  inspect(@par.chunk_size(3, 100), content="1")
}

///|
test "後端名稱在任何 target 上都有定義" {
  let b = @par.backend()
  inspect(b.length() > 0, content="true")
  println("parallel backend: \{b}")
}
