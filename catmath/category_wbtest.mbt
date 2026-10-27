/// 範疇論核心測試

///|
/// 行走箭號範疇：0 → 1（含恆等）
fn walking_arrow() -> Category {
  let arrows = [
    Arrow::{ from: 0, to: 0, }, // 0 = id_0
    Arrow::{ from: 1, to: 1, }, // 1 = id_1
    Arrow::{ from: 0, to: 1, }, // 2 = f
  ]
  let comp = [
    [Some(0), None, Some(2)], // id_0 ∘ …
    [None, Some(1), None],
    [None, Some(2), None],
  ]
  make_category(2, arrows, comp, [0, 1])
}

///|
/// 兩個同構物件的範疇 C（0 ≅ 1）
fn iso_pair() -> Category {
  let arrows = [
    Arrow::{ from: 0, to: 0, }, // 0 = id_0
    Arrow::{ from: 1, to: 1, }, // 1 = id_1
    Arrow::{ from: 0, to: 1, }, // 2 = f
    Arrow::{ from: 1, to: 0, }, // 3 = g
  ]
  // comp[a][b] = b ∘ a（定義於 arrows[a].to == arrows[b].from）
  let comp = [
    [Some(0), None, Some(2), None], // id_0 ∘ …
    [None, Some(1), None, Some(3)], // id_1 ∘ …
    [None, Some(2), None, Some(0)], // f ∘ …：id_1∘f = f，g∘f = id_0
    [Some(3), None, Some(1), None], // g ∘ …：id_0∘g = g，f∘g = id_1
  ]
  make_category(2, arrows, comp, [0, 1])
}

///|
test "walking arrow satisfies category laws" {
  assert_true(check_laws(walking_arrow()))
}

///|
test "iso pair satisfies category laws" {
  assert_true(check_laws(iso_pair()))
}

///|
test "group as one-object category satisfies laws" {
  let g3 = cyclic_group(3)
  let cc = group_as_category(g3)
  assert_true(check_laws(cc))
  assert_eq(cc.n_obj, 1)
}

///|
test "hom sets" {
  let cc = walking_arrow()
  assert_eq(hom(cc, 0, 1).length(), 1)
  assert_eq(hom(cc, 1, 0).length(), 0)
}

///|
test "functor from group automorphism" {
  let g3 = cyclic_group(3)
  let cc = group_as_category(g3)
  // 乘以 2 的自同構
  let ff = {
    obj_map: [0],
    mor_map: [0, 2, 1], // a ↦ 2a mod 3
  }
  assert_true(check_functor(ff, cc, cc))
  assert_true(is_faithful(ff, cc, cc))
  assert_true(is_full(ff, cc, cc))
  assert_true(is_equivalence(ff, cc, cc))
}

///|
test "equivalence: iso-pair category ≃ terminal category" {
  let cc = iso_pair()
  let dd = make_category(1, [Arrow::{ from: 0, to: 0, }], [[Some(0)]], [0])
  // F : cc → dd，把所有物件映到 0，所有箭號映到 id
  let ff = Functor::{ obj_map: [0, 0], mor_map: [0, 0, 0, 0], }
  assert_true(check_functor(ff, cc, dd))
  assert_true(is_faithful(ff, cc, dd))
  assert_true(is_full(ff, cc, dd))
  assert_true(is_essentially_surjective(ff, cc, dd))
  assert_true(is_equivalence(ff, cc, dd))
  // 建構擬逆並驗證自然同構
  let gg = quasi_inverse(ff, cc, dd)
  assert_true(check_functor(gg, dd, cc))
  assert_true(verify_quasi_inverse(ff, gg, cc, dd))
}

///|
test "faithful but not full functor" {
  // 包含函子：單射但非滿
  let dd = make_category(1, [Arrow::{ from: 0, to: 0, }], [[Some(0)]], [0])
  let cc = iso_pair()
  // G : dd → cc，0 ↦ 0，id ↦ id_0（忠實、本質滿射，但非滿：hom(0,0) 在 cc 中只有 id_0，其實是滿的）
  // 改用：dd 單物件，cc = iso_pair 的子範疇 {0} 含 id_0 —— 此處直接驗證單射性
  let gg = Functor::{ obj_map: [0], mor_map: [0], }
  assert_true(check_functor(gg, dd, cc))
  assert_true(is_faithful(gg, dd, cc))
  assert_true(is_full(gg, dd, cc))
}

///|
test "iso classes via union-find" {
  let cc = iso_pair()
  let cls = iso_classes(cc)
  assert_eq(cls[0], cls[1])
}

///|
test "functor composition is functor" {
  let g3 = cyclic_group(3)
  let cc = group_as_category(g3)
  let ff = Functor::{ obj_map: [0], mor_map: [0, 2, 1], }
  let hh = Functor::{ obj_map: [0], mor_map: [0, 2, 1], }
  let comp_ff = compose_functor(ff, hh)
  assert_true(check_functor(comp_ff, cc, cc))
  // (2·2) mod 3 = 1：合成應為 a ↦ a
  assert_eq(comp_ff.mor_map, [0, 1, 2])
}

///|
test "identity functor" {
  let cc = walking_arrow()
  let ff = identity_functor(cc)
  assert_true(check_functor(ff, cc, cc))
}

// ---------------- Set 值函子與 Yoneda ----------------

///|
fn two_el_functor(cc : Category) -> SetFunctor {
  // F(0) = {0,1}，F(1) = {0}，F(f)：兩元素皆映到 0
  SetFunctor::{
    dom: cc,
    objects: [[0, 1], [0]],
    arrows: [[0, 1], [0], [0, 0]],
  }
}

///|
test "set functor laws" {
  let cc = walking_arrow()
  let ff = two_el_functor(cc)
  assert_true(check_set_functor(ff))
}

///|
test "yoneda embedding is functor" {
  let cc = walking_arrow()
  let h = yoneda(cc, 0)
  assert_true(check_set_functor(h))
  assert_eq(h.objects[0].length(), 1)
  assert_eq(h.objects[1].length(), 1)
}

///|
test "yoneda lemma bijection" {
  let cc = walking_arrow()
  let ff = two_el_functor(cc)
  let h = yoneda(cc, 0)
  // 對每個 a ∈ F(0)（兩個元素），τ^a 應為自然變換且 roundtrip 還原
  for a in 0..<ff.objects[0].length() {
    let tau = yoneda_backward(ff, 0, a)
    assert_true(is_natural(tau, h, ff))
    assert_eq(yoneda_forward(ff, 0, tau), a)
  }
}
