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
// Source: src/content/locust/mechanics/brood.gd
// Brood Mother. When this dies, summon `count` Hoppers and add `bonus` to the player's Hopper
// bonus (every Hopper +bonus/+bonus for the rest of the game). Each time it resolves: a death,
// a drumbeat, being eaten; twice with a Dirge-singer.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct Brood;
pub type BroodRef = Rc<RefCell<Brood>>;
impl ToState for Brood {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Brood {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("count", Variant::Int(Kind::Number as i64));
        out.insert("bonus", Variant::Int(Kind::Number as i64));
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
        if !combat.trigger(unit, "locust_brood") {
            return;
        }
        Locust::summon_hoppers(combat, unit, params.borrow().num("count"), true);
        let side_index = unit.unwrap().borrow().side;
        let side = combat.bridge(side_index);
        FightSide::add_counter(
            &side,
            combat,
            names::HOPPER_BONUS,
            params.borrow().num("bonus"),
            unit,
        );
    }
    fn on_recruit_death(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !ctx.trigger(unit, "locust_brood") {
            return;
        }
        Locust::recruit_summon_hoppers(ctx, unit, params.borrow().num("count"));
        ctx.add_counter(names::HOPPER_BONUS, params.borrow().num("bonus"), unit);
    }
}
