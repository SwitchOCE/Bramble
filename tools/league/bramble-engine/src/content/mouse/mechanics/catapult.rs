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
// Source: src/content/mouse/mechanics/catapult.gd
// Spoon Catapult: instead of attacking, Hit the enemy with the least Health. That uses its turn
// and counts toward the attack limit. Golden, or with "attacks twice" (Kettle-drummer), it Hits
// twice, choosing again. Told to attack out of turn, it makes an ordinary attack (the core's
// attack_now doesn't ask instead_of_attack).

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct Catapult;
pub type CatapultRef = Rc<RefCell<Catapult>>;
impl ToState for Catapult {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Catapult {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn instead_of_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) -> bool {
        if combat.weakest_enemy(unit).is_none() {
            return false;
        }
        if !combat.trigger(unit, "mouse_catapult") {
            return false;
        }
        let mut times = params.borrow().num("times");
        if crate::core::combat::combat_unit::CombatUnit::query(unit.unwrap(), Q_ATTACKS, 1) >= 2 {
            times = times.max(2);
        }
        MouseRules::hit_weakest(combat, unit, times);
        true
    }
}
