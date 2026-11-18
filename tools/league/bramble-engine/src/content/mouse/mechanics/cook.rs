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
// Dormouse Cook: at the end of your turn, if all seven slots hold Mice (the Cook included), each
// of them gains +attack Attack permanently.

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
        let Some(unit) = unit else {
            return;
        };
        let board = ctx.player.as_ref().unwrap().borrow().board.clone();
        let mut i = 0;
        while i < board.len() {
            let held = board.get(i).flatten();
            if held.as_ref().is_none_or(|held| {
                !held
                    .borrow()
                    .def
                    .as_ref()
                    .unwrap()
                    .borrow()
                    .has_tribe("Mouse")
            }) {
                return;
            }
            i += 1;
        }
        if !ctx.trigger(Some(unit), "mouse_cook") {
            return;
        }
        let mut i = 0;
        while i < board.len() {
            let held = board.get(i).flatten().unwrap();
            ctx.buff(&held, params.borrow().num("attack"), 0, true, Some(unit));
            i += 1;
        }
    }
}
