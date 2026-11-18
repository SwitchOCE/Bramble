#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/adjutant.gd
// Adjutant: after each fight, the units in the two slots in front of this on the recruit board
// each earn `medals` Medals, whether or not they lived. Any tribe.

use crate::content::pigeon::lib::medals::Medals as Medals;
#[derive(Clone,Default)]
pub struct Adjutant;
pub type AdjutantRef=Rc<RefCell<Adjutant>>;
impl ToState for Adjutant {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Adjutant {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("medals",Variant::Int(Kind::Number as i64));out }
 fn after_fight(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, _report: &FightReportRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/adjutant.gd:after_fight") }
}
