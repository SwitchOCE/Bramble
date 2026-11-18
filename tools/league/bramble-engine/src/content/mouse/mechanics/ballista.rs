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
// Source: src/content/mouse/mechanics/ballista.gd
// Toothpick Ballista: start of fight (main pass), Hit the enemy with the least Health, `times`
// times (golden: twice, choosing again). A Hit is not an attack.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct Ballista;
pub type BallistaRef = Rc<RefCell<Ballista>>;
impl ToState for Ballista {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Ballista {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("ballista unit");
        if unit.borrow().attack() <= 0 || combat.weakest_enemy(Some(unit)).is_none() {
            return;
        }
        if combat.trigger(Some(unit), "mouse_ballista") {
            MouseRules::hit_weakest(combat, Some(unit), params.borrow().num("times"));
        }
    }
}
