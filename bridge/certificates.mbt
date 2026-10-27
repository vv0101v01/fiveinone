///|
/// 三支柱共同的最小證書形狀。它只統一呈現與總控，不把三個套件
/// 各自更豐富的原生證書型別抹平。
pub(all) struct BridgeCertificate {
  source : String
  name : String
  ok : Bool
  detail : String
}

///|
pub fn bridge_certificate(
  source : String,
  name : String,
  ok : Bool,
  detail~ : String = "",
) -> BridgeCertificate {
  { source, name, ok, detail, }
}

///|
pub fn certificate_of_cubical(result : @cub.CheckResult) -> BridgeCertificate {
  {
    source: "cubical",
    name: result.name,
    ok: result.ok,
    detail: if result.ok {
      "passed"
    } else {
      "failed"
    },
  }
}

///|
pub fn certificate_of_symlib(cert : @sym.Cert) -> BridgeCertificate {
  { source: "symlib", name: cert.name, ok: cert.holds, detail: cert.detail, }
}

///|
pub fn certificate_of_semiring_law(
  name : String,
  report : @semialg.LawReport,
) -> BridgeCertificate {
  { source: "semiring", name, ok: report.ok(), detail: report.summary(), }
}

///|
pub fn certificates_all_ok(certs : Array[BridgeCertificate]) -> Bool {
  for cert in certs {
    guard cert.ok else { return false }
  }
  true
}

///|
pub fn certificate_summary(certs : Array[BridgeCertificate]) -> String {
  let mut passed = 0
  for cert in certs {
    if cert.ok {
      passed = passed + 1
    }
  }
  "\{passed}/\{certs.length()} certificates passed"
}

///|
/// 全部第一批跨支柱橋的布林穿越檢查，統一成 BridgeCertificate。
/// Face 半環一項保留 semiring LawReport 的原生 summary。
pub fn bridge_certificates() -> Array[BridgeCertificate] {
  [
    bridge_certificate(
      "bridge",
      "Perm ↔ Wiring/Equiv (S4 round trip)",
      check_perm_wiring_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "weighted graph and matrix symmetry",
      check_graph_symmetry_bridges(),
    ),
    bridge_certificate(
      "bridge",
      "semiring free category ↔ symlib FinCat",
      check_free_category_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "tropical assignment, exact permanent/determinant and QPoly tropicalization",
      check_tropical_bridges(),
    ),
    certificate_of_semiring_law(
      "FaceClass BDD quotient semiring laws",
      face_semiring_law_report(),
    ),
    bridge_certificate(
      "bridge",
      "five-member federation registry has five entries",
      federation_member_count() == 5,
    ),
    bridge_certificate(
      "bridge",
      "FinCat ↔ catmath Category ↔ finalg closure category",
      check_federation_category_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "catmath Cayley groups ↔ symlib permutation groups",
      check_federation_group_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "QPoly ↔ finalg univariate polynomials and ideal membership",
      check_federation_polynomial_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "integer SNF and characteristic-polynomial cross-checks",
      check_federation_matrix_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "S1 winding numbers across cubical, finalg and catmath",
      check_federation_circle_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "finalg verify arithmetic executable specifications",
      check_federation_finalg_verify_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "catmath canonical and derived registries",
      check_federation_catmath_registry(),
    ),
    bridge_certificate(
      "bridge",
      "derived finite category, group and G-set diagrams",
      check_federation_finite_structure_derived_bridges(),
    ),
    bridge_certificate(
      "bridge",
      "derived polynomial-reduction and integer-matrix diagrams",
      check_federation_algebra_derived_bridges(),
    ),
    bridge_certificate(
      "bridge",
      "derived Boolean, finite-topology and Spec diagrams",
      check_federation_boolean_topology_derived_bridges(),
    ),
    bridge_certificate(
      "bridge",
      "derived functional-graph and homology diagrams",
      check_federation_dynamics_homology_derived_bridges(),
    ),
    bridge_certificate(
      "bridge",
      "STLC βπη normal forms modulo explicit unit-η completion",
      check_federation_stlc_derived_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "finite Heyting opens and observable refinement subtyping",
      check_federation_heyting_unification_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "p-adic and Gröbner-refined tropical corner loci",
      check_federation_tropical_unification_bridge(),
    ),
  ]
}

///|
pub fn check_certificate_bridge() -> Bool {
  let sym_cert = certificate_of_symlib(
    @sym.cert("synthetic symlib certificate", true, "ok"),
  )
  sym_cert.source == "symlib" &&
  sym_cert.ok &&
  certificates_all_ok(bridge_certificates())
}
