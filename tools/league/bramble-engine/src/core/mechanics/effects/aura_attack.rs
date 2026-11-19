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
// Source: src/core/mechanics/effects/aura_attack.gd
// 12.2.1 an aura: adjacent units (8.2.2) have +amount Attack while this is on the board.

#[derive(Clone, Default)]
pub struct AuraAttack;
pub type AuraAttackRef = Rc<RefCell<AuraAttack>>;
impl ToState for AuraAttack {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for AuraAttack {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_parts(&self) -> u8 {
        AURA_STATS
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> (i64, i64) {
        if source_slot >= 0
            && view
                .geometry
                .as_ref()
                .expect("aura geometry")
                .borrow()
                .adjacent(source_slot)
                .borrow()
                .contains(&target_slot)
        {
            return (params.borrow().num("amount"), 0);
        }
        (0, 0)
    }
}
