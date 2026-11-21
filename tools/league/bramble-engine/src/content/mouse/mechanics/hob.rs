//! Mirrors src/content/mouse/mechanics/hob.gd.
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::{Dictionary, ToState, Variant};

pub struct Hob;

impl ToState for Hob {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Hob {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "limit" => &(Kind::Number as i64), "attack" => &(Kind::Number as i64), }.as_dict()
    }
}
