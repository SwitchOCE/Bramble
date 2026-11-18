#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/effects/sell_bonus.gd
// 4.3.8 card text changing a sell value: this unit sells for `amount` more. Proves the unit
// layer of the rule queries (Rules.ask).

#[derive(Clone,Default)]
pub struct SellBonus;
pub type SellBonusRef=Rc<RefCell<SellBonus>>;
impl ToState for SellBonus {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for SellBonus {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn modify_int(&self, query: &str, value: i64, _player: Option<&PlayerStateRef>, _unit: Option<&UnitRef>, params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/core/mechanics/effects/sell_bonus.gd:modify_int") }
}
