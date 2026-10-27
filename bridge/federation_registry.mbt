///|
/// The registry of the five member systems in the single 3+2
/// federation.  The original three-pillar bridge is expanded in
/// place: this package is the only cross-member integration layer,
/// and no member pillar imports it back.

///|
/// One member system in the five-member federation.
pub(all) struct FederationMember {
  id : String
  display_name : String
  package_namespace : String
  source_repository : String
  provenance : String
  summary : String
}

///|
/// The five member systems, in federation order.
pub fn federation_members() -> Array[FederationMember] {
  [
    {
      id: "cubical-hermitian",
      display_name: "Cubical/Hermitian kernel and exact algebra",
      package_namespace: "(root) + algebra/",
      source_repository: "https://github.com/vv0101v01/algorithms02",
      provenance: "cubical-hermitian phase-13 worktree; first federated publication golden 9452cb94a441ffe17b082c09cd8ee351c4c96c89",
      summary: "Executable cubical semantics, Hermitian/projector models and exact rational algebra.",
    },
    {
      id: "symlib",
      display_name: "Finite symmetry library",
      package_namespace: "symlib/",
      source_repository: "https://github.com/vv0101v01/algorithm03",
      provenance: "algorithm03 05232fd",
      summary: "Graph canonical forms, permutation groups, finite categories and certificates.",
    },
    {
      id: "semiring",
      display_name: "Semiring laboratory",
      package_namespace: "semiring/*",
      source_repository: "https://github.com/vv0101v01/algorithm01",
      provenance: "algorithm01 6a208f4",
      summary: "Semiring traits, matrices, algebraic paths, tropical geometry and measured applications.",
    },
    {
      id: "finalg",
      display_name: "moon-algebra finite-field algebra",
      package_namespace: "finalg/ + finalg/*",
      source_repository: "https://github.com/vv0101v01/algo",
      provenance: "algo 427135faf8492f5433baba8077d4dc139282291f",
      summary: "Finite-field polynomials, Groebner bases, modules, schemes, finite HoTT and normal forms.",
    },
    {
      id: "catmath",
      display_name: "catmath categorical algorithms",
      package_namespace: "catmath/",
      source_repository: "https://github.com/vv0101v01/algo4",
      provenance: "algo4 3b3deaa9706ee5a3543c0fe0ac897167669e26a4",
      summary: "Finite categories, higher algebra, homological algebra, canonical forms and type-theoretic models.",
    },
  ]
}

///|
/// Number of federated member systems.
pub fn federation_member_count() -> Int32 {
  federation_members().length()
}

///|
/// Stable identifiers of the five federated member systems.
pub fn federation_member_ids() -> Array[String] {
  let out : Array[String] = []
  for system in federation_members() {
    out.push(system.id)
  }
  out
}

///|
/// Namespaces occupied by the five member systems inside this module.
pub fn federation_namespaces() -> Array[String] {
  let out : Array[String] = []
  for system in federation_members() {
    out.push(system.package_namespace)
  }
  out
}
