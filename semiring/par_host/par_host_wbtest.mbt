// ===========================================================================
// 主機後端的測試：它必須與序列接縫**給出同一個答案**
//
// 這個套件只在 native 上編譯（`supported_targets`），因此這裡的測試
// 只在 native 跑；其餘 target 由 `par/` 的序列測試覆蓋同一組性質。
// ===========================================================================

///|
test "主機後端存在，且名稱與序列後端不同" {
  inspect(is_host_backend(), content="true")
  let h = backend_name()
  inspect(h != @par.backend(), content="true")
  println("host backend: \{h} / seam backend: \{@par.backend()}")
}

///|
test "par_for：每一段恰好執行一次，順序不影響計數" {
  let n = 64
  let hits : Array[Int32] = Array::make(n, 0)
  par_for(n, fn(k) { hits[k] = hits[k] + 1 })
  let mut ok = true
  for h in hits {
    if h != 1 {
      ok = false
    }
  }
  inspect(ok, content="true")
}

///|
test "par_for 與序列版本算出同一個和（確定性歸約）" {
  let n = 2000
  let mut seq = 0L
  for i in 0..<n {
    seq = seq + i.to_int64() * 7L
  }
  let par = @par.par_sum(n, 32, fn(i) { i.to_int64() * 7L })
  inspect(par, content="\{seq}")
}

///|
test "分片 I/O：兩次讀到的內容逐位元相同，且檔案數正確" {
  let payload = "0 1 1\n1 2 1\n2 3 1\n"
  let r = shard_io_bench(payload, 4)
  inspect(r.files, content="4")
  inspect(r.same, content="true")
  inspect(r.seq_data.length(), content="4")
  inspect(r.par_data.length(), content="4")
  inspect(r.bytes, content="\{payload.length() * 4}")
  // 時間是量出來的，只斷言「有量到」而不是「量到多少」
  inspect(r.seq_us > 0.0, content="true")
  inspect(r.par_us > 0.0, content="true")
}
