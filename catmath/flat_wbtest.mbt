/// 平坦函子測試

///|
/// 三物件範疇：0 → 1 → 2（合成 0 → 2）
fn chain3() -> Category {
  let arrows = [
    Arrow::{ from: 0, to: 0, }, // 0 = id_0
    Arrow::{ from: 1, to: 1, }, // 1 = id_1
    Arrow::{ from: 2, to: 2, }, // 2 = id_2
    Arrow::{ from: 0, to: 1, }, // 3 = f
    Arrow::{ from: 1, to: 2, }, // 4 = g
    Arrow::{ from: 0, to: 2, }, // 5 = g∘f
  ]
  // 合成表（comp[a][b] = b∘a）：補齊 id_1 ∘ f = f（[3][1] = Some(3)）、
  // g ∘ id_1 = g（[4][2] = Some(4)）、g ∘ f = g∘f（[5][2] = Some(5)）
  let comp = [
    [Some(0), None, None, Some(3), None, Some(5)],
    [None, Some(1), None, None, Some(4), None],
    [None, None, Some(2), None, None, None],
    [None, Some(3), None, None, Some(5), None],
    [None, None, Some(4), None, None, None],
    [None, None, Some(5), None, None, None],
  ]
  make_category(3, arrows, comp, [0, 1, 2])
}

///|
test "chain3 is a category" {
  assert_true(check_laws(chain3()))
}

///|
test "terminal object" {
  match terminal_object(chain3()) {
    Some(t) => assert_eq(t, 2)
    None => assert_true(false)
  }
}

///|
test "pullback in chain3: cospan 0→1→2" {
  // f : 0→1（箭號 3），g : 1→2（箭號 4）：cospan 需同靶 —— 改取 f:0→1 與 id_1:1→1
  match find_pullback(chain3(), 3, 1) {
    Some((p, a, b)) => {
      // 拉回應為 0（f 的源），a = id_0, b = f
      assert_eq(p, 0)
      assert_eq(a, 0)
      assert_eq(b, 3)
    }
    None => assert_true(false)
  }
}

///|
/// 常值單點函子（平坦）
fn constant_one(cc : Category) -> SetFunctor {
  {
    dom: cc,
    objects: Array::makei(cc.n_obj, fn(_) { [0] }),
    arrows: Array::makei(cc.arrows.length(), fn(_) { [0] }),
  }
}

///|
test "constant singleton functor is flat" {
  let cc = chain3()
  let ff = constant_one(cc)
  assert_true(check_set_functor(ff))
  assert_true(is_flat(ff))
  assert_true(is_cofiltered(ff))
  assert_true(flat_iff_cofiltered(ff))
}

///|
/// Yoneda 嵌入 h^0 在 chain3 上是平坦的（表示函子保持所有極限）
test "yoneda embedding is flat (representable preserves limits)" {
  let cc = chain3()
  let h = yoneda(cc, 0)
  assert_true(check_set_functor(h))
  assert_true(is_flat(h))
  assert_true(is_cofiltered(h))
}

///|
/// 非平坦函子：把終對象映到空集
test "non-flat functor detected" {
  let cc = chain3()
  let ff = { dom: cc, objects: [[], [], []], arrows: [[], [], [], [], [], []], }
  assert_false(is_flat(ff))
  assert_false(is_cofiltered(ff))
}
