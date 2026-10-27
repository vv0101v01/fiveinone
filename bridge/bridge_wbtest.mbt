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
