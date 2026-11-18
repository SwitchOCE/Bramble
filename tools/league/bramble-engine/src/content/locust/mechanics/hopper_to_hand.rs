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
// Source: src/content/locust/mechanics/hopper_to_hand.gd
// Horde-runner. At the start of your turn, get `count` Hoppers in hand (Created; lost with a
// full hand, 7.1.2). Given, not summoned: Mother of Thousands doesn't double it.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct HopperToHand;
pub type HopperToHandRef = Rc<RefCell<HopperToHand>>;
impl ToState for HopperToHand {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for HopperToHand {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("count", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if unit.is_none() || !ctx.trigger(unit, "locust_hopper_to_hand") {
            return;
        }
        for _i in 0..params.borrow().num("count") {
            ctx.give_card(names::HOPPER, unit);
        }
    }
}
