/// 群胚與交叉模白盒測試。

///|
/// 構造全連通群胚：物件 {0,1}，每個 hom 集有 2 個箭號
/// （箭號 (x,y,g)，g ∈ C_2；合成 (x,y,g)·(y,z,h) = (x,z,g+h)）
fn build_groupoid_c2() -> Category {
  // 編號：(x*2 + y)*2 + g
  let arrows : Array[Arrow] = []
  for x in 0..<2 {
    for y in 0..<2 {
      for _ in 0..<2 {
        arrows.push({ from: x, to: y, })
      }
    }
  }
  let comp = Array::makei(8, fn(i) {
    Array::makei(8, fn(j) {
      // 箭號 i : x→y（g），箭號 j : y'→z（h）；可合成 ⟺ y == y'
      let xi = i / 2 / 2
      let yi = i / 2 % 2
      let gi = i % 2
      let xj = j / 2 / 2
      let yj = j / 2 % 2
      let gj = j % 2
      if yi != xj {
        None
      } else {
        Some((xi * 2 + yj) * 2 + (gi + gj) % 2)
      }
    })
  })
  let id_of_obj = [0, (1 * 2 + 1) * 2 + 0]
  { n_obj: 2, arrows, comp, id_of_obj, }
}

///|
test "groupoid_is_groupoid" {
  let cc = build_groupoid_c2()
  assert_eq(is_groupoid(cc), true)
  assert_eq(check_laws(cc), true)
}

///|
test "groupoid_components" {
  let cc = build_groupoid_c2()
  let comp = groupoid_components(cc)
  assert_eq(comp[0], comp[1])
  // 離散群胚（僅恆等箭號）
  let dd = {
    n_obj: 2,
    arrows: [{ from: 0, to: 0, }, { from: 1, to: 1, }],
    comp: [[Some(0), None], [None, Some(1)]],
    id_of_obj: [0, 1],
  }
  let dcomp = groupoid_components(dd)
  assert_eq(dcomp[0] != dcomp[1], true)
}

///|
test "groupoid_vertex_group" {
  let cc = build_groupoid_c2()
  let pi = vertex_group(cc, 0)
  assert_eq(pi.order, 2)
  assert_eq(pi.mul[1][1], 0)
  assert_eq(check_group_model(pi, [[0, 1], [1, 0]]), true)
}

///|
test "groupoid_skeleton_equivalence" {
  let cc = build_groupoid_c2()
  let pi = vertex_group(cc, 0)
  let bpi = group_as_category(pi)
  let ff = skeleton_functor(cc, 0)
  assert_eq(check_functor(ff, cc, bpi), true)
  // 完全忠實 + 本質滿射 → 等價
  assert_eq(is_full(ff, cc, bpi), true)
  assert_eq(is_faithful(ff, cc, bpi), true)
  assert_eq(is_essentially_surjective(ff, cc, bpi), true)
  // 擬逆：BC_2 → C
  let mor_map : Array[Int32] = []
  for i in 0..<pi.order {
    // π₁ 的元素 i 對應 cc 中 x₀=0 處的第 i 個迴圈
    mor_map.push(i)
  }
  let gg = { obj_map: [0], mor_map, }
  assert_eq(check_functor(gg, bpi, cc), true)
  assert_eq(is_equivalence(ff, cc, bpi), true)
}

///|
test "crossed_module_inner_s3" {
  // Inn(S_3)：π₀ = Out(S_3) = 1，π₁ = Z(S_3) = 1
  let s3 = symmetric_group(3)
  let aut = automorphism_group(s3)
  assert_eq(aut.order, 6)
  let perms = automorphism_perms(s3)
  assert_eq(perms.length(), 6)
  let cm = inner_crossed_module(s3, aut, perms)
  assert_eq(check_crossed_module(cm), true)
  assert_eq(pi0(cm).order, 1)
  assert_eq(pi1(cm).order, 1)
}

///|
test "crossed_module_inner_v4" {
  // Inn(C_2×C_2)：Out = Aut = GL(2,2) ≅ S_3（6 階），Z = C_2×C_2（4 階）
  let v4 = direct_product(cyclic_group(2), cyclic_group(2))
  let aut = automorphism_group(v4)
  assert_eq(aut.order, 6)
  let perms = automorphism_perms(v4)
  let cm = inner_crossed_module(v4, aut, perms)
  assert_eq(check_crossed_module(cm), true)
  assert_eq(pi0(cm).order, 6)
  assert_eq(pi1(cm).order, 4)
}

///|
test "crossed_module_ordinary_group" {
  // 平凡交叉模：∂ = 零同態，作用平凡 ⟺ 普通群 G（π₀ = G，π₁ = H）
  let gg = cyclic_group(3)
  let hh = cyclic_group(2)
  let d = Array::makei(2, fn(_) { 0 })
  let action = Array::makei(3, fn(_) { Array::makei(2, fn(h) { h }) })
  let cm = { hh, gg, d, action, }
  assert_eq(check_crossed_module(cm), true)
  assert_eq(pi0(cm).order, 3)
  assert_eq(pi1(cm).order, 2)
}
