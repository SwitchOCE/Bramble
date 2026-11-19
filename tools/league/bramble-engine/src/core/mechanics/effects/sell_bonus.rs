#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/core/mechanics/effects/sell_bonus.gd
// 4.3.8 card text changing a sell value: this unit sells for `amount` more. Proves the unit
// layer of the rule queries (Rules.ask).

#[derive(Clone, Default)]
pub struct SellBonus;
pub type SellBonusRef = Rc<RefCell<SellBonus>>;
impl ToState for SellBonus {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for SellBonus {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn modify_int(
        &self,
        query: &str,
        value: i64,
        _player: Option<&PlayerStateRef>,
        _unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        if query == crate::core::rules::rules::Rules::SELL_VALUE {
            value + params.borrow().num("amount")
        } else {
            value
        }
    }
}
