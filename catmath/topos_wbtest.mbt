/// 預層拓撲斯白盒測試。

///|
/// walking arrow 範疇：物件 {0, 1}，箭號 id₀, id₁, f : 0 → 1
fn walking_arrow_topos() -> Category {
  {
    n_obj: 2,
    arrows: [{ from: 0, to: 0, }, { from: 1, to: 1, }, { from: 0, to: 1, }],
    comp: [
      [Some(0), None, Some(2)],
      [None, Some(1), None],
      [None, Some(2), None],
    ],
    id_of_obj: [0, 1],
  }
}

///|
test "topos_omega_walking_arrow" {
  // Ω(0) = 篩 on 0 = {∅, {id₀}} → 2
  // Ω(1) = 篩 on 1 = {∅, {id₁}, {id₁, f}} → 3
  let cc = walking_arrow_topos()
  assert_eq(sieves_on(cc, 0).length(), 2)
  assert_eq(sieves_on(cc, 1).length(), 3)
  let om = omega_presheaf(cc)
  assert_eq(om.sets, [2, 3])
  assert_eq(check_presheaf(om), true)
}

///|
test "topos_presheaf_functoriality" {
  let cc = walking_arrow_topos()
  // 常值預層 F(c) = {0}
  let ff = { cc, sets: [1, 1], maps: [[0], [0], [0]], }
  assert_eq(check_presheaf(ff), true)
  assert_eq(check_presheaf(terminal_presheaf(cc)), true)
}

///|
test "topos_subobject_classifier" {
  let cc = walking_arrow_topos()
  // F : F(0) = {0,1}, F(1) = {0}, F(f) = const 0，F(id) = id
  let ff = { cc, sets: [2, 1], maps: [[0, 1], [0], [0]], }
  assert_eq(check_presheaf(ff), true)
  // 子預層：S(1)=∅ 時 S(0) 任意（4 個）；S(1)={0} 時 0 ∈ S(0)（2 個）→ 6 個
  assert_eq(subpresheaves(ff).length(), 6)
  // 次對象分類器公理：Sub(F) ↪ Nat(F, Ω) 單射且自然
  assert_eq(verify_subobject_classifier(ff), true)
}

///|
test "topos_nat_count" {
  // Nat(F, Ω) 的數量 = 子預層數量（雙射）：6
  let cc = walking_arrow_topos()
  let ff = { cc, sets: [2, 1], maps: [[0, 0], [0], [0]], }
  let om = omega_presheaf(cc)
  // η_0 : F(0)={0,1} → Ω(0)（2 個選擇 × 2），η_1 : F(1)={0} → Ω(1)（3 個選擇）
  // 自然性（唯一非平凡箭號 f : 0→1，對每個 y ∈ F(1)）：
  //   η_0(F(f)(y)) = Ω(f)(η_1(y))
  let mut count = 0
  for a in 0..<om.sets[0] {
    for b in 0..<om.sets[0] {
      for c1 in 0..<om.sets[1] {
        let mut ok = true
        for y in 0..<ff.sets[1] {
          // η_0(F(f)(y))：F(f)(y) = ff.maps[2][y] ∈ F(0)
          let eta0 = if ff.maps[2][y] == 0 { a } else { b }
          if eta0 != om.maps[2][c1] {
            ok = false
          }
        }
        if ok {
          count = count + 1
        }
      }
    }
  }
  assert_eq(count, 6)
}

///|
test "topos_power_object" {
  let cc = walking_arrow_topos()
  let ff = { cc, sets: [1, 1], maps: [[0], [0], [0]], }
  let ps = power_object_size(ff)
  // P(X)(0) = |Ω(0)|^{|X(0)|} = 2^1 = 2；P(X)(1) = 3^1 = 3
  assert_eq(ps, [2, 3])
}
