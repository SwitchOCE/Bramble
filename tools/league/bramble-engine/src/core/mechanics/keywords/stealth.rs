#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/keywords/stealth.gd
// 11.2.6 Stealth (example keyword): can't be targeted by attacks until it attacks or deals
// damage. A Stealthed front-row unit still protects the back row (9.5.3).
pub const HIDDEN: &str = "stealth_hidden";
#[derive(Clone,Default)]
pub struct Stealth;
pub type StealthRef=Rc<RefCell<Stealth>>;
impl ToState for Stealth {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Stealth {
 fn on_combat_begin(&self, _combat: &mut Combat, unit: Option<&CombatUnitRef>, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/stealth.gd:on_combat_begin") }
 fn on_attack(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _defender: &CombatUnitRef, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/stealth.gd:on_attack") }
 fn on_damage_dealt(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _target: Option<&CombatUnitRef>, _amount: i64, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/stealth.gd:on_damage_dealt") }
 fn combat_query(&self, unit: Option<&CombatUnitRef>, query: &str, value: i64, _params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/stealth.gd:combat_query") }
}
impl Stealth {
 pub fn _reveal(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>) { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/stealth.gd:_reveal") }
}
