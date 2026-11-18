#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/ballista.gd
// Toothpick Ballista: start of fight (main pass), Hit the enemy with the least Health, `times`
// times (golden: twice, choosing again). A Hit is not an attack.

use crate::content::mouse::lib::mouse_rules::MouseRules as MouseRules;
#[derive(Clone,Default)]
pub struct Ballista;
pub type BallistaRef=Rc<RefCell<Ballista>>;
impl ToState for Ballista {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Ballista {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn on_start_of_combat(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/ballista.gd:on_start_of_combat") }
}
