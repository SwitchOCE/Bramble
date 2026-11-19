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
// Source: src/content/locust/mechanics/glean.gd
// Gleaner. After a friendly unit dies (9.7.2 step 3, not its own), deal `amount` damage to the
// enemy with the most Health left, either row; a tie goes to the first in reading order.

#[derive(Clone, Default)]
pub struct Glean;
pub type GleanRef = Rc<RefCell<Glean>>;
impl ToState for Glean {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Glean {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(owner) = unit else {
            return;
        };
        let side = owner.borrow().side;
        let mut target: Option<CombatUnitRef> = None;
        let enemies = combat.units(1 - side);
        let mut index = 0;
        while index < enemies.len() {
            let enemy = enemies.get(index).unwrap();
            index += 1;
            if target
                .as_ref()
                .is_none_or(|target| enemy.borrow().health() > target.borrow().health())
            {
                target = Some(enemy);
            }
        }
        if target.is_some() && combat.trigger(unit, "locust_glean") {
            combat.deal_damage(unit, target.as_ref(), params.borrow().num("amount"), false);
        }
    }
}
