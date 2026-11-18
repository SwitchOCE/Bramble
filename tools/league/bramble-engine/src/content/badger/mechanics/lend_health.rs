#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/lend_health.gd
// Lends its Health to the units in front of it: extra maximum Health equal to this unit's
// maximum Health as it stands (AuraContext.max_health_at: permanent buffs and its slot's buff
// included), recalculated when it changes (an aura, 12.2.1; borrowed stats). When this leaves,
// the extra goes but never takes a unit below 1 (the core's rule for aura Health). A golden lends
// its own doubled Health.

#[derive(Clone,Default)]
pub struct LendHealth;
pub type LendHealthRef=Rc<RefCell<LendHealth>>;
impl ToState for LendHealth {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for LendHealth {
 fn has_aura(&self) -> bool { true }
 fn aura(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> (i64, i64) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/lend_health.gd:aura") }
}
