#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::state::slot_state::SlotStateRef;
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/guard_post.gd
// Guard post: a slot keyword (8.5). The Grenadier Guard's Order puts it on a slot together with
// Guard (taunt), so the unit standing there has both. A player has one; setting a new one clears
// the old. It is also a standing mechanic of every player: it answers which slot Reserve units
// fill first (Q_FILL_FIRST) from the side's slots, so an empty post is filled first.
// The slot holding the Guard post, or -1.
pub const ID: &str = "pigeon_guard_post";
#[derive(Clone,Default)]
pub struct GuardPost;
pub type GuardPostRef=Rc<RefCell<GuardPost>>;
impl ToState for GuardPost {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for GuardPost {
 fn side_query(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, query: &str, value: i64, _params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/guard_post.gd:side_query") }
}
impl GuardPost {
 pub fn post_of(slots: &Array<SlotStateRef>) -> i64 { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/guard_post.gd:post_of") }
}
