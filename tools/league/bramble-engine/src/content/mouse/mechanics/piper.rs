#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/piper.gd
// Harvest Piper: when played, give your other Mice +attack Attack permanently (golden: double).

#[derive(Clone,Default)]
pub struct Piper;
pub type PiperRef=Rc<RefCell<Piper>>;
impl ToState for Piper {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Piper {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out }
 fn on_played(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, _target: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/piper.gd:on_played") }
}
