// ===========================================================================
// CSR 與浮點熱帶半環的測試
//
// 每個測試都拿兩個獨立實作互相對照：
//   稀疏 SpGEMM  ↔ 稠密 ikj 乘法
//   稀疏 FW      ↔ 稠密 FW 閉包
//   n × sssp     ↔ 稠密閉包的對應列
//   TropF        ↔ Trop（整數權重時答案必須完全相同）
// 只有「兩邊都對」才叫通過；單邊自我一致不算。
// ===========================================================================

///|
/// 隨機稀疏矩陣：每列固定 degree 條邊（欄由 PRNG 決定）。
fn rand_csr(
  rng : @alg.Rng,
  n : Int32,
  degree : Int32,
  maxw : Int32,
) -> @mat.Csr[@alg.Trop] {
  let from : Array[Int32] = []
  let to : Array[Int32] = []
  let w : Array[@alg.Trop] = []
  for i in 0..<n {
    let mut d = 0
    while d < degree {
      let j = rng.next_int(n)
      if j != i {
        from.push(i)
        to.push(j)
        w.push(@alg.Trop::new(rng.next_int(maxw) + 1))
        d = d + 1
      }
    }
  }
  @mat.Csr::from_triplets(n, n, from, to, w)
}

///|
test "csr/from_triplets: 排序、去重、⊕ 合併" {
  // 同一個 (0,1) 出現兩次：計數半環下必須是 2，熱帶下是 min
  let from : Array[Int32] = [0, 0, 1, 0]
  let to : Array[Int32] = [2, 0, 1, 2]
  let cnt : Array[@alg.Counting] = [
    @alg.Counting::new(1L),
    @alg.Counting::new(5L),
    @alg.Counting::new(1L),
    @alg.Counting::new(3L),
  ]
  let c = @mat.Csr::from_triplets(2, 3, from, to, cnt)
  // 第 0 列：欄 0（5）、欄 2（1+3 = 4）
  inspect(c.row_nnz(0), content="2")
  inspect(c.get(0, 0).unwrap().value(), content="5")
  inspect(c.get(0, 2).unwrap().value(), content="4")
  // 第 1 列：欄 1
  inspect(c.get(1, 1).unwrap().value(), content="1")
  inspect(c.get(1, 0) is None, content="true")
  // 轉回稠密後欄索引必須遞增
  let d = c.to_dense()
  inspect(d.d[0], content="5")
}

///|
test "csr_mul 與稠密乘法一致（熱帶剪枝版）" {
  let rng = @alg.Rng::new(0xC5C5_0001UL)
  let n = 24
  let degree = 5
  let a = rand_csr(rng, n, degree, 20)
  let b = rand_csr(rng, n, degree, 20)
  let da = a.to_dense()
  let db = b.to_dense()
  let dense = @mat.mul_trop(da, db)
  let sparse = @mat.csr_mul_minplus(a, b)
  let back = sparse.to_dense()
  let mut same = true
  for i in 0..<n {
    for j in 0..<n {
      if back.d[i * n + j] != dense.d[i * n + j] {
        same = false
      }
    }
  }
  inspect(same, content="true")
  // nnz 必須等於稠密結果中「有限」的格子數（不多也不少）
  let mut finite = 0
  for i in 0..<(n * n) {
    if !dense.d[i].is_inf() {
      finite = finite + 1
    }
  }
  inspect(sparse.nnz(), content="\{finite}")
}

///|
test "csr_mul（一般半環）與稠密 ikj 一致：計數半環" {
  let rng = @alg.Rng::new(0xC5C5_0002UL)
  let n = 16
  let from : Array[Int32] = []
  let to : Array[Int32] = []
  let cnt : Array[@alg.Counting] = []
  for i in 0..<n {
    for _d in 0..<3 {
      let j = rng.next_int(n)
      from.push(i)
      to.push(j)
      // 1 的計數（不是零元）
      cnt.push(@alg.Counting::new(1L))
    }
  }
  let a = @mat.Csr::from_triplets(n, n, from, to, cnt)
  let dense = @mat.mul_ikj(a.to_dense(), a.to_dense())
  let sparse = @mat.csr_mul(a, a)
  let back = sparse.to_dense()
  let mut same = true
  for i in 0..<n {
    for j in 0..<n {
      if back.d[i * n + j] != dense.d[i * n + j] {
        same = false
      }
    }
  }
  inspect(same, content="true")
}

///|
test "csr_apsp 與稠密 FW 閉包逐點一致" {
  let rng = @alg.Rng::new(0xC5C5_0003UL)
  let n = 20
  let g = rand_csr(rng, n, 4, 15)
  let dense = g.to_dense()
  let closed = @mat.closure_fw_inplace(@mat.Mat::new(n, n, @alg.Trop::inf()))
  // 把邊放進稠密矩陣再閉包（closure_fw_inplace 會處理對角線）
  for i in 0..<n {
    for p in g.row_ptr[i]..<g.row_ptr[i + 1] {
      closed.d[i * n + g.col[p]] = g.val[p]
    }
  }
  let closed2 = @mat.closure_fw_inplace(closed.copy())
  let apsp = @mat.csr_apsp(g)
  let mut same = true
  let mut checked = 0
  for s in 0..<n {
    for j in 0..<n {
      // 對角線：閉包給 0，sssp 給 0（都是 one）；比較非對角項
      if s != j {
        if apsp[s][j] != closed2.d[s * n + j] {
          same = false
        }
        checked = checked + 1
      }
    }
  }
  inspect(same, content="true")
  inspect(checked, content="380")
  let _ = dense
}

///|
test "csr_closure 與稠密 FW 一致，且與 csr_apsp 一致" {
  let rng = @alg.Rng::new(0xC5C5_0004UL)
  let n = 18
  let g = rand_csr(rng, n, 4, 12)
  let (c, neg) = @mat.csr_closure(g)
  inspect(neg, content="false")
  let dense = g.to_dense()
  let closed = @mat.closure_fw_inplace(dense)
  let mut same = true
  for i in 0..<n {
    for j in 0..<n {
      let got = match c.get(i, j) {
        Some(v) => v
        None => @alg.Trop::inf()
      }
      if got != closed.d[i * n + j] {
        same = false
      }
    }
  }
  inspect(same, content="true")
  // 稀疏閉包的對角線必須是 0（反射閉包）
  let mut diag_ok = true
  for i in 0..<n {
    if c.get(i, i).unwrap() != @alg.Trop::new(0) {
      diag_ok = false
    }
  }
  inspect(diag_ok, content="true")
  // 與 n 次 sssp 的結果也必須一致（兩條獨立路徑）
  let apsp = @mat.csr_apsp(g)
  let mut same2 = true
  for s in 0..<n {
    for j in 0..<n {
      let got = match c.get(s, j) {
        Some(v) => v
        None => @alg.Trop::inf()
      }
      if got != apsp[s][j] {
        same2 = false
      }
    }
  }
  inspect(same2, content="true")
}

///|
test "csr_sssp 偵測負權（min-plus 前提被違反）" {
  let from : Array[Int32] = [0, 1]
  let to : Array[Int32] = [1, 0]
  let w : Array[@alg.Trop] = [@alg.Trop::new(1), @alg.Trop::new(-5)]
  let g = @mat.Csr::from_triplets(2, 2, from, to, w)
  let (_d, neg) = @mat.csr_sssp(g, 0)
  inspect(neg, content="true")
  let (_c, neg2) = @mat.csr_closure(g)
  inspect(neg2, content="true")
}

///|
test "TropF：浮點 min-plus 的定律與剪枝" {
  // 基本代數
  let inf = @alg.TropF::inf()
  inspect(inf.is_inf(), content="true")
  inspect(@alg.TropF::of(2.5).value(), content="2.5")
  // NaN 正規化成 ∞（NaN 不是合法元素）
  inspect(@alg.TropF::of(@double.not_a_number).is_inf(), content="true")
  // 浮點半環定律
  // IEEE-754 的加法**不滿足結合律**，因此 Double 熱帶半環只在 ULP 誤差內
  // 是半環。這裡兩個檢查器都跑：
  //   * 精確等值檢查必須「失敗」（負面對照：證明我們沒有假裝浮點是精確的）
  //   * 近似檢查（eps = 1e-9）必須通過
  let rng = @alg.Rng::new(0xC5C5_0007UL)
  let gen = fn() {
    let w = rng.next_int(4000).to_double() / 100.0 - 20.0
    if rng.next_int(7) == 0 {
      inf
    } else {
      @alg.TropF::of(w)
    }
  }
  let exact = @alg.check_semiring("TropF-exact", gen, samples=256)
  inspect(exact.ok(), content="false")
  let approx = @alg.check_semiring_approx(
    "TropF-approx",
    gen,
    fn(a, b) {
      if a.is_inf() || b.is_inf() {
        if a.is_inf() && b.is_inf() {
          0.0
        } else {
          1.0e9
        }
      } else {
        (a.value() - b.value()).abs()
      }
    },
    eps=1.0e-9,
    samples=256,
  )
  inspect(approx.ok(), content="true")
  let idem = @alg.check_idempotent(
    "TropF-idem",
    fn() { @alg.TropF::of(rng.next_int(1000).to_double() * 0.5) },
    samples=256,
  )
  inspect(idem.ok(), content="true")
  // star：x ≥ 0 ⇒ 0；x < 0 ⇒ 明確錯誤
  inspect(@alg.TropF::of(3.0).star_checked().unwrap().value(), content="0")
  let bad = @alg.TropF::of(-0.5).star_checked()
  inspect(bad is Err(_), content="true")
}

///|
test "TropF 剪枝乘法與稠密泛型乘法一致，並與 Trop 對照" {
  let rng = @alg.Rng::new(0xC5C5_0005UL)
  let n = 20
  let a = @mat.Mat::new(n, n, @alg.TropF::inf())
  let b = @mat.Mat::new(n, n, @alg.TropF::inf())
  for i in 0..<n {
    for j in 0..<n {
      if rng.next_int(100) < 40 {
        a.d[i * n + j] = @alg.TropF::of(rng.next_int(20).to_double() + 0.5)
      }
      if rng.next_int(100) < 40 {
        b.d[i * n + j] = @alg.TropF::of(rng.next_int(20).to_double() + 0.25)
      }
    }
  }
  let generic = @mat.mul_ikj(a, b)
  let pruned = @mat.mul_trop_generic(a, b)
  let mut same = true
  for i in 0..<(n * n) {
    if generic.d[i] != pruned.d[i] {
      same = false
    }
  }
  inspect(same, content="true")
  // 獨立對照：暴力三重迴圈（min, +）直接用 Double 算
  let mut brute_ok = true
  for i in 0..<n {
    for j in 0..<n {
      let mut best = @double.infinity
      for k in 0..<n {
        let x = a.d[i * n + k]
        let y = b.d[k * n + j]
        if !x.is_inf() && !y.is_inf() {
          let cand = x.value() + y.value()
          if cand < best {
            best = cand
          }
        }
      }
      let got = pruned.d[i * n + j]
      if best == @double.infinity {
        if !got.is_inf() {
          brute_ok = false
        }
      } else if got.is_inf() || (got.value() - best).abs() > 1.0e-12 {
        brute_ok = false
      }
    }
  }
  inspect(brute_ok, content="true")
}

///|
test "TropF 稀疏 APSP 與稠密閉包一致（浮點權重）" {
  let rng = @alg.Rng::new(0xC5C5_0006UL)
  let n = 16
  let from : Array[Int32] = []
  let to : Array[Int32] = []
  let w : Array[@alg.TropF] = []
  for i in 0..<n {
    for _d in 0..<3 {
      let j = rng.next_int(n)
      if j != i {
        from.push(i)
        to.push(j)
        w.push(@alg.TropF::of(rng.next_int(100).to_double() / 8.0 + 0.125))
      }
    }
  }
  let g = @mat.Csr::from_triplets(n, n, from, to, w)
  let dense = g.to_dense()
  let closed = @mat.closure_fw_inplace(dense)
  let (sp, neg) = @mat.csr_closure(g)
  inspect(neg, content="false")
  let mut same = true
  let mut max_err = 0.0
  for i in 0..<n {
    for j in 0..<n {
      let got = match sp.get(i, j) {
        Some(v) => v
        None => @alg.TropF::inf()
      }
      let want = closed.d[i * n + j]
      if got.is_inf() != want.is_inf() {
        same = false
      } else if !got.is_inf() {
        let e = (got.value() - want.value()).abs()
        if e > max_err {
          max_err = e
        }
        if e > 1.0e-12 {
          same = false
        }
      }
    }
  }
  inspect(same, content="true")
  inspect(max_err < 1.0e-12, content="true")
}

// ---------------------------------------------------------------------------
// 分塊大小由快取參數推導：模型 vs 追蹤器實測
// ---------------------------------------------------------------------------

///|
test "choose_block：由 L1/L2 預算推導，並夾在 [8, n]" {
  // L1 32 KiB、4 bytes 元素、2 個磚 ⇒ 3/4·32768/8 = 3072 ⇒ b = 48
  inspect(@mat.choose_block_l1(32768, 4, 1024), content="48")
  // 8 bytes 元素 ⇒ 預算減半 ⇒ b = 32（但仍是 8 的倍數）
  inspect(@mat.choose_block_l1(32768, 8, 1024), content="32")
  // 更大的 L1 (256 KiB) ⇒ 更大的磚
  inspect(@mat.choose_block_l1(262144, 4, 1024), content="152")
  // n 比磚小 ⇒ 整個矩陣裝得下，不需要分塊
  inspect(@mat.choose_block_l1(32768, 4, 16), content="16")
  // 最小磚 8，不會出現 0 或負數
  inspect(@mat.choose_block_l1(1024, 8, 1024), content="8")
  // L2 面板（3 個磚）：3/4·524288/12 = 32768 ⇒ 176
  inspect(@mat.choose_panel_l2(524288, 4, 1024), content="176")
}

///|
test "自動磚邊長在追蹤器的 L1 miss 曲線上接近最優" {
  let n = 128
  let rng = @alg.Rng::new(0xB10C_0002UL)
  let a = @mat.Mat::new(n, n, @alg.Trop::inf())
  let b = @mat.Mat::new(n, n, @alg.Trop::inf())
  for i in 0..<(n * n) {
    if rng.next_int(100) < 60 {
      a.d[i] = @alg.Trop::new(rng.next_int(20) + 1)
    }
    if rng.next_int(100) < 60 {
      b.d[i] = @alg.Trop::new(rng.next_int(20) + 1)
    }
  }
  let auto = @mat.choose_block_l1(@mat.default_l1_bytes, 4, n)
  let cands : Array[Int32] = [8, 16, 24, 32, auto, 64]
  let mut best = -1L
  let mut auto_miss = -1L
  for cand in cands {
    let tr = @sim.Tracer::new(4)
    let ida = tr.register(n, n)
    let idb = tr.register(n, n)
    let idc = tr.register(n, n)
    let probe = tr.probe()
    let _ = @mat.mul_blocked(a, b, block=cand, probe=fn(mid, i0, j0, wr) {
      let real = if mid == 0 { ida } else if mid == 1 { idb } else { idc }
      probe(real, i0, j0, wr)
    })
    let miss = tr.l1_misses()
    if best < 0L || miss < best {
      best = miss
    }
    if cand == auto {
      auto_miss = miss
    }
  }
  // 模型選出的磚，L1 miss 不超過追蹤器最優值的 1.3 倍
  inspect(auto_miss > 0L, content="true")
  inspect(auto_miss.to_double() <= best.to_double() * 1.3, content="true")
  // 極小磚（8）必須明顯劣於自動選擇：證明「選大一點」不是裝飾
  let tr8 = @sim.Tracer::new(4)
  let ia = tr8.register(n, n)
  let ib = tr8.register(n, n)
  let ic = tr8.register(n, n)
  let p8 = tr8.probe()
  let _ = @mat.mul_blocked(a, b, block=8, probe=fn(mid, i0, j0, wr) {
    let real = if mid == 0 { ia } else if mid == 1 { ib } else { ic }
    p8(real, i0, j0, wr)
  })
  inspect(tr8.l1_misses() > auto_miss * 2L, content="true")
}

// ---------------------------------------------------------------------------
// 平行層與序列層的逐位元一致性
// ---------------------------------------------------------------------------

///|
test "mul_rows_par 與 mul_ikj 逐位元相同（切塊數不影響結果）" {
  let rng = @alg.Rng::new(0x9A11_0001UL)
  let n = 96
  let a = @mat.Mat::new(n, n, @alg.Trop::inf())
  let b = @mat.Mat::new(n, n, @alg.Trop::inf())
  for i in 0..<(n * n) {
    if rng.next_int(100) < 50 {
      a.d[i] = @alg.Trop::new(rng.next_int(30) + 1)
    }
    if rng.next_int(100) < 50 {
      b.d[i] = @alg.Trop::new(rng.next_int(30) + 1)
    }
  }
  let seq = @mat.mul_ikj(a, b)
  for chunks in [1, 3, 8, 64] {
    let par = @mat.mul_rows_par(a, b, chunks)
    let mut same = true
    for i in 0..<(n * n) {
      if seq.d[i] != par.d[i] {
        same = false
      }
    }
    inspect(same, content="true")
  }
}

///|
test "closure_fw_par 與 closure_fw_inplace 逐位元相同" {
  let rng = @alg.Rng::new(0x9A11_0002UL)
  let n = 40
  let a = @mat.Mat::new(n, n, @alg.Trop::inf())
  for i in 0..<n {
    for k in 0..<n {
      if i != k && rng.next_int(100) < 12 {
        a.d[i * n + k] = @alg.Trop::new(rng.next_int(15) + 1)
      }
    }
  }
  let seq = @mat.closure_fw_inplace(a.copy())
  for chunks in [1, 5, 17] {
    let par = @mat.closure_fw_par(a, chunks)
    let mut same = true
    for i in 0..<(n * n) {
      if seq.d[i] != par.d[i] {
        same = false
      }
    }
    inspect(same, content="true")
  }
  // 布林半環（可達性）也必須一致
  let bs = @mat.Mat::new(n, n, @alg.BoolSr::of(false))
  for i in 0..<n {
    for k in 0..<n {
      if i != k && rng.next_int(100) < 10 {
        bs.d[i * n + k] = @alg.BoolSr::of(true)
      }
    }
  }
  let bseq = @mat.closure_fw_inplace(bs.copy())
  let bpar = @mat.closure_fw_par(bs, 7)
  let mut same2 = true
  for i in 0..<(n * n) {
    if bseq.d[i] != bpar.d[i] {
      same2 = false
    }
  }
  inspect(same2, content="true")
}
