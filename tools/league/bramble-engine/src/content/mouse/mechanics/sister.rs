//! Mirrors src/content/mouse/mechanics/sister.gd.
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::{Dictionary, ToState, Variant};

pub struct Sister;

impl ToState for Sister {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Sister {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "limit" => &(Kind::Threshold as i64), }.as_dict()
    }
}
