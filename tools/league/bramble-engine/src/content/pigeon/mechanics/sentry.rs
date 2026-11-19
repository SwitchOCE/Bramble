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
// Source: src/content/pigeon/mechanics/sentry.gd
// Sentry: at the end of your turn, give this slot +amount/+amount (permanent, 3.4.1).

#[derive(Clone, Default)]
pub struct Sentry;
pub type SentryRef = Rc<RefCell<Sentry>>;
impl ToState for Sentry {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Sentry {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
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
        let slot = unit.borrow().slot;
        if slot < 0 || !ctx.trigger(Some(unit), "pigeon_sentry") {
            return;
        }
        ctx.slot_buff(
            slot,
            params.borrow().num("amount"),
            params.borrow().num("amount"),
            Some(unit),
            "",
        );
    }
}
