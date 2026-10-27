///|
/// 代數結構測試：Grp、Ab、Vectₖ
test "cyclic group C5 is a group" {
  let g = cyclic_group(5)
  assert_true(check_group(g))
  assert_true(is_abelian(g))
  assert_eq(g.order, 5)
  assert_eq(element_order(g, 2), 5)
}

///|
test "symmetric group S3" {
  let g = symmetric_group(3)
  assert_eq(g.order, 6)
  assert_true(check_group(g))
  assert_false(is_abelian(g))
  // 共軛類：單位元、對換（3 個）、三循環（2 個）
  let cls = conjugacy_classes(g)
  assert_eq(cls.length(), 3)
}

///|
test "symmetric group S4" {
  let g = symmetric_group(4)
  assert_eq(g.order, 24)
  assert_true(check_group(g))
}

///|
test "direct product C2 × C3 ≅ C6" {
  let g = direct_product(cyclic_group(2), cyclic_group(3))
  assert_eq(g.order, 6)
  assert_true(check_group(g))
  assert_true(is_abelian(g))
  // C2×C3 是循環群（因 gcd(2,3)=1）：存在 6 階元素
  let mut has6 = false
  for x in 0..<g.order {
    if element_order(g, x) == 6 {
      has6 = true
      break
    }
  }
  assert_true(has6)
}

///|
test "abelianization of S3 is C2" {
  let s3 = symmetric_group(3)
  let ab = abelianization(s3)
  assert_eq(ab.order, 2)
  assert_true(check_group(ab))
  assert_true(is_abelian(ab))
}

///|
test "abelianization of abelian group is itself" {
  let c4 = cyclic_group(4)
  let ab = abelianization(c4)
  assert_eq(ab.order, 4)
}

///|
test "center of S3 is trivial" {
  let s3 = symmetric_group(3)
  assert_eq(center(s3).length(), 1)
}

///|
test "center of D4... use C2×C2" {
  let g = direct_product(cyclic_group(2), cyclic_group(2))
  assert_eq(center(g).length(), 4)
}

///|
test "subgroup closure" {
  let s3 = symmetric_group(3)
  // 由一個對換生成的子群（階為 2）
  let sub = subgroup_closure(s3, [1])
  assert_eq(sub.length(), 2)
}

///|
test "group model verification O(n^2)" {
  let g = cyclic_group(7)
  let model = Array::makei(7, fn(a) { Array::makei(7, fn(b) { (a + b) % 7 }) })
  assert_true(check_group_model(g, model))
}

///|
test "matrix multiply and strassen agree" {
  let p = 998244353
  let aa = Mat::{ rows: 2, cols: 2, p, data: [[1, 2], [3, 4]], }
  let bb = Mat::{ rows: 2, cols: 2, p, data: [[5, 6], [7, 8]], }
  let naive = mat_mul(aa, bb)
  let fast = mat_mul_strassen(aa, bb)
  assert_eq(naive.data, fast.data)
  // [[19, 22], [43, 50]]
  assert_eq(naive.data[0], [19, 22])
  assert_eq(naive.data[1], [43, 50])
}

///|
test "matrix rank and inverse" {
  let p = 7
  let aa = Mat::{
    rows: 3,
    cols: 3,
    p,
    data: [[1, 2, 3], [4, 5, 6], [2, 4, 1]],
  }
  assert_eq(mat_rank(aa), 3)
  let inv = mat_inv(aa)
  match inv {
    Some(m) => {
      let prod = mat_mul(aa, m)
      assert_eq(prod.data, mat_identity(3, p).data)
    }
    None => assert_true(false)
  }
  // 奇異矩陣
  let bb = Mat::{
    rows: 3,
    cols: 3,
    p,
    data: [[1, 2, 3], [2, 4, 6], [1, 1, 1]],
  }
  assert_eq(mat_rank(bb), 2)
  match mat_inv(bb) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "determinant" {
  let p = 998244353
  let aa = Mat::{
    rows: 3,
    cols: 3,
    p,
    data: [[6, 1, 1], [4, -2, 5], [2, 8, 7]],
  }
  // det = 6(-2·7-5·8) - 1(4·7-5·2) + 1(4·8+2·2) = 6(-54) - 18 + 36 = -324+18 = -306
  assert_eq(mat_det(aa), -306 % p + p)
}

///|
test "linear solve" {
  let p = 7
  let aa = Mat::{ rows: 2, cols: 2, p, data: [[3, 1], [1, 2]], }
  match mat_solve(aa, [5, 5]) {
    Some(x) =>
      // 3x+y=5, x+2y=5 mod 7 → x=1, y=2
      assert_eq(x, [1, 2])
    None => assert_true(false)
  }
}

///|
test "ntt polynomial multiplication" {
  let p = 998244353
  let root = 3
  let a = [1, 2, 3]
  let b = [4, 5, 6]
  let via_ntt = poly_mul_ntt(a, b, p, root)
  // 朴素：(1+2x+3x²)(4+5x+6x²) = 4 + 13x + 28x² + 27x³ + 18x⁴
  assert_eq(via_ntt, [4, 13, 28, 27, 18])
}

///|
test "karatsuba multiplication" {
  let p = 998244353
  let a = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
  let b = [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  let fast = karatsuba(a, b, p)
  // 朴素校驗
  let naive = Array::make(31, 0)
  for i in 0..<a.length() {
    for j in 0..<b.length() {
      naive[i + j] = (naive[i + j] + a[i] * b[j]) % p
    }
  }
  assert_eq(fast, naive)
}

///|
test "zeta and mobius transforms are inverse" {
  let p = 998244353
  let f = [1, 2, 3, 4, 5, 6, 7, 8]
  let g = zeta_transform(f, p)
  let back = mobius_transform(g, p)
  assert_eq(back, f)
  // g({0,1}) = f(∅)+f({0})+f({1})+f({0,1}) = 1+2+3+4 = 10
  assert_eq(g[3], 10)
}

///|
test "modular exponentiation" {
  assert_eq(pow_mod(2, 10, 1000), 24)
  assert_eq(pow_mod(3, 100, 7), 4)
}
