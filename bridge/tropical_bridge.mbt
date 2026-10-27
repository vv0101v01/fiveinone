///|
fn require_square_int64(a : Array[Array[Int64]]) -> Int32 {
  let n = a.length()
  for row in a {
    guard row.length() == n else { abort("tropical bridge: matrix not square") }
    for x in row {
      guard x > -400000000000000L && x < 400000000000000L else {
        abort("tropical bridge: entry outside finite bridge range")
      }
    }
  }
  n
}

///|
fn all_permutations(n : Int32, cap : Int32) -> Array[@sym.Perm] {
  let group = @sym.PermGroup::symmetric(n)
  guard group.order() <= cap.to_int64() else {
    abort("tropical bridge: permutation enumeration cap exceeded")
  }
  group.elements(cap)
}

///|
/// 一個指派在熱帶半環中的成本（普通整數和）。
pub fn assignment_cost(a : Array[Array[Int64]], p : @sym.Perm) -> Int64 {
  let n = require_square_int64(a)
  guard p.size() == n else { abort("assignment_cost: size mismatch") }
  let mut sum = 0L
  for i in 0..<n {
    sum = sum + a[i][p.apply(i)]
  }
  sum
}

///|
/// 所有達到 semiring `trop_det` 的指派，以 symlib 置換表達。
pub fn tropical_optimal_assignments(
  a : Array[Array[Int64]],
  cap : Int32,
) -> Array[@sym.Perm] {
  let n = require_square_int64(a)
  let best = @strop.trop_det(a)
  let out : Array[@sym.Perm] = []
  for p in all_permutations(n, cap) {
    if assignment_cost(a, p) == best {
      out.push(p)
    }
  }
  out
}

///|
/// 同時重標行與列仍保矩陣的置換：
/// `a[p(i)][p(j)] = a[i][j]`。這是完全二部加權圖在對角
/// 置換作用下的穩定子；它以共軛作用在指派集合上。
pub fn tropical_matrix_symmetries(
  a : Array[Array[Int64]],
  cap : Int32,
) -> Array[@sym.Perm] {
  let n = require_square_int64(a)
  let out : Array[@sym.Perm] = []
  for p in all_permutations(n, cap) {
    let mut ok = true
    for i in 0..<n {
      for j in 0..<n {
        if a[p.apply(i)][p.apply(j)] != a[i][j] {
          ok = false
        }
      }
    }
    if ok {
      out.push(p)
    }
  }
  out
}

///|
fn rat_of_int64(x : Int64) -> @exactalg.Rat {
  @exactalg.rat_big_int(BigInt::from_string(x.to_string()))
}

///|
/// 普通（非熱帶）永久式，以精確有理算術和 symlib 全置換枚舉計算。
pub fn exact_permanent_int64(
  a : Array[Array[Int64]],
  cap : Int32,
) -> @exactalg.Rat {
  let n = require_square_int64(a)
  let mut total = @exactalg.rat_zero()
  for p in all_permutations(n, cap) {
    let mut term = @exactalg.rat_one()
    for i in 0..<n {
      term = @exactalg.rat_mul(term, rat_of_int64(a[i][p.apply(i)]))
    }
    total = @exactalg.rat_add(total, term)
  }
  total
}

///|
/// 普通精確行列式，交由 cubical 精確 algebra 的 QMat 計算。
pub fn exact_determinant_int64(a : Array[Array[Int64]]) -> @exactalg.Rat {
  let n = require_square_int64(a)
  let rows : Array[Array[@exactalg.Rat]] = []
  for i in 0..<n {
    let row : Array[@exactalg.Rat] = []
    for j in 0..<n {
      row.push(rat_of_int64(a[i][j]))
    }
    rows.push(row)
  }
  @exactalg.qmat_det(@exactalg.qmat_from_rows(rows))
}

///|
fn is_prime_i32(p : Int32) -> Bool {
  guard p >= 2 else { return false }
  let mut d = 2
  while d * d <= p {
    if p % d == 0 {
      return false
    }
    d = d + 1
  }
  true
}

///|
fn bigint_padic_valuation(x0 : BigInt, p : Int32) -> Int32 {
  let bp = BigInt::from_int(p)
  let mut x = @exactalg.bigint_abs(x0)
  let mut count = 0
  while x % bp == 0N {
    x = x / bp
    count = count + 1
  }
  count
}

///|
/// 有理數的 p-進賦值；零回傳 None（熱帶像為 +∞）。
pub fn rat_padic_valuation(r : @exactalg.Rat, p : Int32) -> Int32? {
  guard is_prime_i32(p) else { abort("rat_padic_valuation: p is not prime") }
  if @exactalg.rat_is_zero(r) {
    return None
  }
  Some(bigint_padic_valuation(r.num, p) - bigint_padic_valuation(r.den, p))
}

///|
/// QPoly 以 p-進賦值熱帶化為 semiring UniPoly。
/// 零係數送到 semiring 的熱帶 +∞ 哨兵。
pub fn qpoly_tropicalize_padic(
  poly : @exactalg.QPoly,
  p : Int32,
) -> @strop.UniPoly {
  guard is_prime_i32(p) else {
    abort("qpoly_tropicalize_padic: p is not prime")
  }
  let degree = @exactalg.qpoly_degree(poly)
  if degree < 0 {
    return @strop.UniPoly::new([@semialg.trop_inf])
  }
  let coeffs : Array[Int32] = []
  for i in 0..<(degree + 1) {
    match rat_padic_valuation(@exactalg.qpoly_coeff(poly, i), p) {
      Some(v) => coeffs.push(v)
      None => coeffs.push(@semialg.trop_inf)
    }
  }
  @strop.UniPoly::new(coeffs)
}

///|
/// 熱帶橋接穿越檢查：
/// - 2×2 區塊矩陣有 8 個同時對稱、4 個最佳指派，且最佳集在
///   對稱共軛下封閉；
/// - 精確永久式/行列式由 Q 代數重算；
/// - (x-2)(x-4) 的 2-進熱帶根重數列是兩因子的併合 [1,2]。
pub fn check_tropical_bridges() -> Bool {
  let blocks : Array[Array[Int64]] = [
    [0L, 0L, 5L, 5L],
    [0L, 0L, 5L, 5L],
    [5L, 5L, 0L, 0L],
    [5L, 5L, 0L, 0L],
  ]
  let symmetries = tropical_matrix_symmetries(blocks, 32)
  let optima = tropical_optimal_assignments(blocks, 32)
  if symmetries.length() != 8 || optima.length() != 4 {
    return false
  }
  let best = @strop.trop_det(blocks)
  for s in symmetries {
    for q in optima {
      let conjugated = s.compose(q).compose(s.inverse())
      if assignment_cost(blocks, conjugated) != best {
        return false
      }
    }
  }
  let small : Array[Array[Int64]] = [[1L, 2L], [3L, 4L]]
  if !@exactalg.rat_eq(exact_permanent_int64(small, 4), @exactalg.rat_int(10)) ||
    !@exactalg.rat_eq(exact_determinant_int64(small), @exactalg.rat_int(-2)) {
    return false
  }
  let f = @exactalg.qpoly_root_factor(@exactalg.rat_int(2))
  let g = @exactalg.qpoly_root_factor(@exactalg.rat_int(4))
  let product = @exactalg.qpoly_mul(f, g)
  let roots = @strop.sort_rats(qpoly_tropicalize_padic(product, 2).roots())
  roots.length() == 2 &&
  roots[0].n == 1L &&
  roots[0].d == 1L &&
  roots[1].n == 2L &&
  roots[1].d == 1L
}
