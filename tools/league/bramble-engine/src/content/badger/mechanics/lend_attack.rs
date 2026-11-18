#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/lend_attack.gd
// Lends its Attack to the units in front of it (an aura, 12.2.1; borrowed stats): extra Attack
// equal to this unit's Attack as it stands (AuraContext.attack_at: permanent buffs, its slot's
// buff and doubling included), recalculated when it changes. A golden lends its own doubled
// Attack.

#[derive(Clone,Default)]
pub struct LendAttack;
pub type LendAttackRef=Rc<RefCell<LendAttack>>;
impl ToState for LendAttack {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for LendAttack {
 fn has_aura(&self) -> bool { true }
 fn aura(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> (i64, i64) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/lend_attack.gd:aura") }
}
