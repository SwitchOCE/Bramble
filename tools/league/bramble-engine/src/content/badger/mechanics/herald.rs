#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/herald.gd
// Herald of the Charge: Start of fight (main pass): the units in front of this, any tribe,
// attack immediately, the left one first. Normal attacks: they take damage and their "whenever
// this attacks" effects trigger. A unit that can't attack doesn't.

#[derive(Clone,Default)]
pub struct Herald;
pub type HeraldRef=Rc<RefCell<Herald>>;
impl ToState for Herald {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Herald {
 fn on_start_of_combat(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/herald.gd:on_start_of_combat") }
}
