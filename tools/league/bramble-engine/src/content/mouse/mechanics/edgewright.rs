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
// Source: src/content/mouse/mechanics/edgewright.gd
// Edgewright: start of fight (set-up pass), your slots give double Attack this fight (golden:
// triple). The stored buffs don't change; the side reads them at that percent for the rest of the
// fight, even if the Edgewright dies (FightSide.set_slot_attack_percent). Two don't stack: the
// bigger applies. It stacks once with the give-time doubling (SHARED-RULES 13).

#[derive(Clone, Default)]
pub struct Edgewright;
pub type EdgewrightRef = Rc<RefCell<Edgewright>>;
impl ToState for Edgewright {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Edgewright {
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if combat.trigger(unit, "mouse_edgewright") {
            let side_index = unit.unwrap().borrow().side;
            let side = combat.bridge(side_index);
            crate::core::combat::fight_side::FightSide::set_slot_attack_percent(
                &side,
                combat,
                if params.borrow().golden { 300 } else { 200 },
                unit,
            );
        }
    }
}
