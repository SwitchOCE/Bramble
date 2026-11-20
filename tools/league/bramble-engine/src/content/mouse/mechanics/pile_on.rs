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
// Pile on N (11.7.11): this hits first on the first N neighbour attacks (8.2.3).
// An attack heard at zero Attack spends a use. N is a threshold (7.3.5a).
// Sources add up and resolve once per attack. The count persists through a return.
// Every pile-on hit lands together once all friends have
// heard the attack (Combat.hit while joining), so a later piler still lands when an earlier one's
// hit was enough; a target they kill ends the attack before the exchange (9.6.1), and the kill is
// the piler's. A unit with 0 Attack doesn't pile on. Dame Bodkin's percent applies.

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
        crate::state_dict! { "pile_on" => &(Kind::Threshold as i64) }.as_dict()
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
