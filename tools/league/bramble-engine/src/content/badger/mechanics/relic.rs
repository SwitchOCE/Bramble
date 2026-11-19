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
// Source: src/content/badger/mechanics/relic.gd
// Relic Seeker: after each fight, gain `gold` gold, or `more` if outnumbered by at least 3.
// Only one Relic Seeker pays, ranked by `gold` with ties going to the first in reading order.
// The gold is the player's now and carries over to the next turn.
pub const RELIC: &str = "badger_relic";
const HIGH_COUNT: i64 = 3;
#[derive(Clone, Default)]
pub struct Relic;
pub type RelicRef = Rc<RefCell<Relic>>;
impl ToState for Relic {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Relic {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("gold", Variant::Int(Kind::Number as i64));
        out.insert("more", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_fight(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: &FightReportRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        let high = report.borrow().outnumbered_by >= HIGH_COUNT;
        let pay = params.borrow().num(if high { "more" } else { "gold" });
        if pay <= 0 {
            return;
        }
        let board = ctx.player.as_ref().unwrap().borrow().board_units();
        let mut i = 0;
        while i < board.len() {
            let other = board.get(i).unwrap();
            if Rc::ptr_eq(&other, unit) {
                break;
            }
            if Self::_gold(Some(&other)) >= params.borrow().num("gold") {
                return;
            }
            i += 1;
        }
        let board = ctx.player.as_ref().unwrap().borrow().board_units();
        i = 0;
        while i < board.len() {
            let other = board.get(i).unwrap();
            if other.borrow().slot > unit.borrow().slot
                && Self::_gold(Some(&other)) > params.borrow().num("gold")
            {
                return;
            }
            i += 1;
        }
        if ctx.trigger(Some(unit), RELIC) {
            ctx.gain_gold(pay, Some(unit));
        }
    }
}
impl Relic {
    pub fn _gold(unit: Option<&UnitRef>) -> i64 {
        let mut best = 0;
        let mechanics = unit.expect("Relic unit").borrow().mechanics.clone();
        let mut i = 0;
        while i < mechanics.len() {
            let bound = mechanics.get(i).unwrap();
            if bound.borrow().id == RELIC {
                best = best.max(bound.borrow().params.borrow().num("gold"));
            }
            i += 1;
        }
        best
    }
}
