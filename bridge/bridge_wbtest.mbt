///|
fn bridge_test_int_array_eq(a : Array[Int32], b : Array[Int32]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
test "bridge: weighted directed graph canonical key is exact and relabel invariant" {
  let g = @sgraph.Graph::build(3, [0, 0], [1, 2], [5, 7]).with_second([2, 4])
  let relabeled = @sgraph.Graph::build(3, [2, 2], [0, 1], [5, 7]).with_second([
    2, 4,
  ])
  let reversed = @sgraph.Graph::build(3, [1, 2], [0, 0], [5, 7]).with_second([
    2, 4,
  ])
  let changed_weight = @sgraph.Graph::build(3, [0, 0], [1, 2], [5, 8]).with_second([
      2, 4,
    ],
  )
  let self_loop = @sgraph.Graph::build(1, [0], [0], [5]).with_second([2])
  let no_edges = @sgraph.Graph::build(1, [], [], [])
  inspect(
    bridge_test_int_array_eq(
      semiring_graph_canonical_encoding(g),
      semiring_graph_canonical_encoding(relabeled),
    ),
    content="true",
  )
  inspect(
    !bridge_test_int_array_eq(
      semiring_graph_canonical_encoding(g),
      semiring_graph_canonical_encoding(reversed),
    ),
    content="true",
  )
  inspect(
    !bridge_test_int_array_eq(
      semiring_graph_canonical_encoding(g),
      semiring_graph_canonical_encoding(changed_weight),
    ),
    content="true",
  )
  inspect(
    !bridge_test_int_array_eq(
      semiring_graph_canonical_encoding(self_loop),
      semiring_graph_canonical_encoding(no_edges),
    ),
    content="true",
  )
}

///|
test "bridge: permutation wiring and certificate battery" {
  inspect(check_perm_wiring_bridge(), content="true") catch {
    _ => fail("permutation wiring bridge failed")
  }
  inspect(check_certificate_bridge(), content="true") catch {
    _ => fail("bridge certificate battery failed")
  }
}

///|
test "bridge: graph/category/tropical/face flagships" {
  inspect(check_graph_symmetry_bridges(), content="true") catch {
    _ => fail("graph symmetry bridge failed")
  }
  inspect(check_free_category_bridge(), content="true") catch {
    _ => fail("free category bridge failed")
  }
  inspect(check_tropical_bridges(), content="true") catch {
    _ => fail("tropical bridge failed")
  }
  inspect(check_face_semiring_bridge(), content="true") catch {
    _ => fail("face semiring bridge failed")
  }
}
