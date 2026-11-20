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
// Padre, Charge: after a friendly unit dies (9.7.2 step 3), give the slot Renown for
// the next fight. Its printed Charge stays the same on a golden.
pub const USED: &str = "pigeon_padre_uses";
#[derive(Clone, Default)]
pub struct Padre;
pub type PadreRef = Rc<RefCell<Padre>>;
impl ToState for Padre {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Padre {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out.insert("limit", Variant::Int(Kind::Threshold as i64));
        out
    }
    fn after_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if dead.borrow().side != unit.borrow().side || Rc::ptr_eq(dead, unit) {
            return;
        }
        let limit = params.borrow().num("limit");
        if unit.borrow().fight_count(USED) >= limit || !combat.trigger(Some(unit), "pigeon_padre") {
            return;
        }
        unit.borrow_mut().add_fight_count(USED, 1);
        let amount = params.borrow().num("amount");
        let side_index = unit.borrow().side;
        let side = combat.bridge(side_index);
        let slot = dead.borrow().slot;
        crate::core::combat::fight_side::FightSide::add_renown(
            &side,
            combat,
            slot,
            amount,
            Some(unit),
        );
        let left = limit - unit.borrow().fight_count(USED);
        combat.show_uses(Some(unit), USED, left, Some(unit));
    }
}
