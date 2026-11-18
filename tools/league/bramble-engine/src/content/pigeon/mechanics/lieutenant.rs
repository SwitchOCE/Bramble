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
// Source: src/content/pigeon/mechanics/lieutenant.gd
// Lieutenant: Start of fight (main pass): if every slot of this row holds a unit (any tribe),
// each of them deals damage equal to the Attack its own slot gives it in this fight (an
// Edgewright's doubling and a Colour Ensign's copy included) to the enemy across from it (8.2.6);
// if that slot is empty, the nearest enemy in that row, else any enemy. Plain damage: not an
// attack and not a Hit. A golden deals `percent` 200.
// The enemy across from the dealer; if that slot is empty, the nearest enemy in that row, else
// any enemy. Only units the core still counts (combat.units leaves dying ones out).

#[derive(Clone, Default)]
pub struct Lieutenant;
pub type LieutenantRef = Rc<RefCell<Lieutenant>>;
impl ToState for Lieutenant {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Lieutenant {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("percent", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Lieutenant unit");
        let (side, slot) = {
            let u = unit.borrow();
            (u.side, u.slot)
        };
        let row = combat.geometry.as_ref().unwrap().borrow().row_of(slot);
        let dealers = Array::new();
        for index in 0..row.len() {
            let Some(here) = combat.unit_at(side, row.get(index).unwrap()) else {
                return;
            };
            if here.borrow().gone {
                return;
            }
            dealers.push(here);
        }
        if !combat.trigger(Some(unit), "pigeon_lieutenant") {
            return;
        }
        let mut index = 0;
        while index < dealers.len() {
            let dealer = dealers.get(index).unwrap();
            index += 1;
            let amount = (dealer.borrow().stats.as_ref().unwrap().borrow().slot_attack
                * params.borrow().num("percent")) as f64
                / 100.0;
            let amount = amount as i64;
            if amount <= 0 || combat.halted() {
                continue;
            }
            if let Some(target) = self._across(combat, &dealer) {
                combat.deal_damage(Some(&dealer), Some(&target), amount, false);
            }
        }
    }
}
impl Lieutenant {
    pub fn _across(&self, combat: &mut Combat, dealer: &CombatUnitRef) -> Option<CombatUnitRef> {
        let rest = combat.units(1 - dealer.borrow().side);
        if rest.is_empty() {
            return None;
        }
        let slot = combat
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .across(dealer.borrow().slot);
        let row = combat.geometry.as_ref().unwrap().borrow().row_of(slot);
        let mut best = None;
        let mut best_distance = f64::INFINITY;
        for index in 0..rest.len() {
            let candidate = rest.get(index).unwrap();
            let candidate_slot = candidate.borrow().slot;
            if !row.has(&candidate_slot) {
                continue;
            }
            let geometry = combat.geometry.as_ref().unwrap().borrow();
            let x = geometry.x_of(candidate_slot);
            let distance = (x - geometry.x_of(slot)).abs();
            if distance < best_distance {
                best = Some(candidate);
                best_distance = distance;
            }
        }
        if best.is_some() {
            return best;
        }
        let index = combat
            .effect_rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .index(rest.len() as i64);
        rest.get(index as usize)
    }
}
