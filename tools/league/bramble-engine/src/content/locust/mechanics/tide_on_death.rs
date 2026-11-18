#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/tide_on_death.gd
// Famine-caller. When this dies, Tide +`amount`: at once, for the rest of the game, whether it
// died, was drummed or was eaten.

use crate::content::locust::lib::locust::Locust as Locust;
#[derive(Clone,Default)]
pub struct TideOnDeath;
pub type TideOnDeathRef=Rc<RefCell<TideOnDeath>>;
impl ToState for TideOnDeath {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for TideOnDeath {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn has_death_effect(&self) -> bool { true }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/tide_on_death.gd:on_death") }
 fn on_recruit_death(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/tide_on_death.gd:on_recruit_death") }
}
