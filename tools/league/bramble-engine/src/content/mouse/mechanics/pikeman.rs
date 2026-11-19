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
// Source: src/content/mouse/mechanics/pikeman.gd
// Grows every friendly piler Mouse after its pile-on, through MouseRules.after_pile_on.

#[derive(Clone, Default)]
pub struct Pikeman;
pub type PikemanRef = Rc<RefCell<Pikeman>>;
impl ToState for Pikeman {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Pikeman {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out
    }
    fn combat_query(
        &self,
        _unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        _params: &MechanicParamsRef,
    ) -> i64 {
        if query == Q_CANT_ATTACK { 1 } else { value }
    }
}
