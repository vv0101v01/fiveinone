///|
test "phase13: self-family positivity by least fixpoint" {
  inspect(check_self_family_positivity_fixpoint(), content="true")
}

///|
test "phase13: simultaneous IR foreign hypotheses at nested arguments" {
  inspect(check_simultaneous_ir_nested_foreign(), content="true")
}

///|
test "phase13: face conversion descends relevant dims only" {
  inspect(check_conv_under_face_relevant_descent(), content="true")
}

///|
test "phase13: maximum compatible DSystem completion" {
  inspect(check_dsystem_maximum_completion(), content="true")
}

///|
test "phase13: square-valued Circle/Torus comp computes verified caps" {
  inspect(check_circle_torus_square_comp(), content="true")
}

///|
test "phase13: difference-guided Bool case split" {
  inspect(check_difference_guided_case_split(), content="true")
}

///|
test "phase13: interner and byte backend share one DAG" {
  inspect(check_interned_dag_byte_sharing(), content="true")
}

///|
test "phase13: exact BDD ordering beyond twelve variables" {
  inspect(check_bdd_optimal_order_dp_extended(), content="true")
}

///|
test "phase13: CDCL DRUP proofs record clause deletions" {
  inspect(check_cdcl_drup_proof_with_deletions(), content="true")
}

///|
test "phase13: Tier D stratified host-cube probes" {
  inspect(check_dcube_stratified_tier_d(), content="true")
}

///|
test "phase13: inverse/associativity 3-cells and loop classification" {
  inspect(check_loop_inverse_assoc_and_classification(), content="true")
}

///|
test "phase13: HOU residual constraint solver" {
  inspect(check_hou_residual_solver(), content="true")
}

///|
test "phase13: artifact manifest integrity chain" {
  inspect(check_artifact_manifest_integrity_chain(), content="true")
}
