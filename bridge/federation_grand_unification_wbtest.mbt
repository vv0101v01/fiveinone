///|
test "GU-001 valued initial forms" {
  assert_true(check_valued_initial_unification_bridge())
  let x = @exactalg.poly_var(0)
  let f = @exactalg.poly_add(
    @exactalg.poly_int(2),
    @exactalg.poly_add(x, @exactalg.poly_var(1)),
  )
  let report = valued_initial_form_report(f, 2, [0, 0])
  assert_true(report.valid)
  assert_true(report.initial_term_count == 2)
  assert_true(!report.is_monomial)
  assert_true(valued_initial_form_report(f, 2, [1, 0]).is_monomial)
}

///|
test "GU-004 finite relation quantale residuals" {
  assert_true(check_relation_quantale_unification_bridge())
  let identity = [[true, false], [false, true]]
  let target = [[true, true], [false, true]]
  let residual = bool_relation_residual_after(identity, target).unwrap()
  assert_true(bool_matrices_equal(residual, target))
  let report = finite_relation_quantale_report(identity, identity, target)
  assert_true(report.valid)
  assert_true(report.exhaustive_supported)
  let trop_identity = [[0, @semialg.trop_inf], [@semialg.trop_inf, 0]]
  let trop_target = [[2, 3], [1, 2]]
  let trop_residual = tropical_matrix_residual_after_bounded(
    trop_identity, trop_target, 3,
  ).unwrap()
  assert_true(tropical_matrix_equal(trop_residual, trop_target))
  let trop_report = finite_tropical_matrix_quantale_report(
    trop_identity, trop_identity, trop_target, 3,
  )
  assert_true(trop_report.valid)
  assert_true(trop_report.exhaustive_supported)
}

///|
test "GU-003 presheaf sieves and Alexandrov degeneration" {
  assert_true(check_presheaf_sieve_unification_bridge())
  let arrow = finite_presheaf_sieve_report(@sym.cat_arrow(), 1)
  assert_true(arrow.valid)
  assert_true(arrow.sieve_count == 3)
  assert_true(!arrow.is_Boolean)
  assert_true(
    finite_presheaf_sieve_report(@sym.cat_cospan(), 2).sieve_count == 5,
  )
}

///|
test "GU-002 finite blueprints" {
  assert_true(check_blueprint_unification_bridge())
  let f2 = finite_field_blueprint(2).unwrap()
  assert_true(finite_blueprint_add(f2, 1, 1) == Some(0))
  let bool_bp = bool_semiring_blueprint()
  assert_true(finite_blueprint_add(bool_bp, 1, 1) == Some(1))
  let tropical = bounded_tropical_blueprint(3).unwrap()
  // Elements 1,2,3,4 encode finite values 0,1,2,3.
  assert_true(finite_blueprint_add(tropical, 4, 2) == Some(2))
  assert_true(finite_blueprint_mul(tropical, 3, 3) == Some(4))
}

///|
test "GU-005 finite theory morphisms and modes" {
  assert_true(check_theory_mode_unification_bridge())
  let modes = federation_theory_mode_report()
  assert_true(modes.valid)
  assert_true(modes.covered_member_count == 5)
  let diamond = finite_lattice_theory_report(finite_diamond_lattice_model())
  assert_true(diamond.valid)
  assert_true(!diamond.expands_to_heyting)
}

///|
test "grand unification construction aggregate" {
  assert_true(check_federation_grand_unification_construction())
}

///|
test "certificate envelopes verify and reject tampering" {
  assert_true(check_bridge_certificate_envelopes())
  let envelopes = bridge_certificate_envelopes()
  assert_true(envelopes.length() == 21)
  let first = envelopes[0]
  let tampered : BridgeCertificateEnvelope = {
    version: first.version,
    certificate: first.certificate,
    canonical: first.canonical,
    digest: first.digest + "00",
  }
  let report = bridge_certificate_envelope_report(tampered)
  assert_true(!report.valid)
  assert_true(!report.digest_ok)
}
