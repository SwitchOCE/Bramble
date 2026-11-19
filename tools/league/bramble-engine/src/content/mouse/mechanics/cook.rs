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
// Source: src/content/mouse/mechanics/cook.gd
// At end of turn, give your other Mice Attack permanently.

#[derive(Clone, Default)]
pub struct Cook;
pub type CookRef = Rc<RefCell<Cook>>;
impl ToState for Cook {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Cook {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !ctx.trigger(unit, "mouse_cook") {
            return;
        }
        let board = ctx.player.as_ref().unwrap().borrow().board_units();
        for other in board.iter_live() {
            if unit.is_some_and(|unit| Rc::ptr_eq(&other, unit)) {
                continue;
            }
            if crate::content::mouse::lib::mouse_rules::MouseRules::is_mouse(
                other.borrow().def.as_ref(),
            ) {
                ctx.buff(&other, params.borrow().num("attack"), 0, true, unit);
            }
        }
    }
}
