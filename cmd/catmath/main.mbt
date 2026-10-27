///|
/// catmath executable entry point, split out of the upstream root file
/// during the five-system federation.  The upstream algo4 package was
/// simultaneously a library and an executable; in golden the library
/// lives in `catmath/` and this package only hosts `main`.
fn main {
  println("catmath: category-theoretic algorithms on MoonBit")
  println("modules: 21  |  tests: moon test  |  benchmarks: moon bench")
  // Compile-time constant-folding demonstration (`zerocost.mbt`).
  let _ = @catlib.zero_cost_demo()
  // Free-monoid universal-property demonstration (`free.mbt`): evaluate
  // a word over Z2 through the unique extension from the free monoid.
  let zm = @catlib.fin_monoid_of(2, [[0, 1], [1, 0]], 0, "Z2")
  let _ = @catlib.fm_extend(@catlib.free_monoid_of(2), [0, 1], zm, [1, 0, 1])
}
