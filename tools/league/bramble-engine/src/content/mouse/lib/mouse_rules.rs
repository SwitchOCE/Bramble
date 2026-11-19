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
// Source: src/content/mouse/lib/mouse_rules.gd
// The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
// scripts in mechanics/. Not a mechanic itself, so it lives in lib/.
// side_query: percent of its Attack a pile-on hit deals (base 100; Dame Bodkin 200, golden 300).
// Fight count: how many times this unit has piled on this fight (a return carries it).
// Fight count, and the uses a screen shows: the Needle Pikeman's gains this fight.
// Hit the enemy with the least Health `times` times, choosing again for each (the core's
// weakest_enemy leaves out units already dying). False if none was hit.
// "After this piles on" effects, once `piler` has asked for its pile-on hit: its own (Needle
// Pikeman, Shrew Cutpurse) and its side's Fencing Masters. The hits land together after every
// friend has heard the attack, at the Attack each had when it asked, so a gain made here never
// counts for the hit that earned it, and every unit that piled on counts even when another's hit
// killed the target (rules.pile_on.together).
// Summons `count` Cousins from `source`'s slot (8.4.2), golden ones when `golden`. A Cousin
// never waits: with no room it is lost. Returns how many landed.
pub const TRIBE: &str = "Mouse";
pub const COUSIN: &str = "cousin";
pub const PILE_ON: &str = "mouse_pile_on";
pub const PILE_ON_UNCOUNTED: i64 = 0;
pub const PILE_ON_HEARD: &str = "mouse_pile_on_heard";
pub const HAND_ME_DOWN: &str = "mouse_hand_me_down";
pub const Q_PILE_PERCENT: &str = "mouse_pile_percent";
pub const PILES: &str = "mouse_piles";
pub const PIKE_GAINS: &str = "mouse_pikeman_gains";
#[derive(Clone, Default)]
pub struct MouseRules;
pub type MouseRulesRef = Rc<RefCell<MouseRules>>;
impl ToState for MouseRules {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl MouseRules {
    pub fn is_mouse(def: Option<&UnitDefRef>) -> bool {
        def.is_some_and(|def| def.borrow().has_tribe(TRIBE))
    }
    /// All Pile on sources add up. An uncounted source makes the total uncounted (7.3.5a).
    pub fn pile_on_count(unit: &CombatUnitRef) -> i64 {
        let mut total: i64 = 0;
        for bound in unit.borrow().hooks().iter_live() {
            let bound = bound.borrow();
            if bound.id != PILE_ON {
                continue;
            }
            let n = bound.params.borrow().num("pile_on");
            if n == PILE_ON_UNCOUNTED {
                return PILE_ON_UNCOUNTED;
            }
            total = total.wrapping_add(n);
        }
        total
    }
    /// Only the first Pile on hook resolves, including when multiple sources grant it.
    pub fn resolves_pile_on(unit: &CombatUnitRef, params: &MechanicParamsRef) -> bool {
        for bound in unit.borrow().hooks().iter_live() {
            let bound = bound.borrow();
            if bound.id == PILE_ON {
                return Rc::ptr_eq(&bound.params, params);
            }
        }
        false
    }
    pub fn use_pile_on(combat: &mut Combat, unit: &CombatUnitRef) -> bool {
        let limit = Self::pile_on_count(unit);
        if limit == PILE_ON_UNCOUNTED {
            return true;
        }
        if unit.borrow().fight_count(PILE_ON_HEARD) >= limit {
            return false;
        }
        unit.borrow_mut().add_fight_count(PILE_ON_HEARD, 1);
        let left = limit - unit.borrow().fight_count(PILE_ON_HEARD);
        combat.show_uses(Some(unit), PILE_ON, left, Some(unit));
        true
    }

    /// Hand-me-down (11.7.12–11.7.13) passes own Attack to the nearest friendly Mouse.
    pub fn hand_me_down(combat: &mut Combat, giver: &CombatUnitRef) -> Option<CombatUnitRef> {
        let attack = giver.borrow().stats.as_ref().unwrap().borrow().own_attack();
        if attack <= 0 {
            return None;
        }
        let heir = Self::nearest_mouse(combat, giver)?;
        if !combat.trigger(Some(giver), HAND_ME_DOWN) {
            return None;
        }
        combat.buff(Some(&heir), attack, 0, Some(giver), false);
        Some(heir)
    }
    /// Fewest neighbour steps (8.2.3) from the origin's last-known slot, ties in reading order.
    pub fn nearest_mouse(combat: &mut Combat, origin: &CombatUnitRef) -> Option<CombatUnitRef> {
        let (slot, side) = {
            let origin = origin.borrow();
            (origin.slot, origin.side)
        };
        let geometry = combat.geometry.as_ref().unwrap().clone();
        let steps = geometry.borrow().neighbour_steps(slot);
        let mut best: Option<CombatUnitRef> = None;
        let mut best_away = -1;
        for friend in combat.units(side).iter_live() {
            let unit = friend.borrow();
            if Rc::ptr_eq(&friend, origin) || unit.gone || !Self::is_mouse(unit.def.as_ref()) {
                continue;
            }
            if !geometry.borrow().is_valid(unit.slot) {
                continue;
            }
            let away = steps.get(unit.slot as usize).unwrap();
            if away < 0 {
                continue;
            }
            if best.as_ref().is_none_or(|best| {
                away < best_away || (away == best_away && unit.slot < best.borrow().slot)
            }) {
                best = Some(friend.clone());
                best_away = away;
            }
        }
        best
    }

    pub fn hit_weakest(combat: &mut Combat, unit: Option<&CombatUnitRef>, times: i64) -> bool {
        let unit = unit.expect("hit source");
        let mut any = false;
        for _time in 0..times {
            if unit.borrow().gone || combat.halted() {
                break;
            }
            let Some(target) = combat.weakest_enemy(Some(unit)) else {
                break;
            };
            combat.hit(Some(unit), Some(&target), 100);
            any = true;
        }
        any
    }
    pub fn after_pile_on(combat: &mut Combat, piler: &CombatUnitRef) {
        piler.borrow_mut().add_fight_count(PILES, 1);
        let first = piler.borrow().fight_count(PILES) == 1;
        let side = piler.borrow().side;
        let holders = combat.units(side).duplicate();
        let mut i = 0;
        while i < holders.len() {
            let holder = holders.get(i).unwrap();
            let hooks = holder.borrow().hooks();
            let mut j = 0;
            while j < hooks.len() {
                let bound = hooks.get(j).unwrap();
                if combat.halted() {
                    return;
                }
                let (id, params) = {
                    let bound = bound.borrow();
                    (bound.id.clone(), bound.params.clone())
                };
                match id.as_str() {
                    "mouse_pikeman" => {
                        if Rc::ptr_eq(&holder, piler) {
                            Self::_pikeman_grows(combat, piler, &params);
                        }
                    }
                    "mouse_cutpurse" => {
                        if Rc::ptr_eq(&holder, piler) && first && combat.trigger(Some(piler), &id) {
                            let side_index = piler.borrow().side;
                            let side = combat.bridge(side_index);
                            crate::core::combat::fight_side::FightSide::add_gold(
                                &side,
                                combat,
                                params.borrow().num("gold"),
                                Some(piler),
                            );
                        }
                    }
                    "mouse_fencing_master" => {
                        let is_mouse = Self::is_mouse(piler.borrow().def.as_ref());
                        if first && is_mouse && combat.trigger(Some(&holder), &id) {
                            combat.buff(
                                Some(piler),
                                params.borrow().num("attack"),
                                0,
                                Some(&holder),
                                true,
                            );
                        }
                    }
                    _ => {}
                }
                j += 1;
            }
            i += 1;
        }
    }
    pub fn _pikeman_grows(combat: &mut Combat, piler: &CombatUnitRef, params: &MechanicParamsRef) {
        let limit = params.borrow().num("limit");
        if piler.borrow().fight_count(PIKE_GAINS) >= limit {
            return;
        }
        if combat.trigger(Some(piler), "mouse_pikeman") {
            piler.borrow_mut().add_fight_count(PIKE_GAINS, 1);
            combat.buff(
                Some(piler),
                params.borrow().num("attack"),
                0,
                Some(piler),
                true,
            );
            let left = limit - piler.borrow().fight_count(PIKE_GAINS);
            combat.show_uses(Some(piler), PIKE_GAINS, left, Some(piler));
        }
    }
    pub fn summon_cousins(
        combat: &mut Combat,
        source: Option<&CombatUnitRef>,
        count: i64,
        golden: bool,
    ) -> i64 {
        let source = source.expect("cousin source");
        let mut landed = 0;
        for _i in 0..count {
            let (side, slot) = {
                let source = source.borrow();
                (source.side, source.slot)
            };
            let made = combat.summon(
                side,
                COUSIN,
                slot,
                false,
                Some(source),
                false,
                &Dictionary::new(),
                golden,
            );
            if made.is_none() {
                break;
            }
            landed += 1;
        }
        landed
    }
}
