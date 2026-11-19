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
// Source: src/core/mechanics/effects/triple_reward.gd
// 7.3.6 the Triple Reward: Discover a unit from the tier above the player's tier when cast,
// or the top tier at the top (Rules.triple_reward_tier).

#[derive(Clone, Default)]
pub struct TripleReward;
pub type TripleRewardRef = Rc<RefCell<TripleReward>>;
impl ToState for TripleReward {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for TripleReward {
    fn on_played(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        _target: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
        if ctx.trigger(unit, "triple_reward") {
            let rules = ctx
                .session
                .as_ref()
                .unwrap()
                .borrow()
                .rules
                .as_ref()
                .unwrap()
                .clone();
            let tier = rules
                .borrow()
                .triple_reward_tier(ctx.player.as_ref().unwrap());
            ctx.discover(tier, tier);
        }
    }
}
