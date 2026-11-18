#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/brood.gd
// Brood Mother. When this dies, summon `count` Hoppers and add `bonus` to the player's Hopper
// bonus (every Hopper +bonus/+bonus for the rest of the game). Each time it resolves: a death,
// a drumbeat, being eaten; twice with a Dirge-singer.

use crate::content::locust::lib::locust::Locust as Locust;
#[derive(Clone,Default)]
pub struct Brood;
pub type BroodRef=Rc<RefCell<Brood>>;
impl ToState for Brood {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Brood {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("count",Variant::Int(Kind::Number as i64));out.insert("bonus",Variant::Int(Kind::Number as i64));out }
 fn has_death_effect(&self) -> bool { true }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/brood.gd:on_death") }
 fn on_recruit_death(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/brood.gd:on_recruit_death") }
}
