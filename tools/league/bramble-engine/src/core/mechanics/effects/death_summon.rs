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
// Source: src/core/mechanics/effects/death_summon.gd
// Own death effect (9.7.2 step 2): summon `count` copies of `card`, the first into this unit's
// slot (8.4.1), the rest by 8.4.2-8.4.4.

#[derive(Clone, Default)]
pub struct DeathSummon;
pub type DeathSummonRef = Rc<RefCell<DeathSummon>>;
impl ToState for DeathSummon {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for DeathSummon {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("card", Variant::Int(Kind::Text as i64));
        out.insert("count", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !combat.trigger(unit, "death_summon") {
            return;
        }
        let count = params.borrow().num("count");
        for _i in 0..count {
            let unit_ref = unit.expect("Death Summon unit");
            let side = unit_ref.borrow().side;
            let card = params.borrow().text("card");
            let slot = unit_ref.borrow().slot;
            combat.summon(
                side,
                &card,
                slot,
                true,
                unit,
                &Dictionary::new(),
                false,
                crate::core::units::stat_block::StatBlock::UNSET,
            );
        }
    }
    fn has_death_effect(&self) -> bool {
        true
    }
}
