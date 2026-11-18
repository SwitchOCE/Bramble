#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/keywords/venomous.gd
// 11.2.5 Venomous (example keyword): destroys the first unit it deals damage to each combat.
pub const USED: &str = "venom_used";
#[derive(Clone,Default)]
pub struct Venomous;
pub type VenomousRef=Rc<RefCell<Venomous>>;
impl ToState for Venomous {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Venomous {
 fn on_damage_dealt(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, target: Option<&CombatUnitRef>, _amount: i64, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/venomous.gd:on_damage_dealt") }
}
