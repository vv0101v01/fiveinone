///|
test "federation registry lists five member systems" {
  assert_true(federation_member_count() == 5)
  assert_true(federation_member_ids().length() == 5)
  assert_true(federation_namespaces().length() == 5)
}

///|
test "federation finite-category bridges" {
  assert_true(check_federation_category_bridge())
}

///|
test "federation finite-group bridges" {
  assert_true(check_federation_group_bridge())
}

///|
test "federation polynomial and matrix bridges" {
  assert_true(check_federation_polynomial_bridge())
  assert_true(check_federation_matrix_bridge())
}

///|
test "federation circle, verify and catmath registry bridges" {
  assert_true(check_federation_circle_bridge())
  assert_true(check_federation_finalg_verify_bridge())
  assert_true(check_federation_catmath_registry())
}

///|
test "derived finite category group and gset diagrams" {
  assert_true(check_federation_finite_structure_derived_bridges())
}

///|
test "derived polynomial and integer matrix diagrams" {
  assert_true(check_federation_algebra_derived_bridges())
}

///|
test "derived boolean topology and spec diagrams" {
  assert_true(check_federation_boolean_topology_derived_bridges())
}

///|
test "derived dynamics and homology diagrams" {
  assert_true(check_federation_dynamics_homology_derived_bridges())
}

///|
test "derived stlc normal form diagram" {
  assert_true(check_federation_stlc_derived_bridge())
}

///|
test "finite Heyting observable subtype diagram" {
  assert_true(check_federation_heyting_unification_bridge())
}

///|
test "tropical corner locus diagram" {
  assert_true(check_federation_tropical_unification_bridge())
}

///|
test "all bridge certificates pass" {
  assert_true(certificates_all_ok(bridge_certificates()))
}
