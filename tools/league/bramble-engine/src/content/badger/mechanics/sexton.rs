use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::{Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};

// Source: src/content/badger/mechanics/sexton.gd
// Sett Sexton: after a unit in front of this gains Attack from Fury, it gains +amount Attack
// permanently. BadgerRules::sexton_pays applies the per-unit limit right after the Fury buff.
// Golden doubles the amount and uses the same limit.
#[derive(Clone, Default)]
pub struct Sexton;
pub type SextonRef = Rc<RefCell<Sexton>>;
impl ToState for Sexton {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Sexton {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out.insert("limit", Variant::Int(Kind::Threshold as i64));
        out
    }
}
