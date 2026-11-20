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
// Source: src/content/badger/mechanics/grudge.gd
// Grudge N: after each fight, gain +N Health, and +N/+N more for each unit you were outnumbered
// by. Paid by the standing badger_grudge_pay, so a unit has it once whatever gives it.

#[derive(Clone, Default)]
pub struct Grudge;
pub type GrudgeRef = Rc<RefCell<Grudge>>;
impl ToState for Grudge {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Grudge {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("grudge", Variant::Int(Kind::Number as i64));
        out
    }
}
