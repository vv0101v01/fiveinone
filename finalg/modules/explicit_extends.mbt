///|
/// Integration-owned explicit trait-method promotions; see
/// `finalg/finite/explicit_extends.mbt` for the federation policy.

///|
pub extend FinModule with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend InvSystem with @moonbitlang/core/debug.Debug::{to_repr}
