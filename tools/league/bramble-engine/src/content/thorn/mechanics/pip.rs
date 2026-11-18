#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/pip.gd
// When this dies, summon a Pip (Crab-apple): a 3/3 Briar with Seed, into this unit's slot, else
// the nearest empty one; with no room it is lost (Pips don't wait). A golden Crab-apple summons
// a golden Pip (6/6, and its Seed adds 2). Eaten in the shop, the Pip goes on the recruit board
// like any summon.
pub const PIP: &str = "pip";
#[derive(Clone,Default)]
pub struct Pip;
pub type PipRef=Rc<RefCell<Pip>>;
impl ToState for Pip {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Pip {
 fn has_death_effect(&self) -> bool { true }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/pip.gd:on_death") }
 fn on_recruit_death(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/pip.gd:on_recruit_death") }
}
