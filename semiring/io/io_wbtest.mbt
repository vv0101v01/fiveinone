// ===========================================================================
// io 套件測試
// ===========================================================================

///|
test "兩種載入器結果完全一致（含註解、空行、多餘空白）" {
  let text = "# comment\n0 1 5\n\n1 2 7\n 2   3   9 \n3 4 1\n"
  let a = parse_edges_naive(text)
  let b = parse_edges_fast(@utf8.encode(text))
  assert_eq(a.n, b.n)
  assert_eq(a.from, b.from)
  assert_eq(a.to, b.to)
  assert_eq(a.w, b.w)
  assert_eq(b.n, 5)
  assert_eq(b.from.length(), 4)
}

///|
test "載入器處理大輸入：兩種方法結果一致" {
  let rng = @alg.Rng::new(0xDEAD_0001UL)
  let text = synth_edge_list(rng, 500, 20000)
  let bytes = synth_edge_bytes(@alg.Rng::new(0xDEAD_0001UL), 500, 20000)
  let a = parse_edges_naive(text)
  let b = parse_edges_fast(bytes)
  assert_eq(a.from.length(), 20000)
  assert_eq(a.from, b.from)
  assert_eq(a.to, b.to)
  assert_eq(a.w, b.w)
}

///|
test "單趟掃描對退化輸入的穩健性" {
  // 空輸入
  let e = parse_edges_fast(@utf8.encode(""))
  assert_eq(e.n, 0)
  assert_eq(e.from.length(), 0)
  // 只有註解
  let c = parse_edges_fast(@utf8.encode("# a\n# b\n"))
  assert_eq(c.from.length(), 0)
  // 欄位不足的行會被忽略
  let d = parse_edges_fast(@utf8.encode("1 2\n3 4 5\n"))
  assert_eq(d.from.length(), 1)
}
