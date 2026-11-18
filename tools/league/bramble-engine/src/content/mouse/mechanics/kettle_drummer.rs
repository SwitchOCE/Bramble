#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/kettle_drummer.gd
// Kettle-drummer: your back-row units (B1 to B3, any tribe, itself included) attack twice, as
// an aura giving the core's windfury. A Spoon Catapult there Hits twice; a unit that can't
// attack still can't.

#[derive(Clone,Default)]
pub struct KettleDrummer;
pub type KettleDrummerRef=Rc<RefCell<KettleDrummer>>;
impl ToState for KettleDrummer {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for KettleDrummer {
 fn has_aura(&self) -> bool { true }
 fn aura_keywords(&self, view: &mut AuraContext, _source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<String> { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/kettle_drummer.gd:aura_keywords") }
}
