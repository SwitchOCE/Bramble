#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/seed.gd
// Seed: when this dies, add a copy of it to your Compost (a death effect, 9.7.2 step 2). A
// golden adds 2, and so does a golden Crab-apple's golden Pip. Set off without a death (drummed,
// eaten) it still adds its entry.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct Seed;
pub type SeedRef=Rc<RefCell<Seed>>;
impl ToState for Seed {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Seed {
 fn has_death_effect(&self) -> bool { true }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/seed.gd:on_death") }
 fn on_recruit_death(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/seed.gd:on_recruit_death") }
}
impl Seed {
 pub fn _entries(params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/seed.gd:_entries") }
}
