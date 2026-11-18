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
// Source: src/core/mechanics/keywords/venomous.gd
// 11.2.5 Venomous (example keyword): destroys the first unit it deals damage to each combat.
pub const USED: &str = "venom_used";
#[derive(Clone, Default)]
pub struct Venomous;
pub type VenomousRef = Rc<RefCell<Venomous>>;
impl ToState for Venomous {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Venomous {
    fn on_damage_dealt(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        _amount: i64,
        _params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Venomous unit");
        let target = target.expect("Venomous target");
        if unit.borrow().state_int(USED) != 0 || target.borrow().gone {
            return;
        }
        if !combat.trigger(Some(unit), "venomous") {
            return;
        }
        unit.borrow_mut().set_state(USED, 1);
        combat.destroy(Some(unit), Some(target));
        combat.show_status(Some(unit), "venomous", false, Some(unit));
    }
}
