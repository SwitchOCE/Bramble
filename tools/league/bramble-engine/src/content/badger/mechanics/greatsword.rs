#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/content/badger/mechanics/greatsword.gd
// Greatsword Bearer: the units in front of this, any tribe, have Overrun (an aura).

#[derive(Clone, Default)]
pub struct Greatsword;
pub type GreatswordRef = Rc<RefCell<Greatsword>>;
impl ToState for Greatsword {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Greatsword {
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_parts(&self) -> u8 {
        AURA_KEYWORDS
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        let out = Array::new();
        if source_slot >= 0
            && view
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .in_front_of(source_slot)
                .has(&target_slot)
        {
            out.push("badger_overrun".to_owned());
        }
        out
    }
}
