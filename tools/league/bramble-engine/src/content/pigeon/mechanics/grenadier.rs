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
// Source: src/content/pigeon/mechanics/grenadier.gd
// Grenadier Guard: Order (cost): make a slot (empty or not) your Guard post, clearing the old
// one; the post is a slot effect giving Guard (taunt) and stays when the Grenadier is sold. At
// the end of your turn, give the slot that is your Guard post then +attack/+health permanently;
// when the post moves, stats already given stay on the old slot.
pub const GUARD: &str = "taunt";
use crate::content::pigeon::mechanics::guard_post::GuardPost;
#[derive(Clone, Default)]
pub struct Grenadier;
pub type GrenadierRef = Rc<RefCell<Grenadier>>;
impl ToState for Grenadier {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Grenadier {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("cost", Variant::Int(Kind::Threshold as i64));
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_ability(&self) -> bool {
        true
    }
    fn ability_cost(&self, params: &MechanicParamsRef) -> i64 {
        params.borrow().num("cost")
    }
    fn ability_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::Slot
    }
    fn on_ability(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        _target: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let slot = ctx.target_index;
        if slot < 0 || !ctx.trigger(unit, "pigeon_grenadier") {
            return;
        }
        let old = GuardPost::post_of(&ctx.player.as_ref().unwrap().borrow().slots);
        if old == slot {
            return;
        }
        if old >= 0 {
            ctx.slot_clear_keyword(old, crate::content::pigeon::mechanics::guard_post::ID, unit);
            ctx.slot_clear_keyword(old, GUARD, unit);
        }
        ctx.slot_keyword(
            slot,
            crate::content::pigeon::mechanics::guard_post::ID,
            unit,
        );
        ctx.slot_keyword(slot, GUARD, unit);
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
        let post = GuardPost::post_of(&ctx.player.as_ref().unwrap().borrow().slots);
        if post < 0 || !ctx.trigger(Some(unit), "pigeon_grenadier") {
            return;
        }
        ctx.add_renown(post, params.borrow().num("amount"), Some(unit));
    }
}
