#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/standard_bearer.gd
// Parish Standard-bearer: your Mice have +attack Attack for each Mouse you have (itself and
// Cousins included), recounted as units arrive and die. Borrowed Attack (an aura).

use crate::content::mouse::lib::mouse_rules::MouseRules as MouseRules;
#[derive(Clone,Default)]
pub struct StandardBearer;
pub type StandardBearerRef=Rc<RefCell<StandardBearer>>;
impl ToState for StandardBearer {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for StandardBearer {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out }
 fn has_aura(&self) -> bool { true }
 fn aura(&self, view: &mut AuraContext, _source_slot: i64, target_slot: i64, params: &MechanicParamsRef) -> (i64, i64) { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/standard_bearer.gd:aura") }
}
