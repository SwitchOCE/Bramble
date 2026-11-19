#![allow(unused_imports, unused_variables)]
use crate::core::combat::fight_side::FightSide;
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
// Source: src/content/locust/mechanics/shed.gd
// Skin-shedder. Start of fight, set-up pass (ruling 41): the units next to this (8.2.2, same
// row, any tribe) get `charges` more Molt charges for this fight (one; two on a golden); one
// without Molt is given it. This unit doesn't Molt itself.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct Shed;
pub type ShedRef = Rc<RefCell<Shed>>;
impl ToState for Shed {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Shed {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("charges", Variant::Int(Kind::Number as i64));
        out
    }
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let targets = combat.select(unit, "adjacent");
        if targets.is_empty() || !combat.trigger(unit, "locust_shed") {
            return;
        }
        let side_index = unit.unwrap().borrow().side;
        let side = combat.bridge(side_index);
        let mut index = 0;
        while index < targets.len() {
            let target = targets.get(index).unwrap();
            index += 1;
            target
                .borrow_mut()
                .add_fight_count(names::MOLT_EXTRA, params.borrow().num("charges"));
            if !target.borrow().has_mechanic(names::MOLT) {
                FightSide::give_keyword(&side, combat, Some(&target), names::MOLT, false, unit);
            }
            combat.show_uses(
                Some(&target),
                names::MOLT,
                Locust::molt_left(Some(&target)),
                unit,
            );
        }
    }
}
