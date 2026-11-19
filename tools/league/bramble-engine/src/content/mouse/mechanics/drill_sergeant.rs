//! Mirrors src/content/mouse/mechanics/drill_sergeant.gd.
use crate::Array;
use crate::content::mouse::lib::mouse_rules::{MouseRules, PILE_ON};
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::core::{
    mechanics::{mechanic::AURA_GRANTS, mechanic_params::MechanicParamsRef},
    state::aura_context::AuraContext,
};
use crate::{Dictionary, ToState, Variant};

/// Grants Pile on to every neighbouring Mouse (8.2.3).
pub struct DrillSergeant;

impl ToState for DrillSergeant {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for DrillSergeant {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "grant" => &(Kind::Number as i64), }.as_dict()
    }

    fn has_aura(&self) -> bool {
        true
    }

    fn aura_parts(&self) -> u8 {
        AURA_GRANTS
    }

    fn aura_grants(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        let target = view.def_at(target_slot);
        if !MouseRules::is_mouse(target.as_ref()) || source_slot < 0 {
            return Array::new();
        }
        let geometry = view.geometry.as_ref().unwrap().borrow();
        if !geometry.neighbours(source_slot).has(&target_slot) {
            return Array::new();
        }
        Array::from([crate::state_dict! {
            "mechanic" => PILE_ON, "pile_on" => &params.borrow().num("grant"),
        }
        .as_dict()])
    }
}
