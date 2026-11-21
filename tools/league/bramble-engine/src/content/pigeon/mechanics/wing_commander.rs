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
// Source: src/content/pigeon/mechanics/wing_commander.gd
// Wing Commander gives permanent Renown to a friendly Sortie Pigeon's slot after it kills.
pub const SORTIE: &str = "pigeon_sortie";
#[derive(Clone, Default)]
pub struct WingCommander;
pub type WingCommanderRef = Rc<RefCell<WingCommander>>;
impl ToState for WingCommander {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for WingCommander {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"limit" => &(Kind::Number as i64),"amount" => &(Kind::Number as i64)}
            .as_dict()
    }
    fn on_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        self.on_friendly_kill(combat, unit, unit.unwrap(), victim, params);
    }
    fn on_friendly_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        killer: &CombatUnitRef,
        _victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        const WING: &str = "pigeon_wing_commander";
        let Some(unit) = unit else {
            return;
        };
        let limit = params.borrow().num("limit");
        if unit.borrow().fight_count(WING) >= limit
            || !killer
                .borrow()
                .def
                .as_ref()
                .unwrap()
                .borrow()
                .has_tribe("Pigeon")
            || !killer.borrow().has_mechanic(SORTIE)
            || !combat.trigger(Some(unit), WING)
        {
            return;
        }
        unit.borrow_mut().add_fight_count(WING, 1);
        let side = combat.bridge(unit.borrow().side);
        let slot = killer.borrow().slot;
        crate::core::combat::fight_side::FightSide::add_renown(
            &side,
            combat,
            slot,
            params.borrow().num("amount"),
            Some(unit),
        );
        let left = limit - unit.borrow().fight_count(WING);
        combat.show_uses(Some(unit), "pigeon_wing_commander_uses", left, Some(unit));
    }
}
