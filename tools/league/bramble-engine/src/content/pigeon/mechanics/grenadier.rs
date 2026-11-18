#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/grenadier.gd
// Grenadier Guard: Order (cost): make a slot (empty or not) your Guard post, clearing the old
// one; the post is a slot effect giving Guard (taunt) and stays when the Grenadier is sold. At
// the end of your turn, give the slot that is your Guard post then +attack/+health permanently;
// when the post moves, stats already given stay on the old slot.
pub const GUARD: &str = "taunt";
use crate::content::pigeon::mechanics::guard_post::GuardPost as GuardPost;
#[derive(Clone,Default)]
pub struct Grenadier;
pub type GrenadierRef=Rc<RefCell<Grenadier>>;
impl ToState for Grenadier {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Grenadier {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("cost",Variant::Int(Kind::Threshold as i64));out.insert("attack",Variant::Int(Kind::Number as i64));out.insert("health",Variant::Int(Kind::Number as i64));out }
 fn has_ability(&self) -> bool { true }
 fn ability_cost(&self, params: &MechanicParamsRef) -> i64 { params.borrow().num("cost") }
 fn ability_target(&self, _params: &MechanicParamsRef) -> Target { Target::Slot }
 fn on_ability(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, _target: Option<&UnitRef>, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/grenadier.gd:on_ability") }
 fn on_end_of_turn(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/grenadier.gd:on_end_of_turn") }
}
