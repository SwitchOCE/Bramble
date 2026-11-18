#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/brigadier.gd
// Brigadier: an aura giving every friendly Decorated Pigeon (3+ Medals), itself included, the
// core's "attacks twice" (windfury, 9.4.11). It follows the Medal count, so a third Medal earned
// mid-fight counts from then. Out-of-turn attacks stay single (the core's attack_now).

use crate::content::pigeon::lib::medals::Medals as Medals;
#[derive(Clone,Default)]
pub struct Brigadier;
pub type BrigadierRef=Rc<RefCell<Brigadier>>;
impl ToState for Brigadier {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Brigadier {
 fn has_aura(&self) -> bool { true }
 fn aura_keywords(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<String> { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/brigadier.gd:aura_keywords") }
}
