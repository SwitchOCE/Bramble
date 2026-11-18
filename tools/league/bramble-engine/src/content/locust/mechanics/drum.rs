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
// Source: src/content/locust/mechanics/drum.gd
// War-drummer. Whenever this attacks (every attack, out-of-turn ones too), from the front row
// only: a unit in the slots behind it (8.2.1) that has a death effect, at random if two, has
// its death effects resolve `times` times where it stands. Nothing died: no death counts, no
// "after a friendly unit dies", no return (ruling 31). Dirge-singer doubles each (ruling 33).

#[derive(Clone, Default)]
pub struct Drum;
pub type DrumRef = Rc<RefCell<Drum>>;
impl ToState for Drum {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Drum {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let slot = unit.unwrap().borrow().slot;
        if !combat.geometry.as_ref().unwrap().borrow().front.has(&slot) {
            return;
        }
        let behind = Array::new();
        let friends = combat.select(unit, "behind");
        let mut index = 0;
        while index < friends.len() {
            let friend = friends.get(index).unwrap();
            index += 1;
            if friend.borrow().has_death_effect() {
                behind.push(friend);
            }
        }
        if behind.is_empty() || !combat.trigger(unit, "locust_drum") {
            return;
        }
        let chosen = combat
            .effect_rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .index(behind.len() as i64);
        let drummed = behind.get(chosen as usize).unwrap();
        for _i in 0..params.borrow().num("times") {
            if drummed.borrow().gone {
                return;
            }
            combat.run_death_effects(Some(&drummed));
        }
    }
}
