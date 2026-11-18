#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/effects/discover.gd
// A stand-in Tavern spell's effect (6.2): Discover a unit of the player's tier or lower.

#[derive(Clone,Default)]
pub struct Discover;
pub type DiscoverRef=Rc<RefCell<Discover>>;
impl ToState for Discover {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Discover {
 fn on_played(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, _target: Option<&UnitRef>, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/effects/discover.gd:on_played") }
}
