#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::slot_state::SlotStateRef;
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/content/pigeon/mechanics/guard_post.gd
// Guard post: a slot keyword (8.5). The Grenadier Guard's Order puts it on a slot together with
// Guard (taunt), so the unit standing there has both. A player has one; setting a new one clears
// the old. It is also a standing mechanic of every player: it answers which slot Reserve units
// fill first (Q_FILL_FIRST) from the side's slots, so an empty post is filled first.
// The slot holding the Guard post, or -1.
pub const ID: &str = "pigeon_guard_post";
#[derive(Clone, Default)]
pub struct GuardPost;
pub type GuardPostRef = Rc<RefCell<GuardPost>>;
impl ToState for GuardPost {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for GuardPost {
    fn side_query(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        _params: &MechanicParamsRef,
    ) -> i64 {
        if query != Q_FILL_FIRST || value >= 0 {
            return value;
        }
        let side_index = unit.map_or(combat.listening_side, |u| u.borrow().side);
        if side_index < 0 {
            return value;
        }
        Self::post_of(&combat.bridge(side_index).borrow().slots)
    }
}
impl GuardPost {
    pub fn post_of(slots: &Array<SlotStateRef>) -> i64 {
        for index in 0..slots.len() {
            if slots
                .get(index)
                .unwrap()
                .borrow()
                .keywords
                .has(&ID.to_string())
            {
                return index as i64;
            }
        }
        -1
    }
}
