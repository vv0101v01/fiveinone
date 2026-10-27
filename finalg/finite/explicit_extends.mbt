///|
/// Integration-owned explicit trait-method promotions.
///
/// Upstream `moon-algebra` suppressed `implicit_impl_as_method` at
/// module level.  Golden instead makes the same derived methods
/// explicit, package by package, so the whole module can keep
/// `--deny-warn` without a global warning suppression.

///|
pub extend FinAlg with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FinIdeal with @moonbitlang/core/debug.Debug::{to_repr}
