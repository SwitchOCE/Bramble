#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/lance_corporal.gd
// Lance Corporal: Order (cost): give the slots in front of this +amount/+amount, permanently,
// empty or not. From the front row there are no slots in front, so the Order can't be used there
// (ability_usable: not a legal action, and the view shows it dimmed).
// The slots in front of `slot` on the game's board (ability_usable has no context to ask).

#[derive(Clone,Default)]
pub struct LanceCorporal;
pub type LanceCorporalRef=Rc<RefCell<LanceCorporal>>;
impl ToState for LanceCorporal {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for LanceCorporal {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("cost",Variant::Int(Kind::Threshold as i64));out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn has_ability(&self) -> bool { true }
 fn ability_cost(&self, params: &MechanicParamsRef) -> i64 { params.borrow().num("cost") }
 fn ability_usable(&self, _player: Option<&PlayerStateRef>, unit: Option<&UnitRef>, _params: &MechanicParamsRef) -> bool { unit.is_some_and(|unit| {let slot=unit.borrow().slot;slot>=0 && !Self::_in_front(slot).is_empty()}) }
 fn on_ability(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, _target: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/lance_corporal.gd:on_ability") }
}
impl LanceCorporal {
 pub fn _in_front(slot: i64) -> Array<i64> { crate::core::board::board_geometry::BoardGeometry::standard(4, 3).borrow().in_front_of(slot) }
}
