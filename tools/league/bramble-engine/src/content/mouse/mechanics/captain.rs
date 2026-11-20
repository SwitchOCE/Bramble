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
// Source: src/content/mouse/mechanics/captain.gd
// One Cousin for each qualifying neighbouring attack until Charge runs out.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct Captain;
pub type CaptainRef = Rc<RefCell<Captain>>;
impl ToState for Captain {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Captain {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("limit", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_friendly_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        _defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if unit.borrow().gone || Rc::ptr_eq(attacker, unit) {
            return;
        }
        if !combat
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .neighbours(unit.borrow().slot)
            .has(&attacker.borrow().slot)
        {
            return;
        }
        if MouseRules::charge(combat, unit, "mouse_captain", params.borrow().num("limit")) {
            MouseRules::summon_cousins(combat, Some(unit), 1, false);
        }
    }
}
