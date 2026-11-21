#![allow(unused_imports, unused_variables)]
use crate::content::badger::lib::badger_rules::BadgerRules;
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
// Source: src/content/badger/mechanics/herald.gd
// Herald of the Charge lends Fury to the units in its target slots, of any tribe.

#[derive(Clone, Default)]
pub struct Herald;
pub type HeraldRef = Rc<RefCell<Herald>>;
impl ToState for Herald {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Herald {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"target_set" => &(Kind::Text as i64), "fury" => &(Kind::Number as i64)}
            .as_dict()
    }

    fn text_params(&self, params: &MechanicParamsRef) -> Dictionary {
        BadgerRules::front_target_words(params)
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
        let geometry = view.geometry.as_ref().unwrap().borrow();
        if !BadgerRules::front_target_slots(&geometry, source_slot, params).has(&target_slot) {
            return Array::new();
        }
        Array::from([
            crate::state_dict! {"mechanic"=>"badger_fury","fury"=>&params.borrow().num("fury")}
                .as_dict(),
        ])
    }
}
