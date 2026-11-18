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
// Source: src/core/mechanics/effects/end_turn_buff.gd
// End of Turn (3.4.1 step 1): give a random other friendly unit +attack/+health permanently.

#[derive(Clone, Default)]
pub struct EndTurnBuff;
pub type EndTurnBuffRef = Rc<RefCell<EndTurnBuff>>;
impl ToState for EndTurnBuff {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for EndTurnBuff {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out.insert("health", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit_ref = unit.expect("end_turn_buff unit");
        let target = ctx.random_of(&ctx.select(unit_ref, "others"));
        if target.is_none() || !ctx.trigger(unit, "end_turn_buff") {
            return;
        }
        ctx.buff(
            &target.unwrap(),
            params.borrow().num("attack"),
            params.borrow().num("health"),
            true,
            unit,
        );
    }
}
