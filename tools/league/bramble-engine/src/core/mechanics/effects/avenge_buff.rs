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
// Source: src/core/mechanics/effects/avenge_buff.gd
// A death counter (9.7.4, like HSBG's Avenge): each time `every` friendly units have died this
// combat, give all friendly units +attack/+health this combat. `every` is a threshold, so a
// golden copy keeps it (7.3.5).
pub const COUNT: &str = "avenge_count";
#[derive(Clone, Default)]
pub struct AvengeBuff;
pub type AvengeBuffRef = Rc<RefCell<AvengeBuff>>;
impl ToState for AvengeBuff {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for AvengeBuff {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("every", Variant::Int(Kind::Threshold as i64));
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out.insert("health", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.expect("Avenge unit");
        let count = unit.borrow().state_int(COUNT).wrapping_add(1);
        unit.borrow_mut().set_state(COUNT, count);
        let every = params.borrow().num("every").max(1);
        if count % every != 0 || !combat.trigger(Some(unit), "avenge_buff") {
            return;
        }
        let friends = combat.select(Some(unit), "all");
        let mut index = 0;
        while index < friends.len() {
            let friend = friends.get(index).expect("friendly unit");
            let attack = params.borrow().num("attack");
            let health = params.borrow().num("health");
            combat.buff(Some(&friend), attack, health, Some(unit), false);
            index += 1;
        }
    }
}
