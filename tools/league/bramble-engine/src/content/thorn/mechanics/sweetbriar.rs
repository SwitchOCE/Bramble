#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/sweetbriar.gd
// Whenever a unit goes into your Compost, gain +N/+N permanently (Sweetbriar). Every entry, in
// either phase: a sale, a Bury, a Seed, a Thorns kill with Lone Hawthorn. In a fight the gain is
// on the unit in the fight and on the recruit board at once.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct Sweetbriar;
pub type SweetbriarRef=Rc<RefCell<Sweetbriar>>;
impl ToState for Sweetbriar {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Sweetbriar {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn on_heap_added(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, heap: &str, _card_id: &str, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/sweetbriar.gd:on_heap_added") }
 fn on_heap_added_in_fight(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, heap: &str, _card_id: &str, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/sweetbriar.gd:on_heap_added_in_fight") }
}
