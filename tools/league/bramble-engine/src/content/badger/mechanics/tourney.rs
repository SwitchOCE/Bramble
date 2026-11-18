#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/tourney.gd
// Tourney Champion: Start of fight (main pass): this attacks the enemy with the most Attack, in
// either row, ignoring Guard (9.5.7; a tie goes to the first in reading order), and takes no
// damage from anything while that attack resolves.

#[derive(Clone,Default)]
pub struct Tourney;
pub type TourneyRef=Rc<RefCell<Tourney>>;
impl ToState for Tourney {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Tourney {
 fn on_start_of_combat(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/tourney.gd:on_start_of_combat") }
}
