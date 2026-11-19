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
// Source: src/core/mechanics/effects/play_buff.gd
// When recruited (7.2.3) or cast: give units +attack/+health permanently. `to` is "target" (a
// chosen friendly unit) or a selector name (Selectors), relative to this unit.

#[derive(Clone, Default)]
pub struct PlayBuff;
pub type PlayBuffRef = Rc<RefCell<PlayBuff>>;
impl ToState for PlayBuff {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for PlayBuff {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out.insert("health", Variant::Int(Kind::Number as i64));
        out.insert("to", Variant::Int(Kind::Text as i64));
        out
    }
    fn play_target(&self, params: &MechanicParamsRef) -> Target {
        if params.borrow().text("to") == "target" {
            Target::FriendlyUnit
        } else {
            Target::None
        }
    }
    fn recruit_target(&self, params: &MechanicParamsRef) -> Target {
        self.play_target(params)
    }
    fn on_recruited(
        &self,
        ctx: &mut RecruitContext,
        unit: &UnitRef,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        Self::_buff(ctx, Some(unit), target, params);
    }
    fn on_played(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        Self::_buff(ctx, unit, target, params);
    }
}
impl PlayBuff {
    fn _buff(
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        let mut targets = Array::new();
        if params.borrow().text("to") == "target" {
            if let Some(target) = target {
                targets.push(target.clone());
            }
        } else {
            targets = ctx.select(unit.expect("play_buff unit"), &params.borrow().text("to"));
        }
        if targets.is_empty() || !ctx.trigger(unit, "play_buff") {
            return;
        }
        let mut index = 0;
        while index < targets.len() {
            let each = targets.get(index).unwrap();
            index += 1;
            ctx.buff(
                &each,
                params.borrow().num("attack"),
                params.borrow().num("health"),
                true,
                unit,
            );
        }
    }
}
