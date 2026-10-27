///|
fn main {
  println("Cubical Hermitian — five-member (3+2) federation showcase")
  println("----------------------------------------------------------")
  println("Federation members:")
  for system in @bridge.federation_members() {
    println("- \{system.id}: \{system.package_namespace} — \{system.summary}")
  }
  println("Bridge certificates:")
  let certificates = @bridge.bridge_certificates()
  for cert in certificates {
    let status = if cert.ok { "PASS" } else { "FAIL" }
    println("[\{status}] \{cert.source}: \{cert.name}")
    if cert.detail != "" {
      println("        \{cert.detail}")
    }
  }
  println(@bridge.certificate_summary(certificates))
  let cycle = @sgraph.Graph::build(4, [0, 1, 2, 3], [1, 2, 3, 0], [1, 1, 1, 1])
  let report = @bridge.weighted_graph_report(cycle, 32)
  println(
    "directed weighted C4: weighted symmetries=\{report.weighted_symmetry_count}, reachable pairs=\{report.reachable_pairs}, finite-distance sum=\{report.finite_distance_sum}",
  )
  println(
    "symmetry-average projector: projector=\{@cub.is_projector(report.symmetry_projector)}, trace=\{@cub.mat_trace_re(report.symmetry_projector)}",
  )
  let rotation = @sym.Perm::from_img([1, 2, 3, 0])
  let wiring_ok = match
    @bridge.perm_of_wiring(@bridge.perm_equiv(rotation).wiring) {
    Some(back) => back.equal(rotation)
    None => false
  }
  println("Perm → cubical Equiv → Perm round trip: \{wiring_ok}")
  guard @bridge.certificates_all_ok(certificates) && wiring_ok else {
    abort("showcase failed")
  }
}
