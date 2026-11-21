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
// Relic Seeker pays a base amount plus gold per unit outnumbering you last fight.
// Only the highest payout applies, with ties going to the first slot.
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
        out.insert("more", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: Option<&FightReportRef>,
        params: &MechanicParamsRef,
    ) {
        let (Some(unit), Some(report)) = (unit, report) else {
            return;
        };
        let outnumbered_by = report.borrow().outnumbered_by;
        let pay = Self::_payout(params, outnumbered_by);
        if pay <= 0 {
            return;
        }
        let board = ctx.player.as_ref().unwrap().borrow().board_units();
        for other in board.iter_live() {
            for bound in other.borrow().mechanics.iter_live() {
                let bound = bound.borrow();
                if bound.id != RELIC {
                    continue;
                }
                let other_pay = Self::_payout(&bound.params, outnumbered_by);
                if other_pay > pay || (other_pay == pay && other.borrow().slot < unit.borrow().slot)
                {
                    return;
                }
            }
        }
        if ctx.trigger(Some(unit), RELIC) {
            ctx.pay_fight_reward(|ctx| ctx.gain_gold(pay, Some(unit)));
        }
    }
}
impl Relic {
    fn _payout(params: &MechanicParamsRef, outnumbered_by: i64) -> i64 {
        let params = params.borrow();
        params.num("gold") + params.num("more") * outnumbered_by
    }
}
