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
/// 去重後的跨成員語義證書正本清單，統一成 BridgeCertificate。
/// Face 半環一項保留 semiring LawReport 的原生 summary。
///
/// 註冊表計數、finalg verify 與 catmath registry 是治理／
/// 成員原生健康檢查，仍由各自函數與 wbtest 保留，但不冒充
/// 大一統定理而重複列證。第一波整數矩陣煙霧亦已被第二波
/// 整數矩陣報告包含，故只保留後者作正本。
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
      "tropical assignment and exact permanent/determinant",
      check_tropical_bridges(),
    ),
    certificate_of_semiring_law(
      "FaceClass BDD quotient semiring laws",
      face_semiring_law_report(),
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
      "S1 winding numbers across cubical, finalg and catmath",
      check_federation_circle_bridge(),
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
    bridge_certificate(
      "bridge",
      "valued multivariate initial forms and exact principal tropical grids",
      check_valued_initial_unification_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "finite Boolean and tropical matrix quantale residuals and star closure",
      check_relation_quantale_unification_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "presheaf sieves on representables and Alexandrov degeneration",
      check_presheaf_sieve_unification_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "finite blueprints for rings, semirings and finite spectra",
      check_blueprint_unification_bridge(),
    ),
    bridge_certificate(
      "bridge",
      "executable theory morphisms with model restriction and reflection",
      check_theory_mode_unification_bridge(),
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

///|
/// A versioned, content-addressed envelope for one bridge
/// certificate.
///
/// The canonical text length-prefixes every variable field.  The
/// digest is two independent FNV-1a 64-bit hashes; it is an
/// integrity checksum for this repository's certificate registry,
/// not a cryptographic signature and not a substitute for
/// rerunning the underlying checks.  Verification therefore
/// recomputes `bridge_certificates()` and compares the registered
/// certificate field by field.
pub(all) struct BridgeCertificateEnvelope {
  version : Int32
  certificate : BridgeCertificate
  canonical : String
  digest : String
}

///|
fn certificate_canonical_field(label : String, value : String) -> String {
  "|\{label}[\{value.length()}]=\{value}"
}

///|
fn certificate_canonical_text(cert : BridgeCertificate) -> String {
  let ok = if cert.ok { "1" } else { "0" }
  "golden-bridge-certificate-v1" +
  certificate_canonical_field("source", cert.source) +
  certificate_canonical_field("name", cert.name) +
  certificate_canonical_field("ok", ok) +
  certificate_canonical_field("detail", cert.detail)
}

///|
fn certificate_fnv1a64(text : String, seed : UInt64) -> UInt64 {
  let mut hash = seed
  for ch in text {
    hash = (hash ^ ch.to_int().to_uint64()) * 1099511628211UL
  }
  hash
}

///|
fn certificate_hex_digit(value : Int32) -> String {
  if value < 10 {
    value.to_string()
  } else if value == 10 {
    "a"
  } else if value == 11 {
    "b"
  } else if value == 12 {
    "c"
  } else if value == 13 {
    "d"
  } else if value == 14 {
    "e"
  } else {
    "f"
  }
}

///|
fn certificate_hex64(value : UInt64) -> String {
  let mut out = ""
  for k in 0..<16 {
    let digit = ((value >> (60 - k * 4)) & 15UL).to_int()
    out = out + certificate_hex_digit(digit)
  }
  out
}

///|
fn certificate_digest(canonical : String) -> String {
  let first = certificate_fnv1a64(canonical, 14695981039346656037UL)
  let second = certificate_fnv1a64(
    canonical,
    14695981039346656037UL ^ 0x9E37_79B9_7F4A_7C15UL,
  )
  certificate_hex64(first) + "-" + certificate_hex64(second)
}

///|
/// Wrap one certificate in the current v1 envelope format.
pub fn bridge_certificate_envelope(
  cert : BridgeCertificate,
) -> BridgeCertificateEnvelope {
  let canonical = certificate_canonical_text(cert)
  {
    version: 1,
    certificate: cert,
    canonical,
    digest: certificate_digest(canonical),
  }
}

///|
/// Envelopes for the current canonical certificate registry.
pub fn bridge_certificate_envelopes() -> Array[BridgeCertificateEnvelope] {
  let out : Array[BridgeCertificateEnvelope] = []
  for cert in bridge_certificates() {
    out.push(bridge_certificate_envelope(cert))
  }
  out
}

///|
fn certificates_equal(a : BridgeCertificate, b : BridgeCertificate) -> Bool {
  a.source == b.source &&
  a.name == b.name &&
  a.ok == b.ok &&
  a.detail == b.detail
}

///|
pub(all) struct BridgeCertificateEnvelopeReport {
  valid : Bool
  version_ok : Bool
  canonical_ok : Bool
  digest_ok : Bool
  registry_ok : Bool
  certificate_ok : Bool
}

///|
fn certificate_envelope_report_against(
  envelope : BridgeCertificateEnvelope,
  registry : Array[BridgeCertificate],
) -> BridgeCertificateEnvelopeReport {
  let version_ok = envelope.version == 1
  let canonical = certificate_canonical_text(envelope.certificate)
  let canonical_ok = envelope.canonical == canonical
  let digest_ok = envelope.digest == certificate_digest(canonical)
  let mut matches = 0
  for cert in registry {
    if certificates_equal(cert, envelope.certificate) {
      matches = matches + 1
    }
  }
  let registry_ok = matches == 1
  let certificate_ok = envelope.certificate.ok
  {
    valid: version_ok &&
    canonical_ok &&
    digest_ok &&
    registry_ok &&
    certificate_ok,
    version_ok,
    canonical_ok,
    digest_ok,
    registry_ok,
    certificate_ok,
  }
}

///|
/// Verify one envelope against a freshly recomputed registry.
pub fn bridge_certificate_envelope_report(
  envelope : BridgeCertificateEnvelope,
) -> BridgeCertificateEnvelopeReport {
  certificate_envelope_report_against(envelope, bridge_certificates())
}

///|
pub(all) struct BridgeCertificateEnvelopesReport {
  valid : Bool
  certificate_count : Int32
  envelope_count : Int32
  unique_names_ok : Bool
  unique_digests_ok : Bool
  all_envelopes_ok : Bool
  all_certificates_ok : Bool
}

///|
/// Verify every current certificate envelope.  The registry is
/// recomputed once and shared by all per-envelope comparisons.
pub fn bridge_certificate_envelopes_report() -> BridgeCertificateEnvelopesReport {
  let registry = bridge_certificates()
  let envelopes : Array[BridgeCertificateEnvelope] = []
  for cert in registry {
    envelopes.push(bridge_certificate_envelope(cert))
  }
  let mut unique_names_ok = true
  let mut unique_digests_ok = true
  for i in 0..<envelopes.length() {
    for j in (i + 1)..<envelopes.length() {
      if envelopes[i].certificate.name == envelopes[j].certificate.name {
        unique_names_ok = false
      }
      if envelopes[i].digest == envelopes[j].digest {
        unique_digests_ok = false
      }
    }
  }
  let mut all_envelopes_ok = true
  for envelope in envelopes {
    if !certificate_envelope_report_against(envelope, registry).valid {
      all_envelopes_ok = false
    }
  }
  let all_certificates_ok = certificates_all_ok(registry)
  {
    valid: unique_names_ok &&
    unique_digests_ok &&
    all_envelopes_ok &&
    all_certificates_ok,
    certificate_count: registry.length(),
    envelope_count: envelopes.length(),
    unique_names_ok,
    unique_digests_ok,
    all_envelopes_ok,
    all_certificates_ok,
  }
}

///|
pub fn check_bridge_certificate_envelopes() -> Bool {
  bridge_certificate_envelopes_report().valid
}
