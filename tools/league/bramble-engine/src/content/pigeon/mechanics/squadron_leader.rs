#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/squadron_leader.gd
// Squadron Leader: an aura on the units in the two slots in front of this (any tribe): Sortie
// and +attack Attack. Borrowed stats, in both phases.

#[derive(Clone,Default)]
pub struct SquadronLeader;
pub type SquadronLeaderRef=Rc<RefCell<SquadronLeader>>;
impl ToState for SquadronLeader {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for SquadronLeader {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out }
 fn has_aura(&self) -> bool { true }
 fn aura(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, params: &MechanicParamsRef) -> (i64, i64) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/squadron_leader.gd:aura") }
 fn aura_keywords(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<String> { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/squadron_leader.gd:aura_keywords") }
}
impl SquadronLeader {
 pub fn _covers(&self, view: &AuraContext, source_slot: i64, target_slot: i64) -> bool { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/squadron_leader.gd:_covers") }
}
