///|
/// Integration-owned explicit trait-method promotions; see
/// `finalg/finite/explicit_extends.mbt` for the federation policy.

///|
pub extend Graph with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Path with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Frac with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Frac with Eq::{not_equal, equal}

///|
pub extend PartitionGroupoid with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PartitionGroupoid with Eq::{not_equal, equal}

///|
pub extend KClass with @moonbitlang/core/debug.Debug::{to_repr}
