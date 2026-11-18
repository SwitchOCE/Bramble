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
// Source: src/content/badger/mechanics/overrun.gd
// Overrun: when an attack by this unit deals more damage in the damage exchange than its target
// has Health left, the rest is dealt to another enemy, picked as this unit's next attack would
// pick (combat.choose_target, which never picks a dying unit), and so on. Only the first target
// was attacked and strikes back; the carried damage is plain damage (no Thorns, Fury or "is
// attacked"), and its kills are this unit's. Not for a Hit or a pile-on hit; if a pile-on killed
// the target there is no exchange and nothing to carry. A target saved by Stiff Upper Lip or a
// shield wasn't killed, so nothing carries on (SHARED-RULES 28).
//
// combat.damage_from_own_attack() is true only for this unit's own attack on its target: not its
// strike back when it is attacked, a Cleave splash, a Hit or the carried damage itself.

#[derive(Clone, Default)]
pub struct Overrun;
pub type OverrunRef = Rc<RefCell<Overrun>>;
impl ToState for Overrun {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Overrun {
    fn on_damage_dealt(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        _amount: i64,
        _params: &MechanicParamsRef,
    ) {
        let target = target.expect("Overrun target");
        if !combat.damage_from_own_attack() || target.borrow().health() >= 0 {
            return;
        }
        let unit = unit.expect("Overrun unit");
        let mut rest = -target.borrow().health();
        while rest > 0 && !combat.halted() {
            let next = combat.choose_target(unit);
            if next.is_none() || !combat.trigger(Some(unit), "badger_overrun") {
                return;
            }
            let next = next.unwrap();
            let before = next.borrow().health();
            combat.deal_damage(Some(unit), Some(&next), rest, false);
            rest = if next.borrow().should_die() {
                rest - before
            } else {
                0
            };
        }
    }
}
