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
// Relic Seeker: after each fight, gain N gold for every 2 units you were outnumbered by, win or
// lose. Only one Relic Seeker pays: the one that pays most, the first in reading order on a tie.
// It was on the board in the fight, since the board doesn't change between the fight and this.
// The gold is the player's now; gold carries over, so it is spent next turn.
pub const RELIC: &str = "badger_relic";
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
        let pay = (report.borrow().outnumbered_by as f64 / 2.0).floor() as i64
            * params.borrow().num("gold");
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
