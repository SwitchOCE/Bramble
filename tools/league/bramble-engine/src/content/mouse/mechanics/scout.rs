#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/scout.gd
// Hedgerow Scout: whenever this attacks, summon a Cousin (golden: 2). It lands before any Pile
// on, nearest the Scout, and piles on in this attack if it lands next to the Scout.

use crate::content::mouse::lib::mouse_rules::MouseRules as MouseRules;
#[derive(Clone,Default)]
pub struct Scout;
pub type ScoutRef=Rc<RefCell<Scout>>;
impl ToState for Scout {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Scout {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("count",Variant::Int(Kind::Number as i64));out }
 fn on_attack(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _defender: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/scout.gd:on_attack") }
}
