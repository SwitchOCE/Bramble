#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/bury_twice.gd
// "Your Bury effects happen twice" (Old Mother Midden: `times` 2, a golden 3 through card data's
// golden override). One unit is still buried and one entry added. Two Middens don't add up: the
// biggest applies.

use crate::content::thorn::lib::bury_base::BuryBase as BuryBase;
#[derive(Clone,Default)]
pub struct BuryTwice;
pub type BuryTwiceRef=Rc<RefCell<BuryTwice>>;
impl ToState for BuryTwice {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for BuryTwice {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn modify_int(&self, query: &str, value: i64, _player: Option<&PlayerStateRef>, _unit: Option<&UnitRef>, params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/bury_twice.gd:modify_int") }
}
