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
// Source: src/content/pigeon/mechanics/squadron_leader.gd
// Squadron Leader: an aura on the units in the two slots in front of this (any tribe): Sortie
// and +attack Attack. Borrowed stats, in both phases.

#[derive(Clone, Default)]
pub struct SquadronLeader;
pub type SquadronLeaderRef = Rc<RefCell<SquadronLeader>>;
impl ToState for SquadronLeader {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for SquadronLeader {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_parts(&self) -> u8 {
        AURA_STATS | AURA_KEYWORDS
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> (i64, i64) {
        if self._covers(view, source_slot, target_slot) {
            return (params.borrow().num("attack") as i32 as i64, 0);
        }
        (0, 0)
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        let out = Array::new();
        if self._covers(view, source_slot, target_slot) {
            out.push("pigeon_sortie".to_string());
        }
        out
    }
}
impl SquadronLeader {
    pub fn _covers(&self, view: &AuraContext, source_slot: i64, target_slot: i64) -> bool {
        source_slot >= 0
            && view
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .in_front_of(source_slot)
                .has(&target_slot)
    }
}
