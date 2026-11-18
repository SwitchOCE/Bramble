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
// Source: src/core/mechanics/effects/kill_gain.gd
// After this kills a unit (9.7.2 step 1): gain +attack/+health this combat, if it is alive.

#[derive(Clone, Default)]
pub struct KillGain;
pub type KillGainRef = Rc<RefCell<KillGain>>;
impl ToState for KillGain {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for KillGain {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out.insert("health", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/core/mechanics/effects/kill_gain.gd:on_kill")
    }
}
