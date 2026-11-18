#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/lieutenant.gd
// Lieutenant: Start of fight (main pass): if every slot of this row holds a unit (any tribe),
// each of them deals damage equal to the Attack its own slot gives it in this fight (an
// Edgewright's doubling and a Colour Ensign's copy included) to the enemy across from it (8.2.6);
// if that slot is empty, the nearest enemy in that row, else any enemy. Plain damage: not an
// attack and not a Hit. A golden deals `percent` 200.
// The enemy across from the dealer; if that slot is empty, the nearest enemy in that row, else
// any enemy. Only units the core still counts (combat.units leaves dying ones out).

#[derive(Clone,Default)]
pub struct Lieutenant;
pub type LieutenantRef=Rc<RefCell<Lieutenant>>;
impl ToState for Lieutenant {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Lieutenant {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("percent",Variant::Int(Kind::Number as i64));out }
 fn on_start_of_combat(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/lieutenant.gd:on_start_of_combat") }
}
impl Lieutenant {
 pub fn _across(&self, combat: &mut Combat, dealer: &CombatUnitRef) -> Option<CombatUnitRef> { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/lieutenant.gd:_across") }
}
