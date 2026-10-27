// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "vv0101v01/cubical-hermitian"

version = "0.0.1"

readme = "README.md"

repository = "https://github.com/vv0101v01/golden"

license = "Apache-2.0"

keywords = [
  "cubical",
  "hermitian",
  "projector",
  "univalence",
  "exact-algebra",
  "finite-symmetry",
  "graph-automorphism",
  "finite-category",
  "category-theory",
  "canonical-forms",
  "finite-fields",
  "groebner-bases",
  "homotopy-type-theory",
  "semiring",
  "tropical",
  "path-algebra",
]

preferred_target = "wasm"

description = "A five-system federated MoonBit library joining an executable cubical/Hermitian kernel with exact rational algebra, finite symmetry, semiring path/tropical algorithms, finite-field algebra and Gröbner/normal forms, and categorical higher-algebra algorithms through the single one-way bridge package."

import {
  "moonbitlang/async@0.22.5",
}
