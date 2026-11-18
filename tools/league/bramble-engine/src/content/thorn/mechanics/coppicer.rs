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
// Source: src/content/thorn/mechanics/coppicer.gd
// After a friendly unit returns, give your units +N/+N permanently (Hazel Coppicer). Any return
// (Root, Molt); not Reserve, a summon or a copy. Permanent, so it also reaches each unit's
// recruit-board self; units that exist only in this fight keep it for the fight. Dying units are
// not among combat.units, so they get nothing.

#[derive(Clone, Default)]
pub struct Coppicer;
pub type CoppicerRef = Rc<RefCell<Coppicer>>;
impl ToState for Coppicer {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Coppicer {
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
        let Some(unit) = unit else { return };
        if back.borrow().side != unit.borrow().side || !combat.trigger(Some(unit), "thorn_coppicer")
        {
            return;
        }
        let amount = params.borrow().num("amount");
        let side = unit.borrow().side;
        let friends = combat.units(side);
        let mut index = 0;
        while index < friends.len() {
            let friend = friends.get(index).unwrap();
            index += 1;
            combat.buff(Some(&friend), amount, amount, Some(unit), true);
        }
    }
}
