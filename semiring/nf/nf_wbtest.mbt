// ===========================================================================
// 規範形式的測試
// ===========================================================================

///|
fn abc_alphabet() -> Array[Int32] {
  [0, 1, 2]
}

///|
test "ACI 正規形：⊕ 的結合、交換、冪等真的被壓掉" {
  let a = RChar(0)
  let b = RChar(1)
  let c = RChar(2)
  // (a+b)+c = a+(b+c)
  assert_eq(regex_cmp(r_sum(r_sum(a, b), c), r_sum(a, r_sum(b, c))), 0)
  // a+b = b+a
  assert_eq(regex_cmp(r_sum(a, b), r_sum(b, a)), 0)
  // a+a = a
  assert_eq(regex_cmp(r_sum(a, a), a), 0)
  // a+0 = a
  assert_eq(regex_cmp(r_sum(a, RZero), a), 0)
}

///|
test "ACI 正規形：⊗ 的單位與吸收元" {
  assert_eq(regex_cmp(r_prod(RZero, RChar(0)), RZero), 0)
  assert_eq(regex_cmp(r_prod(ROne, RChar(0)), RChar(0)), 0)
  assert_eq(regex_cmp(r_star(RZero), ROne), 0)
  assert_eq(regex_cmp(r_star(ROne), ROne), 0)
  assert_eq(regex_cmp(r_star(r_star(RChar(0))), r_star(RChar(0))), 0)
}

///|
test "導數：∂a(a) = ε、∂b(a) = ∅、∂a(ab) = b" {
  let a = RChar(0)
  let b = RChar(1)
  assert_eq(regex_cmp(deriv(a, 0), ROne), 0)
  assert_eq(regex_cmp(deriv(a, 1), RZero), 0)
  assert_eq(regex_cmp(deriv(r_prod(a, b), 0), b), 0)
  // ∂a(a*) = a*
  assert_eq(regex_cmp(deriv(r_star(a), 0), r_star(a)), 0)
}

///|
test "Kleene 代數定律在最小 DFA 上成立（不是恆真：反向也檢查）" {
  let al = abc_alphabet()
  let a = RChar(0)
  let b = RChar(1)
  // (a+b)* = (a* b*)*
  let lhs = r_star(r_sum(a, b))
  let rhs = r_star(r_prod(r_star(a), r_star(b)))
  assert_true(regex_equiv(lhs, rhs, al))
  // (ab)* a = a (ba)*
  let l2 = r_prod(r_star(r_prod(a, b)), a)
  let r2 = r_prod(a, r_star(r_prod(b, a)))
  assert_true(regex_equiv(l2, r2, al))
  // (a*)* = a*
  assert_true(regex_equiv(r_star(r_star(a)), r_star(a), al))
  // 反面：a* ≠ a
  assert_false(regex_equiv(r_star(a), a, al))
  // 反面：(a+b)* ≠ a*b*
  assert_false(
    regex_equiv(r_star(r_sum(a, b)), r_prod(r_star(a), r_star(b)), al),
  )
}

///|
test "最小化：結果是最小的（再最小化不變）且語言不變" {
  let al = abc_alphabet()
  // (a+b)*abb 這類含冗餘狀態的表示式
  let r = r_prod(r_star(r_sum(RChar(0), RChar(1))), r_prod(RChar(0), RChar(1)))
  let d = dfa_of_regex(r, al)
  let m = dfa_minimize(d)
  let m2 = dfa_minimize(m)
  assert_eq(m.nstates(), m2.nstates())
  assert_true(dfa_equiv(d, m))
  // 未最小化的狀態數必然 ≥ 最小化的
  assert_true(d.nstates() >= m.nstates())
}

///|
test "正規形字串：同一語言的兩個不同寫法給出同一個字串" {
  let al = abc_alphabet()
  let a = RChar(0)
  let b = RChar(1)
  // (a|b)* 的兩種寫法
  let e1 = r_star(r_sum(a, b))
  let e2 = r_star(r_sum(b, a))
  let c1 = dfa_canonical(dfa_minimize(dfa_of_regex(e1, al)))
  let c2 = dfa_canonical(dfa_minimize(dfa_of_regex(e2, al)))
  assert_true(c1 == c2)
  // 不同語言的字串必須不同
  let e3 = r_prod(r_star(a), r_star(b))
  let c3 = dfa_canonical(dfa_minimize(dfa_of_regex(e3, al)))
  assert_false(c1 == c3)
}

///|
test "自動機與暴力比對：所有長度 ≤ 5 的字串" {
  let al = abc_alphabet()
  let a = RChar(0)
  let b = RChar(1)
  let r = r_star(r_prod(r_sum(a, b), r_sum(a, b)))
  let d = dfa_minimize(dfa_of_regex(r, al))
  let mut compared = 0
  for len in 0..<6 {
    let total = if len == 0 { 1 } else { pow3(len) }
    for code in 0..<total {
      let w = decode(code, len)
      // 偶數長度（含 0）的 a/b 字串
      let expect = len % 2 == 0 && all_ab(w)
      assert_eq(d.accepts(w), expect)
      assert_eq(rx_accepts(r, w), expect)
      compared = compared + 1
    }
  }
  assert_eq(compared, 1 + 3 + 9 + 27 + 81 + 243)
}

///|
fn pow3(n : Int32) -> Int32 {
  let mut p = 1
  for _ in 0..<n {
    p = p * 3
  }
  p
}

///|
fn decode(code : Int32, len : Int32) -> Array[Int32] {
  let out : Array[Int32] = Array::make(len, 0)
  let mut c = code
  for i in 0..<len {
    out[len - 1 - i] = c % 3
    c = c / 3
  }
  out
}

///|
fn all_ab(w : Array[Int32]) -> Bool {
  for c in w {
    if c > 1 {
      return false
    }
  }
  true
}

///|
test "反向語言：L(r^R) = L(r)^R（以最短字串抽樣比對）" {
  let al = abc_alphabet()
  let a = RChar(0)
  let b = RChar(1)
  let r = r_prod(r_star(a), r_prod(b, r_star(a)))
  let d = dfa_minimize(dfa_of_regex(r, al))
  let dr = dfa_reverse(d)
  for code in 0..<27 {
    let w = decode(code, 3)
    let rev : Array[Int32] = [w[2], w[1], w[0]]
    assert_eq(dr.accepts(rev), d.accepts(w))
  }
}

///|
test "半環正規形：分配律、結合律、冪等律被判定成立" {
  let a = SVar(0)
  let b = SVar(1)
  let c = SVar(2)
  // a(b+c) = ab+ac
  assert_true(
    idempotent_identity_holds(
      SProd(a, SSum(b, c)),
      SSum(SProd(a, b), SProd(a, c)),
    ),
  )
  // (a+b)+c = a+(b+c)
  assert_true(
    idempotent_identity_holds(SSum(SSum(a, b), c), SSum(a, SSum(b, c))),
  )
  // a+a = a（冪等）
  assert_true(idempotent_identity_holds(SSum(a, a), a))
  // a·1 = a、a·0 = 0
  assert_true(idempotent_identity_holds(SProd(a, SOne), a))
  assert_true(idempotent_identity_holds(SProd(a, SZero), SZero))
}

///|
test "半環正規形：非平凡的相等與不相等都判對" {
  let a = SVar(0)
  let b = SVar(1)
  // (a+b)(a+b) = aa + ab + ba + bb，而不是 a+b
  let lhs = SProd(SSum(a, b), SSum(a, b))
  let rhs = SSum(SSum(SProd(a, a), SProd(a, b)), SSum(SProd(b, a), SProd(b, b)))
  assert_true(idempotent_identity_holds(lhs, rhs))
  assert_false(idempotent_identity_holds(lhs, SSum(a, b)))
  // 非交換：ab ≠ ba（本庫的半環不假設交換的 ⊗）
  assert_false(idempotent_identity_holds(SProd(a, b), SProd(b, a)))
}

///|
test "兩條判定路徑（多項式正規形 vs 最小 DFA）永遠一致" {
  let rng = @alg.Rng::new(424242UL)
  let mut compared = 0
  for _ in 0..<40 {
    let e1 = random_sexpr(rng, 3)
    let e2 = random_sexpr(rng, 3)
    let via_poly = idempotent_identity_holds(e1, e2)
    let via_dfa = idempotent_identity_holds_via_dfa(e1, e2)
    assert_eq(via_poly, via_dfa)
    compared = compared + 1
  }
  assert_eq(compared, 40)
}

///|
fn random_sexpr(rng : @alg.Rng, depth : Int32) -> SExpr {
  if depth == 0 {
    let k = rng.next_int(5)
    if k == 0 {
      SZero
    } else if k == 1 {
      SOne
    } else {
      SVar(rng.next_int(3))
    }
  } else {
    let k = rng.next_int(4)
    if k == 0 {
      SSum(random_sexpr(rng, depth - 1), random_sexpr(rng, depth - 1))
    } else if k == 1 {
      SProd(random_sexpr(rng, depth - 1), random_sexpr(rng, depth - 1))
    } else {
      random_sexpr(rng, 0)
    }
  }
}

///|
test "隨機表示式：最小 DFA 與暴力判定在長度 ≤ 4 的字上一致" {
  let al = abc_alphabet()
  let rng = @alg.Rng::new(8888UL)
  for _ in 0..<10 {
    let r = random_regex(rng, 3)
    let d = dfa_minimize(dfa_of_regex(r, al))
    for len in 0..<5 {
      let total = pow3(len)
      for code in 0..<total {
        let w = decode(code, len)
        assert_eq(d.accepts(w), rx_accepts(r, w))
      }
    }
  }
}

///|
fn random_regex(rng : @alg.Rng, depth : Int32) -> Regex {
  if depth == 0 {
    let k = rng.next_int(5)
    if k == 0 {
      RZero
    } else if k == 1 {
      ROne
    } else {
      RChar(rng.next_int(2))
    }
  } else {
    let k = rng.next_int(5)
    if k == 0 {
      r_sum(random_regex(rng, depth - 1), random_regex(rng, depth - 1))
    } else if k == 1 {
      r_prod(random_regex(rng, depth - 1), random_regex(rng, depth - 1))
    } else if k == 2 {
      r_star(random_regex(rng, depth - 1))
    } else {
      random_regex(rng, 0)
    }
  }
}
