// algorithms.mbt 白盒測試：精煉演算法結果一致且步數更低。

// 測試 1：模冪——平方-乘 O(log e) vs 連乘 O(e)

///|
test "algorithms_pow_mod" {
  let (r1, s1) = pow_mod_steps(3, 100, 97)
  let (r2, s2) = naive_pow_steps(3, 100, 97)
  assert_eq(r1, r2)
  assert_eq(r1, pow_mod(3, 100, 97))
  assert_eq(s2, 100)
  // 精煉步數 ≤ 2⌈log₂100⌉ = 14
  assert_eq(s1 <= 14, true)
  assert_eq(s1 < s2, true)
}

// 測試 2：矩陣乘法——Strassen O(n^2.807) vs 朴素 O(n³)

///|
test "algorithms_mat_mul" {
  let aa = make_mat(4, 4, 97, [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 16],
  ])
  let bb = make_mat(4, 4, 97, [
    [16, 15, 14, 13],
    [12, 11, 10, 9],
    [8, 7, 6, 5],
    [4, 3, 2, 1],
  ])
  let (r1, s1) = mat_mul_steps(aa, bb)
  let (r2, s2) = mat_mul_strassen_steps(aa, bb)
  assert_eq(mat_eq(r1, r2), true)
  assert_eq(mat_eq(r1, mat_mul(aa, bb)), true)
  assert_eq(s1, 64)
  // Strassen 4×4：7² = 49 次模乘
  assert_eq(s2, 49)
  assert_eq(s2 < s1, true)
}

// 測試 3：多項式乘法——NTT O(n log n) vs 朴素 O(n²)

///|
test "algorithms_poly_mul" {
  let p = 998244353
  let aa = Array::makei(64, fn(i) { (i * 7 + 3) % p })
  let bb = Array::makei(64, fn(i) { (i * 5 + 1) % p })
  let (r1, s1) = poly_mul_naive_steps(aa, bb, p)
  let (r2, s2) = poly_mul_ntt_steps(aa, bb, p, 3)
  assert_eq(r1, r2)
  assert_eq(r2, poly_mul_ntt(aa, bb, p, 3))
  assert_eq(s1, 64 * 64)
  // NTT：3 次變換 × 6 級 × 32 蝶 × 2 模乘 + 點值乘 + 逆變換縮放
  assert_eq(s2 < s1, true)
}

// 測試 4：Karatsuba O(n^1.585) vs 學校式 O(n²)

///|
test "algorithms_karatsuba" {
  let p = 998244353
  let aa = Array::makei(8, fn(i) { (i * 3 + 1) % p })
  let bb = Array::makei(8, fn(i) { (i * 2 + 5) % p })
  let (r1, s1) = karatsuba_steps(aa, bb, p)
  let (r2, s2) = poly_mul_naive_steps(aa, bb, p)
  assert_eq(r1, r2)
  assert_eq(r1, karatsuba(aa, bb, p))
  assert_eq(s2, 64)
  // Karatsuba：T(8) = 3·T(4) = 27
  assert_eq(s1, 27)
  assert_eq(s1 < s2, true)
}

// 測試 5：zeta 變換 O(n·2ⁿ) vs 朴素 O(4ⁿ)

///|
test "algorithms_zeta" {
  let p = 97
  let f = Array::makei(16, fn(i) { (i * 5 + 2) % p })
  let (r1, s1) = zeta_naive_steps(f, p)
  let (r2, s2) = zeta_steps(f, p)
  assert_eq(r1, r2)
  assert_eq(r2, zeta_transform(f, p))
  assert_eq(s1, 256)
  // 每個 i（2 的冪）恰有一半 s 滿足 (s & i) ≠ 0
  assert_eq(s2, 4 * 8)
  assert_eq(s2 < s1, true)
}

// 測試 6：證明網正確性——GMM 收縮 vs DR switching

///|
test "algorithms_proof_net" {
  // 星形網：4 個並鏈匯入張量樹
  let nodes : Array[NetNode] = []
  for _ in 0..<4 {
    nodes.push(mk_axiom())
    nodes.push(mk_axiom())
  }
  for i in 0..<4 {
    nodes.push(mk_par(2 * i, 2 * i + 1))
  }
  nodes.push(mk_tensor(8, 9))
  nodes.push(mk_tensor(12, 10))
  nodes.push(mk_tensor(13, 11))
  let net = ProofNet::{ nodes, }
  assert_eq(net_is_correct(net), true)
  // DR 工作量：2⁴ = 16 個 switching，各 O(n)
  let dr = dr_switching_run(net)
  let gmm = gmm_parsing_steps(net)
  assert_eq(dr > gmm, true)
  assert_eq(dr_switching_steps(net), 16 * 15)
}

// 測試 7：群公理驗證——模型對照 O(n²) vs 暴力 O(n³)

///|
test "algorithms_group_check" {
  let gg = cyclic_group(5)
  let model = Array::makei(5, fn(i) { Array::makei(5, fn(j) { (i + j) % 5 }) })
  let (r1, s1) = check_group_naive_steps(gg)
  let (r2, s2) = check_group_model_steps(gg, model)
  assert_eq(r1, true)
  assert_eq(r2, true)
  assert_eq(r1 == r2, true)
  assert_eq(check_group(gg), true)
  // naive：Latin 檢查 n² + 結合律 n³ = 25 + 125
  assert_eq(s1, 150)
  assert_eq(s2, 25)
  assert_eq(s2 < s1, true)
}

// 測試 8：非群模型被對照檢查拒絕

///|
test "algorithms_group_model_reject" {
  let gg = cyclic_group(3)
  let bad = Array::makei(3, fn(i) { Array::makei(3, fn(j) { (i + j + 1) % 3 }) })
  let (r2, _s2) = check_group_model_steps(gg, bad)
  assert_eq(r2, false)
}
