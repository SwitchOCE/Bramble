//! Mirrors src/content/mouse/mechanics/widow.gd.
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::{Dictionary, ToState, Variant};

pub struct Widow;

impl ToState for Widow {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Widow {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "heirs" => &(Kind::Number as i64), }.as_dict()
    }
}
