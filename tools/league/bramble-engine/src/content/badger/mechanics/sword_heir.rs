#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/sword_heir.gd
// Sword-heir: after a unit in front of this dies (9.7.2 step 3, by its last-known slot), gain its
// own Attack and own maximum Health (SHARED-RULES 43: no slot buff, lent stats, auras or Tide)
// and its own Fury (printed and given; not an aura's or the Marshal's), this fight. Golden:
// double the Attack and Health (`times`), not the Fury.

use crate::content::badger::lib::badger_rules::BadgerRules as BadgerRules;
#[derive(Clone,Default)]
pub struct SwordHeir;
pub type SwordHeirRef=Rc<RefCell<SwordHeir>>;
impl ToState for SwordHeir {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for SwordHeir {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn after_friendly_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, dead: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/sword_heir.gd:after_friendly_death") }
}
