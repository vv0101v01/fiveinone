///|
/// 偽函子（pseudofunctor）白盒測試。
/// 例：G = C_2 平凡作用於 D = BC_3，相干結構由非平凡 2-上循環
/// c(1,1) = 1（其餘 0）給出；H²(C_2, C_3) = 0 故 c 為余邊界，
/// b = (0, 2) 滿足 db = c，可嚴格化。
test "pseudo_nat_iso_id" {
  let dd = group_as_category(cyclic_group(3))
  let ni = nat_iso_id(dd)
  let idf = identity_functor(dd)
  assert_eq(check_nat_iso(ni, idf, idf, dd), true)
}

///|
test "pseudo_coherence_nontrivial_cocycle" {
  let gg = cyclic_group(2)
  let dd = group_as_category(cyclic_group(3))
  let idf = identity_functor(dd)
  let alpha = [idf, idf]
  // c(g,h)：C_2 × C_2 → C_3，c(1,1) = 1，其餘 0
  let c = [[0, 0], [0, 1]]
  let phi = Array::makei(2, fn(g) {
    Array::makei(2, fn(h) {
      NatIso::{ components: Array::makei(1, fn(_) { c[g][h] }), }
    })
  })
  let ap = { gg, dom: dd, alpha, phi, }
  assert_eq(check_pseudo(ap), true)
}

///|
test "pseudo_coboundary" {
  let gg = cyclic_group(2)
  let c = [[0, 0], [0, 1]]
  // b = (0, 2)：db(1,1) = 2 + 2 − 0 = 4 ≡ 1 (mod 3)
  assert_eq(is_coboundary(gg, c, [0, 2], 3), true)
  assert_false(is_coboundary(gg, c, [0, 1], 3))
}

///|
test "pseudo_strictification" {
  let gg = cyclic_group(2)
  let dd = group_as_category(cyclic_group(3))
  let idf = identity_functor(dd)
  let alpha = [idf, idf]
  let c = [[0, 0], [0, 1]]
  let phi = Array::makei(2, fn(g) {
    Array::makei(2, fn(h) {
      NatIso::{ components: Array::makei(1, fn(_) { c[g][h] }), }
    })
  })
  let ap = { gg, dom: dd, alpha, phi, }
  let ap_strict = strictify(ap, [0, 2], c, 3)
  // 嚴格化後仍為偽函子（相干公理保持）
  assert_eq(check_pseudo(ap_strict), true)
  // 嚴格化後為嚴格作用：α'_g ∘ α'_h = α'_{gh}
  for g in 0..<2 {
    for h in 0..<2 {
      let comp = compose_functor(ap_strict.alpha[h], ap_strict.alpha[g])
      assert_eq(functor_eq(comp, ap_strict.alpha[gg.mul[g][h]]), true)
    }
  }
  // 原偽函子與嚴格化相干等價
  assert_eq(strictification_equivalent(ap, ap_strict, [0, 2]), true)
}

///|
test "pseudo_strict_action_is_pseudo" {
  // 嚴格作用（φ ≡ 恆等）必為偽函子
  let gg = cyclic_group(3)
  let dd = group_as_category(cyclic_group(4))
  let idf = identity_functor(dd)
  let alpha = [idf, idf, idf]
  let phi = Array::makei(3, fn(_) { Array::makei(3, fn(_) { nat_iso_id(dd) }) })
  let ap = { gg, dom: dd, alpha, phi, }
  assert_eq(check_pseudo(ap), true)
}
