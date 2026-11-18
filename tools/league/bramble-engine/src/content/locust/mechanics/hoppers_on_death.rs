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
// Source: src/content/locust/mechanics/hoppers_on_death.gd
// Green Recruit. When this dies, summon `count` Hoppers: the first into its slot (8.4.1), the
// rest nearest (8.4.2); with no room they wait. Set off without a death (War-drummer) its slot
// is taken, so all go nearest or wait. Eaten in the shop they land on the recruit board.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct HoppersOnDeath;
pub type HoppersOnDeathRef = Rc<RefCell<HoppersOnDeath>>;
impl ToState for HoppersOnDeath {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for HoppersOnDeath {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("count", Variant::Int(Kind::Number as i64));
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
        if combat.trigger(unit, "locust_hoppers_on_death") {
            Locust::summon_hoppers(combat, unit, params.borrow().num("count"), true);
        }
    }
    fn on_recruit_death(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if ctx.trigger(unit, "locust_hoppers_on_death") {
            Locust::recruit_summon_hoppers(ctx, unit, params.borrow().num("count"));
        }
    }
}
