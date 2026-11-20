//! Mirrors src/content/pigeon/mechanics/group_captain.gd.
use crate::Array;
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    mechanics::mechanic::{AURA_KEYWORDS, AURA_STATS},
    mechanics::mechanic_params::MechanicParamsRef,
    state::aura_context::AuraContext,
};
use crate::{Dictionary, ToState, Variant};

pub struct GroupCaptain;

impl ToState for GroupCaptain {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for GroupCaptain {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "attack" => &(Kind::Number as i64), }.as_dict()
    }

    fn has_aura(&self) -> bool {
        true
    }
    fn aura_parts(&self) -> u8 {
        AURA_STATS | AURA_KEYWORDS
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> (i64, i64) {
        if source_slot >= 0 && view.reservist_slots.has(&target_slot) {
            return (params.borrow().num("attack"), 0);
        }
        (0, 0)
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        if source_slot >= 0 && view.reservist_slots.has(&target_slot) {
            return Array::from(["pigeon_sortie".to_owned()]);
        }
        Array::new()
    }
}
