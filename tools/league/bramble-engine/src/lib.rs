//! File-for-file port of the pinned Bramble GDScript rules engine.
// Keep source file nesting, source argument lists, and explicit source defaults for auditability.
#![allow(
    clippy::module_inception,
    clippy::too_many_arguments,
    clippy::derivable_impls
)]
pub mod content;
pub mod core;
pub mod game;
pub mod util;
pub mod variant;
pub use variant::{Array, Dictionary, ToState, Variant};

#[macro_export]
macro_rules! state_dict {
    () => { $crate::Variant::Dictionary($crate::Dictionary::new()) };
    ($($key:expr => $value:expr),* $(,)?) => {{
        let mut entries = ::indexmap::IndexMap::new();
        $(entries.insert(($key).to_string(), $crate::ToState::to_state($value));)*
        $crate::Variant::dictionary(entries)
    }};
}
