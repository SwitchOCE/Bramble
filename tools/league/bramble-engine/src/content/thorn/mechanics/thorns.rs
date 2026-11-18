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
// Source: src/content/thorn/mechanics/thorns.gd
// Thorns N: whenever this is attacked, deal N damage to the attacker first (9.6.1 step 1). Not
// an attack and not a Hit. Thorns from several sources add up: the first Thorns on the unit
// deals the total. An attacker it kills doesn't attack (the core ends the attack). An attack
// that takes no damage takes none (the core's NO_DAMAGE). A kill is noted for Lone Hawthorn.
// FightSide.state key: this enemy unit was killed by this side's Thorns.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct Thorns;
pub type ThornsRef = Rc<RefCell<Thorns>>;
impl ToState for Thorns {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Thorns {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_attacked(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.unwrap();
        let hooks = unit.borrow().hooks();
        if !Compost::is_first(&hooks, "thorn_thorns", params) {
            return;
        }
        let amount = Compost::total(&hooks, "thorn_thorns", "amount");
        if amount <= 0 || attacker.borrow().gone || !combat.trigger(Some(unit), "thorn_thorns") {
            return;
        }
        combat.deal_damage(Some(unit), Some(attacker), amount, false);
        if attacker.borrow().should_die() {
            let index = unit.borrow().side;
            combat
                .bridge(index)
                .borrow_mut()
                .set_state(combat, &Self::kill_key(attacker), 1);
        }
    }
}
impl Thorns {
    pub fn kill_key(attacker: &CombatUnitRef) -> String {
        format!("thorn_thorns_kill_{}", attacker.borrow().uid)
    }
}
