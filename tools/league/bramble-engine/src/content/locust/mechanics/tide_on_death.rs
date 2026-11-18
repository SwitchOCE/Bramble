#![allow(unused_imports, unused_variables)]
use crate::core::combat::fight_side::FightSide;
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
// Source: src/content/locust/mechanics/tide_on_death.gd
// Famine-caller. When this dies, Tide +`amount`: at once, for the rest of the game, whether it
// died, was drummed or was eaten.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct TideOnDeath;
pub type TideOnDeathRef = Rc<RefCell<TideOnDeath>>;
impl ToState for TideOnDeath {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for TideOnDeath {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_death_effect(&self) -> bool {
        true
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if combat.trigger(unit, "locust_tide_on_death") {
            let side_index = unit.unwrap().borrow().side;
            let side = combat.bridge(side_index);
            FightSide::add_counter(
                &side,
                combat,
                names::TIDE,
                params.borrow().num("amount"),
                unit,
            );
        }
    }
    fn on_recruit_death(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if ctx.trigger(unit, "locust_tide_on_death") {
            ctx.add_counter(names::TIDE, params.borrow().num("amount"), unit);
        }
    }
}
