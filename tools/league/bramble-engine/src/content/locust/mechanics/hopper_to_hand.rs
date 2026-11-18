#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/hopper_to_hand.gd
// Horde-runner. At the start of your turn, get `count` Hoppers in hand (Created; lost with a
// full hand, 7.1.2). Given, not summoned: Mother of Thousands doesn't double it.

use crate::content::locust::lib::locust::Locust as Locust;
#[derive(Clone,Default)]
pub struct HopperToHand;
pub type HopperToHandRef=Rc<RefCell<HopperToHand>>;
impl ToState for HopperToHand {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for HopperToHand {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("count",Variant::Int(Kind::Number as i64));out }
 fn on_start_of_turn(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/hopper_to_hand.gd:on_start_of_turn") }
}
