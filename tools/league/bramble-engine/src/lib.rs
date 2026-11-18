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
    (without $skip:expr; $($key:expr => $value:expr),* $(,)?) => {{
        let skip: &[&str] = $skip;
        // stringify! counts keys without evaluating key/value expressions.
        let mut entries = ::indexmap::IndexMap::with_capacity(
            <[&str]>::len(&[$(stringify!($key)),*])
        );
        $(if !skip.contains(&$key) {
            entries.insert(($key).to_string(), $crate::ToState::to_state($value));
        })*
        $crate::Variant::dictionary(entries)
    }};
    () => { $crate::Variant::Dictionary($crate::Dictionary::new()) };
    ($($key:expr => $value:expr),* $(,)?) => {{
        // stringify! counts keys without evaluating key/value expressions.
        let mut entries = ::indexmap::IndexMap::with_capacity(
            <[&str]>::len(&[$(stringify!($key)),*])
        );
        $(entries.insert(($key).to_string(), $crate::ToState::to_state($value));)*
        $crate::Variant::dictionary(entries)
    }};
}
