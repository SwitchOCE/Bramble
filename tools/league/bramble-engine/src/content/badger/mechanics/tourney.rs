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
// Source: src/content/badger/mechanics/tourney.gd
// Tourney Champion: Start of fight (main pass): this attacks the enemy with the most Attack, in
// either row, ignoring Guard (9.5.7; a tie goes to the first in reading order), and takes no
// damage from anything while that attack resolves.

#[derive(Clone, Default)]
pub struct Tourney;
pub type TourneyRef = Rc<RefCell<Tourney>>;
impl ToState for Tourney {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Tourney {
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Tourney unit");
        let side = unit.borrow().side;
        let mut target: Option<CombatUnitRef> = None;
        let enemies = combat.units(1 - side);
        let mut i = 0;
        while i < enemies.len() {
            let enemy = enemies.get(i).unwrap();
            if target
                .as_ref()
                .is_none_or(|target| enemy.borrow().attack() > target.borrow().attack())
            {
                target = Some(enemy);
            }
            i += 1;
        }
        if target.is_some() && combat.trigger(Some(unit), "badger_tourney") {
            combat.attack_now(Some(unit), target.as_ref(), true);
        }
    }
}
