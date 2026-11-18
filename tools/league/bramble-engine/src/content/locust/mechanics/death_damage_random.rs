#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/death_damage_random.gd
// Wheat Raider. When this dies, deal `amount` damage to a random enemy from either row (9.5.6):
// damage, not an attack or a Hit. Needs a fight: in the shop it does nothing (ruling 34).

#[derive(Clone,Default)]
pub struct DeathDamageRandom;
pub type DeathDamageRandomRef=Rc<RefCell<DeathDamageRandom>>;
impl ToState for DeathDamageRandom {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for DeathDamageRandom {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn has_death_effect(&self) -> bool { true }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/death_damage_random.gd:on_death") }
}
