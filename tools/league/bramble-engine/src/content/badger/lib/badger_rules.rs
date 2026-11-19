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
// Source: src/content/badger/lib/badger_rules.gd
// Rules the Badger mechanics share (SHARED-RULES, "Badgers own"): how much Fury a unit has.
// Not a mechanic: the scripts in mechanics/ preload it.
// side_query: what this side's Fury is multiplied by (base 1; the Marshal answers 2).
// Fury from every source, before the Marshal: every badger_fury the unit has, printed, given
// (Master-at-Arms for good; Sett Sexton and Sword-heir this fight) and from auras (Dame). They
// add up.
// The unit's own Fury (Sword-heir takes it): printed and given, not an aura's (Dame) or the
// Marshal's doubling.
// Gives `target` +`amount` Fury for the rest of this fight (Sett Sexton, Sword-heir): a
// badger_fury of its own, so a unit with no Fury now has some.
// True for the one badger_fury of a unit that resolves its Fury (the first in its hooks), so
// Fury from several sources triggers once.
// Fury N (9.6.1 steps 1 and 2): +N Attack, and +N more per unit outnumbering the side.
pub const Q_FURY_TIMES: &str = "badger_fury_times";
pub const FURY: &str = "badger_fury";
pub const GRUDGE: &str = "badger_grudge";
pub const KNIGHT: &str = "Knight";
pub const BADGER: &str = "Badger";
#[derive(Clone, Default)]
pub struct BadgerRules;
pub type BadgerRulesRef = Rc<RefCell<BadgerRules>>;
impl ToState for BadgerRules {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl BadgerRules {
    pub fn fury(unit: Option<&CombatUnitRef>) -> i64 {
        let unit = unit.expect("Fury unit");
        let mut total = 0;
        let hooks = unit.borrow().hooks();
        let mut i = 0;
        while i < hooks.len() {
            let bound = hooks.get(i).unwrap();
            if bound.borrow().id == FURY {
                total += bound.borrow().params.borrow().num("fury");
            }
            i += 1;
        }
        total
    }
    pub fn own_fury(unit: Option<&CombatUnitRef>) -> i64 {
        let unit = unit.expect("Fury unit");
        let mut total = 0;
        let mechanics = unit.borrow().mechanics.clone();
        let mut i = 0;
        while i < mechanics.len() {
            let bound = mechanics.get(i).unwrap();
            if bound.borrow().id == FURY {
                total += bound.borrow().params.borrow().num("fury");
            }
            i += 1;
        }
        total
    }
    pub fn give_fight_fury(
        combat: &mut Combat,
        target: Option<&CombatUnitRef>,
        amount: i64,
        source: Option<&CombatUnitRef>,
    ) {
        if amount > 0 {
            let side_index = target.expect("Fury target").borrow().side;
            let side = combat.bridge(side_index);
            let raw = Dictionary::new();
            raw.insert("fury", Variant::Int(amount));
            crate::core::combat::fight_side::FightSide::give_effect(
                &side, combat, target, FURY, &raw, false, source,
            );
        }
    }
    pub fn resolves_fury(unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) -> bool {
        let hooks = unit.expect("Fury unit").borrow().hooks();
        let mut i = 0;
        while i < hooks.len() {
            let bound = hooks.get(i).unwrap();
            if bound.borrow().id == FURY {
                return Rc::ptr_eq(&bound.borrow().params, params);
            }
            i += 1;
        }
        false
    }
    pub fn rage(combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) {
        let Some(unit) = unit else {
            return;
        };
        if unit.borrow().gone || !Self::resolves_fury(Some(unit), params) {
            return;
        }
        let side = unit.borrow().side;
        let times = combat.side_query(side, Q_FURY_TIMES, 1).max(1);
        let gain = Self::fury(Some(unit)) * times * (1 + combat.outnumbered_by(side));
        if gain <= 0 || !combat.trigger(Some(unit), FURY) {
            return;
        }
        combat.buff(Some(unit), gain, 0, Some(unit), false);
    }
    pub fn is_knight(def: Option<&UnitDefRef>) -> bool {
        def.is_some_and(|def| def.borrow().types.has(&KNIGHT.to_owned()))
    }
}
