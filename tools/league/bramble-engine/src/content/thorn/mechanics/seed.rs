#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::compost_rules::HEAP;
use crate::core::combat::fight_side::FightSide;
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
// Source: src/content/thorn/mechanics/seed.gd
// Seed: when this dies, add a copy of it to your Compost (a death effect, 9.7.2 step 2). A
// golden adds 2, and so does a golden Crab-apple's golden Pip. Set off without a death (drummed,
// eaten) it still adds its entry.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct Seed;
pub type SeedRef = Rc<RefCell<Seed>>;
impl ToState for Seed {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Seed {
    fn has_death_effect(&self) -> bool {
        true
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !combat.trigger(unit, "thorn_seed") {
            return;
        }
        let unit = unit.unwrap();
        for _i in 0..Self::_entries(params) {
            let index = unit.borrow().side;
            let side = combat.bridge(index);
            let def = unit.borrow().def.as_ref().unwrap().clone();
            let (id, tier) = {
                let d = def.borrow();
                (d.id.clone(), d.tier)
            };
            FightSide::heap_add(&side, combat, HEAP, &id, tier, Some(unit));
        }
    }
    fn on_recruit_death(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !ctx.trigger(unit, "thorn_seed") {
            return;
        }
        for _i in 0..Self::_entries(params) {
            let id = unit
                .unwrap()
                .borrow()
                .def
                .as_ref()
                .unwrap()
                .borrow()
                .id
                .clone();
            ctx.heap_add(HEAP, &id, unit);
        }
    }
}
impl Seed {
    pub fn _entries(params: &MechanicParamsRef) -> i64 {
        if params.borrow().golden { 2 } else { 1 }
    }
}
