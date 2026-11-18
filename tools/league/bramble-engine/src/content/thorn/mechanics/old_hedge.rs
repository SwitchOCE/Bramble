#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/old_hedge.gd
// Your other Briars have Root 1 (The Old Hedge): an aura granting thorn_root with cost 1 to
// every other Briar on the board. Root's grants combine by the lowest cost, so two Hedges still
// give Root 1, and a Briar with its own Root pays the lower of the two. A Briar that dies after
// the Hedge has died has no Root from it.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct OldHedge;
pub type OldHedgeRef=Rc<RefCell<OldHedge>>;
impl ToState for OldHedge {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for OldHedge {
 fn has_aura(&self) -> bool { true }
 fn aura_grants(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<Dictionary> { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/old_hedge.gd:aura_grants") }
}
