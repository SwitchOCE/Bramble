#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/coppicer.gd
// After a friendly unit returns, give your units +N/+N permanently (Hazel Coppicer). Any return
// (Root, Molt); not Reserve, a summon or a copy. Permanent, so it also reaches each unit's
// recruit-board self; units that exist only in this fight keep it for the fight. Dying units are
// not among combat.units, so they get nothing.

#[derive(Clone,Default)]
pub struct Coppicer;
pub type CoppicerRef=Rc<RefCell<Coppicer>>;
impl ToState for Coppicer {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Coppicer {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn after_friendly_return(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, back: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/coppicer.gd:after_friendly_return") }
}
