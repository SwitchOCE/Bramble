#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/pikeman.gd
// Needle Pikeman: can't attack (skipped in the attack order, and "attacks immediately" does
// nothing). After each pile-on it gains +attack Attack permanently, `limit` times a fight; the
// gain is made in MouseRules.after_pile_on, after the hit that earned it.

#[derive(Clone,Default)]
pub struct Pikeman;
pub type PikemanRef=Rc<RefCell<Pikeman>>;
impl ToState for Pikeman {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Pikeman {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out.insert("limit",Variant::Int(Kind::Threshold as i64));out }
 fn combat_query(&self, _unit: Option<&CombatUnitRef>, query: &str, value: i64, _params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/pikeman.gd:combat_query") }
}
