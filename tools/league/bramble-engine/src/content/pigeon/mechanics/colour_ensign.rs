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
// Source: src/content/pigeon/mechanics/colour_ensign.gd
// Colour Ensign: Start of fight (set-up pass): this slot copies your strongest slot's buff
// (Attack plus Health; first in reading order on a tie), for this fight, if it is bigger than
// its own. A copy is not a buff given (FightSide.slot_set), so the Sergeant Major doesn't double
// it; it stays on the slot for the fight after the Ensign dies. Golden: the slots next to it
// copy it too.

#[derive(Clone, Default)]
pub struct ColourEnsign;
pub type ColourEnsignRef = Rc<RefCell<ColourEnsign>>;
impl ToState for ColourEnsign {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for ColourEnsign {
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Colour Ensign unit");
        let side_index = unit.borrow().side;
        let side = combat.bridge(side_index);
        let slots = side.borrow().slots.clone();
        let mut best = -1;
        let mut best_total = 0;
        for index in 0..slots.len() {
            let slot = slots.get(index).unwrap();
            let total = slot.borrow().attack + slot.borrow().health;
            if best < 0 || total > best_total {
                best = index as i64;
                best_total = total;
            }
        }
        let targets = Array::from([unit.borrow().slot]);
        if unit.borrow().golden {
            let adjacent = combat
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .adjacent(unit.borrow().slot);
            for index in 0..adjacent.len() {
                targets.push(adjacent.get(index).unwrap());
            }
        }
        let copied = slots.get(best as usize).unwrap().borrow().duplicate_slot();
        let changes = Array::new();
        for index in 0..targets.len() {
            let slot = targets.get(index).unwrap();
            let here = slots.get(slot as usize).unwrap();
            if slot != best && best_total > here.borrow().attack + here.borrow().health {
                changes.push(slot);
            }
        }
        if changes.is_empty() || !combat.trigger(Some(unit), "pigeon_colour_ensign") {
            return;
        }
        for index in 0..changes.len() {
            let (attack, health) = {
                let copied = copied.borrow();
                (copied.attack, copied.health)
            };
            crate::core::combat::fight_side::FightSide::slot_set(
                &side,
                combat,
                changes.get(index).unwrap(),
                attack,
                health,
                false,
                Some(unit),
            );
        }
    }
}
