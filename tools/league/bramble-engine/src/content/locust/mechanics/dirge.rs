#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/dirge.gd
// Dirge-singer. Your death effects trigger (1 + `extra`) times: twice, three times on a golden,
// however they were set off (a death, a drumbeat, being eaten). Two don't add up. Not "after a
// friendly unit dies" effects or returns (ruling 33).

#[derive(Clone,Default)]
pub struct Dirge;
pub type DirgeRef=Rc<RefCell<Dirge>>;
impl ToState for Dirge {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Dirge {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("extra",Variant::Int(Kind::Number as i64));out }
 fn side_query(&self, _combat: &mut Combat, unit: Option<&CombatUnitRef>, query: &str, value: i64, params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/dirge.gd:side_query") }
 fn modify_int(&self, query: &str, value: i64, _player: Option<&PlayerStateRef>, _unit: Option<&UnitRef>, params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/dirge.gd:modify_int") }
}
