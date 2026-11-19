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
// Source: src/content/badger/mechanics/oakfeller.gd
// The Oakfeller: after this attacks and kills a unit with its own damage (the target, or one
// reached by Overrun), it attacks once more, at once. The extra attack never earns another. A
// kill a neighbour's pile-on makes is not its kill.
//
// State on the fight unit: SWING is 1 while a normal attack's deaths resolve and 2 for the
// extra attack's; a kill during a normal swing sets PENDING, and the extra attack is made
// after that round of deaths (once the dead have left the board).
pub const SWING: &str = "badger_oak_swing";
pub const PENDING: &str = "badger_oak_pending";
pub const EXTRA: &str = "badger_oak_extra";
#[derive(Clone, Default)]
pub struct Oakfeller;
pub type OakfellerRef = Rc<RefCell<Oakfeller>>;
impl ToState for Oakfeller {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Oakfeller {
    fn on_attack(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Oakfeller unit");
        let swing = if unit.borrow().state_int(EXTRA) != 0 {
            2
        } else {
            1
        };
        unit.borrow_mut().set_state(SWING, swing);
    }
    fn on_attacked(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        unit.expect("Oakfeller unit")
            .borrow_mut()
            .set_state(SWING, 0);
    }
    fn on_kill(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _victim: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Oakfeller unit");
        if unit.borrow().state_int(SWING) == 1 {
            unit.borrow_mut().set_state(PENDING, 1);
        }
    }
    fn after_death_round(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        unit.borrow_mut().set_state(SWING, 0);
        if unit.borrow().state_int(PENDING) == 0 {
            return;
        }
        unit.borrow_mut().set_state(PENDING, 0);
        let side = unit.borrow().side;
        if unit.borrow().gone || combat.units(1 - side).is_empty() {
            return;
        }
        if !combat.trigger(Some(unit), "badger_oakfeller") {
            return;
        }
        unit.borrow_mut().set_state(EXTRA, 1);
        combat.attack_now(Some(unit), None, false, None);
        unit.borrow_mut().set_state(EXTRA, 0);
        unit.borrow_mut().set_state(SWING, 0);
    }
}
