///|
test "colored automorphism groups" {
  let c4 = Graph::cycle(4)
  assert_true(automorphism_group(c4).order() == 8L)
  assert_true(automorphism_group_colored(c4, [0, 1, 0, 1]).order() == 4L)
  assert_true(automorphism_group_colored(c4, [0, 0, 0, 1]).order() == 2L)
  let swap01 = Perm::from_img([1, 0, 3, 2])
  assert_true(!is_colored_automorphism(c4, [0, 1, 0, 1], swap01))
}

///|
test "colored canonical isomorphism" {
  let c4 = Graph::cycle(4)
  assert_true(isomorphic_colored(c4, [0, 1, 0, 1], c4, [1, 0, 1, 0]))
  assert_true(!isomorphic_colored(c4, [0, 1, 0, 1], c4, [0, 0, 1, 1]))
}
