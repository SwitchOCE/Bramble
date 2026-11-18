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
// Source: src/content/badger/mechanics/herald.gd
// Herald of the Charge: Start of fight (main pass): the units in front of this, any tribe,
// attack immediately, the left one first. Normal attacks: they take damage and their "whenever
// this attacks" effects trigger. A unit that can't attack doesn't.

#[derive(Clone, Default)]
pub struct Herald;
pub type HeraldRef = Rc<RefCell<Herald>>;
impl ToState for Herald {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Herald {
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Herald unit");
        let (slot, side) = {
            let u = unit.borrow();
            (u.slot, u.side)
        };
        let slots = combat.geometry.as_ref().unwrap().borrow().in_front_of(slot);
        crate::util::godot_sort::sort(&mut slots.borrow_mut());
        let charging = Array::new();
        let mut i = 0;
        while i < slots.len() {
            if let Some(front) = combat.unit_at(side, slots.get(i).unwrap()) {
                if !front.borrow().gone {
                    charging.push(front);
                }
            }
            i += 1;
        }
        if charging.is_empty() || !combat.trigger(Some(unit), "badger_herald") {
            return;
        }
        i = 0;
        while i < charging.len() {
            let front = charging.get(i).unwrap();
            if !front.borrow().gone && !front.borrow().should_die() {
                combat.attack_now(Some(&front), None, false);
            }
            i += 1;
        }
    }
}
