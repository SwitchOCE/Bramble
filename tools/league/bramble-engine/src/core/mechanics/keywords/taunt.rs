#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/keywords/taunt.gd
// 11.2.1 Taunt (example keyword): must be attacked, within the row that can be attacked (9.5.4).

#[derive(Clone,Default)]
pub struct Taunt;
pub type TauntRef=Rc<RefCell<Taunt>>;
impl ToState for Taunt {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Taunt {
 fn combat_query(&self, _unit: Option<&CombatUnitRef>, query: &str, value: i64, _params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/taunt.gd:combat_query") }
}
