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
// Source: src/content/mouse/mechanics/pile_on.gd
// Pile on N (rulebook 11.7.11): the first N times a neighbour (next to, in front of or behind: up
// to four, 8.2.3; any tribe) attacks each fight, this hits the target first. N counts the neighbour
// attacks this unit hears, not its hits: an attack it hears with 0 Attack still uses one. `pile_on`
// is a NUMBER, so a golden doubles N (7.3.5). Several Pile ons on one unit add up and pile on once
// (MouseRules.pile_on_count). Pile-on hits queue once all friends have heard the attack (Combat.hit
// while joining) and land in order; once the target is dead, the rest are skipped (owner, 20 Nov
// 2026: a dead unit isn't hit again). A target they kill ends the attack before the exchange
// (9.6.1); the kill is the piler whose hit was lethal. A unit with 0 Attack doesn't pile on. Dame
// Bodkin's percent applies. The count is a fight count, so a return keeps it (SHARED-RULES 21); a
// counted piler shows its uses left under its own id, and its pill dims at 0.

use crate::content::mouse::lib::mouse_rules::{MouseRules, PILE_ON, Q_PILE_PERCENT};
#[derive(Clone, Default)]
pub struct PileOn;
pub type PileOnRef = Rc<RefCell<PileOn>>;
impl ToState for PileOn {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for PileOn {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "pile_on" => &(Kind::Number as i64) }.as_dict()
    }

    fn on_friendly_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if !combat
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .neighbours(unit.borrow().slot)
            .has(&attacker.borrow().slot)
        {
            return;
        }
        if !MouseRules::resolves_pile_on(unit, params) {
            return;
        }
        if !MouseRules::use_pile_on(combat, unit) {
            return;
        }
        if unit.borrow().attack() <= 0 || !combat.trigger(Some(unit), PILE_ON) {
            return;
        }
        let (side, is_mouse) = {
            let unit = unit.borrow();
            (unit.side, MouseRules::is_mouse(unit.def.as_ref()))
        };
        let mut percent = 100;
        if is_mouse {
            percent = combat.side_query(side, Q_PILE_PERCENT, percent);
        }
        let piler = unit.clone();
        combat.hit_with_after(
            Some(unit),
            Some(defender),
            percent,
            Some(Rc::new(move |combat| {
                MouseRules::after_pile_on(combat, &piler)
            })),
        );
    }
}
