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
// Source: src/core/mechanics/keywords/stealth.gd
// 11.2.6 Stealth (example keyword): can't be targeted by attacks until it attacks or deals
// damage. A Stealthed front-row unit still protects the back row (9.5.3).
pub const HIDDEN: &str = "stealth_hidden";
#[derive(Clone, Default)]
pub struct Stealth;
pub type StealthRef = Rc<RefCell<Stealth>>;
impl ToState for Stealth {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Stealth {
    fn on_combat_begin(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        unit.expect("Stealth unit")
            .borrow_mut()
            .set_state(HIDDEN, 1);
    }
    fn on_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        self._reveal(combat, unit);
    }
    fn on_damage_dealt(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _target: Option<&CombatUnitRef>,
        _amount: i64,
        _params: &MechanicParamsRef,
    ) {
        self._reveal(combat, unit);
    }
    fn combat_query(
        &self,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        _params: &MechanicParamsRef,
    ) -> i64 {
        if query == Q_UNTARGETABLE && unit.expect("Stealth unit").borrow().state_int(HIDDEN) != 0 {
            return 1;
        }
        value
    }
}
impl Stealth {
    pub fn _reveal(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>) {
        let unit = unit.expect("Stealth unit");
        if unit.borrow().state_int(HIDDEN) != 0 {
            unit.borrow_mut().set_state(HIDDEN, 0);
            combat.show_status(Some(unit), "stealth", false, None);
        }
    }
}
