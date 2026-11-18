#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/effects/play_buff.gd
// When played (7.2.3) or cast: give units +attack/+health permanently. `to` is "target" (a
// chosen friendly unit) or a selector name (Selectors), relative to this unit.

#[derive(Clone,Default)]
pub struct PlayBuff;
pub type PlayBuffRef=Rc<RefCell<PlayBuff>>;
impl ToState for PlayBuff {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for PlayBuff {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out.insert("health",Variant::Int(Kind::Number as i64));out.insert("to",Variant::Int(Kind::Text as i64));out }
 fn play_target(&self, params: &MechanicParamsRef) -> Target { if params.borrow().text("to")=="target" {Target::FriendlyUnit} else {Target::None} }
 fn on_played(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, target: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/effects/play_buff.gd:on_played") }
}
