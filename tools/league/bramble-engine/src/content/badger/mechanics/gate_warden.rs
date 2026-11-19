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
// Source: src/content/badger/mechanics/gate_warden.gd
// Gate Warden: whenever this is attacked (9.6.1 step 1, before damage), gain +attack/+health
// permanently.
// A Hit, Overrun's carried damage and other plain damage are not attacks.

#[derive(Clone, Default)]
pub struct GateWarden;
pub type GateWardenRef = Rc<RefCell<GateWarden>>;
impl ToState for GateWarden {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for GateWarden {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out.insert("health", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_attacked(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if combat.trigger(unit, "badger_gate_warden") {
            let attack = params.borrow().num("attack");
            let health = params.borrow().num("health");
            combat.buff(unit, attack, health, unit, true);
        }
    }
}
