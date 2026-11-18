#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/greatsword.gd
// Greatsword Bearer: the units in front of this, any tribe, have Overrun (an aura).

#[derive(Clone,Default)]
pub struct Greatsword;
pub type GreatswordRef=Rc<RefCell<Greatsword>>;
impl ToState for Greatsword {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Greatsword {
 fn has_aura(&self) -> bool { true }
 fn aura_keywords(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<String> { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/greatsword.gd:aura_keywords") }
}
