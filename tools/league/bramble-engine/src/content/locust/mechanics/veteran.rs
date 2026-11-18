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
// Source: src/content/locust/mechanics/veteran.gd
// Twice-shed Veteran. After another friendly unit returns (Molt or Root; 9.7.2 step 5), it and
// this gain +`amount`/+`amount` this fight.

#[derive(Clone, Default)]
pub struct Veteran;
pub type VeteranRef = Rc<RefCell<Veteran>>;
impl ToState for Veteran {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Veteran {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_friendly_return(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        back: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if unit.is_none() || back.borrow().gone || !combat.trigger(unit, "locust_veteran") {
            return;
        }
        let amount = params.borrow().num("amount");
        combat.buff(Some(back), amount, amount, unit, false);
        combat.buff(unit, amount, amount, unit, false);
    }
}
