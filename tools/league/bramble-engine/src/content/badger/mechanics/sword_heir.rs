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
// Source: src/content/badger/mechanics/sword_heir.gd
// Sword-heir: after a unit in front of this dies (9.7.2 step 3, by its last-known slot), gain its
// own Attack and own maximum Health (SHARED-RULES 43: excluding Renown, lent stats, auras and Tide)
// and its own Fury (printed and given; not an aura's or the Marshal's), this fight. Golden:
// double the Attack and Health (`times`), not the Fury.

use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct SwordHeir;
pub type SwordHeirRef = Rc<RefCell<SwordHeir>>;
impl ToState for SwordHeir {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for SwordHeir {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if Rc::ptr_eq(dead, unit) || dead.borrow().side != unit.borrow().side {
            return;
        }
        if !combat
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .in_front_of(unit.borrow().slot)
            .has(&dead.borrow().slot)
        {
            return;
        }
        if !combat.trigger(Some(unit), "badger_sword_heir") {
            return;
        }
        BadgerRules::give_fight_fury(
            combat,
            Some(unit),
            BadgerRules::own_fury(Some(dead)),
            Some(unit),
        );
        let times = params.borrow().num("times");
        let (attack, health) = {
            let dead = dead.borrow();
            let stats = dead.stats.as_ref().unwrap().borrow();
            (stats.own_attack() * times, stats.own_health() * times)
        };
        combat.buff(Some(unit), attack, health, Some(unit), false);
    }
}
