#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/keywords/windfury.gd
// 11.2.3 Windfury (example keyword): attacks twice in a row each cycle; golden is still two.

#[derive(Clone,Default)]
pub struct Windfury;
pub type WindfuryRef=Rc<RefCell<Windfury>>;
impl ToState for Windfury {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Windfury {
 fn combat_query(&self, _unit: Option<&CombatUnitRef>, query: &str, value: i64, _params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/core/mechanics/keywords/windfury.gd:combat_query") }
}
