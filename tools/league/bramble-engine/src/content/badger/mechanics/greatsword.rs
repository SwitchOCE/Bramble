#![allow(unused_imports, unused_variables)]
use crate::content::badger::lib::badger_rules::{BadgerRules, FRONT_ROW};
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
// Greatsword Bearer: the chosen front units, any tribe, have Overrun (an aura).

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
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"target_set" => &(Kind::Text as i64)}.as_dict()
    }

    fn text_params(&self, params: &MechanicParamsRef) -> Dictionary {
        BadgerRules::front_target_words(params)
    }

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
        params: &MechanicParamsRef,
    ) -> Array<String> {
        let out = Array::new();
        if source_slot < 0 {
            return out;
        }
        let geometry = view.geometry.as_ref().unwrap().borrow();
        let targets = if BadgerRules::front_target_set(params) == FRONT_ROW {
            geometry.front.clone()
        } else {
            geometry.in_front_of(source_slot)
        };
        if targets.has(&target_slot) {
            out.push("badger_overrun".to_owned());
        }
        out
    }
}
