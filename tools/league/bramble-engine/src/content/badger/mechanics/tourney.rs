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
// Tourney Champion: Start of fight (main pass): attacks the enemies with the most Attack,
// ignoring Guard (9.5.7). Ties are broken in reading order. These attacks take no damage.

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
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"targets" => &(Kind::Number as i64)}.as_dict()
    }

    fn text_params(&self, params: &MechanicParamsRef) -> Dictionary {
        let count = params.borrow().num("targets");
        let words = if count == 1 {
            "the enemy".into()
        } else {
            format!("the {count} enemies")
        };
        crate::state_dict! {"top_enemies" => &words}.as_dict()
    }

    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Tourney unit");
        let side = unit.borrow().side;
        let mut enemies = combat.units(1 - side).to_vec();
        crate::util::godot_sort::sort_custom(&mut enemies, |a, b| {
            let (a, b) = (a.borrow(), b.borrow());
            if a.attack() == b.attack() {
                a.slot < b.slot
            } else {
                a.attack() > b.attack()
            }
        });
        let count = params.borrow().num("targets").min(enemies.len() as i64);
        if count <= 0 || !combat.trigger(Some(unit), "badger_tourney") {
            return;
        }
        for target in enemies.iter().take(count as usize) {
            let target_alive = !target.borrow().gone && !target.borrow().should_die();
            if target_alive && !combat.attack_now(Some(unit), Some(target), true, None) {
                break;
            }
        }
    }
}
