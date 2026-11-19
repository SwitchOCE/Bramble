//! Mirrors src/content/mouse/mechanics/bell_ringer.gd.
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::{Dictionary, ToState, Variant};

pub struct BellRinger;

impl ToState for BellRinger {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for BellRinger {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "attack" => &(Kind::Number as i64), }.as_dict()
    }
}
