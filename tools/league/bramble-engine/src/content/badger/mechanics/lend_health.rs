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
// Source: src/content/badger/mechanics/lend_health.gd
// Lends its Health to the units in front of it: extra maximum Health equal to this unit's
// maximum Health as it stands (AuraContext.max_health_at: permanent buffs and its slot's buff
// included), recalculated when it changes (an aura, 12.2.1; borrowed stats). When this leaves,
// the extra goes but never takes a unit below 1 (the core's rule for aura Health). A golden lends
// its own doubled Health.

#[derive(Clone, Default)]
pub struct LendHealth;
pub type LendHealthRef = Rc<RefCell<LendHealth>>;
impl ToState for LendHealth {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for LendHealth {
    fn has_aura(&self) -> bool {
        true
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> (i64, i64) {
        if source_slot < 0
            || !view
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .in_front_of(source_slot)
                .has(&target_slot)
        {
            return (0, 0);
        }
        (0, view.max_health_at(source_slot) as i32 as i64)
    }
}
