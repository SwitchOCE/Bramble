#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/reserve.gd
// Reserve: in a fight, this steps from the hand into a slot a friendly unit died in, the Guard
// post first (the core's FightArrivals does the stepping in; SHARED-RULES ruling 6).

#[derive(Clone,Default)]
pub struct Reserve;
pub type ReserveRef=Rc<RefCell<Reserve>>;
impl ToState for Reserve {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Reserve {
 fn combat_query(&self, _unit: Option<&CombatUnitRef>, query: &str, value: i64, _params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/reserve.gd:combat_query") }
}
