//! Mirrors src/content/mouse/lib/mouse_rules.gd.
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef, fight_side::FightSide},
    mechanics::mechanic_params::MechanicParamsRef,
    units::unit_def::UnitDefRef,
};
use crate::{Array, Dictionary};
use std::rc::Rc;

pub const TRIBE: &str = "Mouse";
pub const COUSIN: &str = "cousin";
pub const PILE_ON: &str = "mouse_pile_on";
pub const PILE_ON_HEARD: &str = "mouse_pile_on_heard";
pub const HAND_ME_DOWN: &str = "mouse_hand_me_down";
pub const Q_PILE_PERCENT: &str = "mouse_pile_percent";

pub struct MouseRules;
impl MouseRules {
    pub fn is_mouse(def: Option<&UnitDefRef>) -> bool {
        def.is_some_and(|def| def.borrow().has_tribe(TRIBE))
    }

    /// All Pile on sources add up. Golden units keep their printed count (7.3.5a).
    pub fn pile_on_count(unit: &CombatUnitRef) -> i64 {
        let mut total: i64 = 0;
        for bound in unit.borrow().hooks().iter_live() {
            let bound = bound.borrow();
            if bound.id != PILE_ON {
                continue;
            }
            total = total.wrapping_add(bound.params.borrow().num("pile_on"));
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
        if unit.borrow().fight_count(PILE_ON_HEARD) >= limit {
            return false;
        }
        unit.borrow_mut().add_fight_count(PILE_ON_HEARD, 1);
        let left = limit - unit.borrow().fight_count(PILE_ON_HEARD);
        combat.show_uses(Some(unit), PILE_ON, left, Some(unit));
        true
    }

    /// Spend a charge before resolving an effect that can cause another use.
    pub fn charge(combat: &mut Combat, unit: &CombatUnitRef, id: &str, limit: i64) -> bool {
        if unit.borrow().fight_count(id) >= limit || !combat.trigger(Some(unit), id) {
            return false;
        }
        unit.borrow_mut().add_fight_count(id, 1);
        let left = limit - unit.borrow().fight_count(id);
        combat.show_uses(Some(unit), "mouse_charge_left", left, Some(unit));
        true
    }

    /// Living Mice in neighbour distance order (8.2.3), with ties in reading order.
    pub fn nearest_mice(combat: &mut Combat, origin: &CombatUnitRef) -> Array<CombatUnitRef> {
        let (slot, side) = {
            let origin = origin.borrow();
            (origin.slot, origin.side)
        };
        let steps = combat
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .neighbour_steps(slot);
        let mut heirs = Vec::new();
        for friend in combat.units(side).iter_live() {
            let unit = friend.borrow();
            if !Rc::ptr_eq(&friend, origin)
                && Self::is_mouse(unit.def.as_ref())
                && steps.borrow()[unit.slot as usize] >= 0
            {
                heirs.push(friend.clone());
            }
        }
        crate::util::godot_sort::sort_custom(&mut heirs, |a, b| {
            let (a, b) = (a.borrow().slot, b.borrow().slot);
            let steps = steps.borrow();
            if steps[a as usize] == steps[b as usize] {
                return a < b;
            }
            steps[a as usize] < steps[b as usize]
        });
        heirs.into()
    }

    /// Hand-me-down (11.7.12–11.7.13) passes own Attack in neighbour distance order.
    pub fn hand_me_down(combat: &mut Combat, giver: &CombatUnitRef) {
        let attack = giver.borrow().stats.as_ref().unwrap().borrow().own_attack();
        let heirs = Self::nearest_mice(combat, giver);
        if attack <= 0 || heirs.is_empty() || !combat.trigger(Some(giver), HAND_ME_DOWN) {
            return;
        }
        let mut attack = attack;
        let mut count = 1;
        let mut permanent = false;
        let side = giver.borrow().side;
        for friend in combat.units(side).iter_live() {
            let hooks = friend.borrow().hooks();
            for bound in hooks.iter_live() {
                let bound = bound.borrow();
                match bound.id.as_str() {
                    "mouse_bell_ringer" => {
                        attack = attack.wrapping_add(bound.params.borrow().num("attack"));
                    }
                    "mouse_widow" => count = count.max(bound.params.borrow().num("heirs")),
                    // The first Mother who can pay covers the entire gift.
                    "mouse_old_mother" if !permanent => {
                        permanent = Self::charge(
                            combat,
                            &friend,
                            &bound.id,
                            bound.params.borrow().num("limit"),
                        );
                    }
                    _ => {}
                }
            }
        }
        heirs.borrow_mut().truncate(count as usize);
        // Distribute first, then resolve each heir's Hobs before its Sister attack.
        for heir in heirs.iter_live() {
            combat.buff(Some(&heir), attack, 0, Some(giver), permanent);
        }
        for heir in heirs.iter_live() {
            if !heir.borrow().gone && !heir.borrow().should_die() {
                Self::after_inheriting(combat, &heir);
            }
        }
    }

    pub fn after_inheriting(combat: &mut Combat, heir: &CombatUnitRef) {
        let side = heir.borrow().side;
        for friend in combat.units(side).iter_live() {
            let hooks = friend.borrow().hooks();
            for bound in hooks.iter_live() {
                let bound = bound.borrow();
                if bound.id == "mouse_hob"
                    && Self::charge(
                        combat,
                        &friend,
                        &bound.id,
                        bound.params.borrow().num("limit"),
                    )
                {
                    combat.buff(
                        Some(heir),
                        bound.params.borrow().num("attack"),
                        0,
                        Some(&friend),
                        true,
                    );
                }
            }
        }
        let hooks = heir.borrow().hooks();
        for bound in hooks.iter_live() {
            let bound = bound.borrow();
            if bound.id == "mouse_sister"
                && Self::charge(combat, heir, &bound.id, bound.params.borrow().num("limit"))
            {
                combat.attack_now(Some(heir), None, false, None);
            }
        }
    }

    pub fn after_pile_on(combat: &mut Combat, piler: &CombatUnitRef) {
        let hooks = piler.borrow().hooks();
        for bound in hooks.iter_live() {
            let bound = bound.borrow();
            match bound.id.as_str() {
                "mouse_pikeman" if combat.trigger(Some(piler), &bound.id) => {
                    let side = piler.borrow().side;
                    for friend in combat.units(side).iter_live() {
                        let piler_mouse = {
                            let friend = friend.borrow();
                            Self::is_mouse(friend.def.as_ref()) && friend.has_mechanic(PILE_ON)
                        };
                        if piler_mouse {
                            combat.buff(
                                Some(&friend),
                                bound.params.borrow().num("attack"),
                                0,
                                Some(piler),
                                true,
                            );
                        }
                    }
                }
                "mouse_cutpurse" if combat.trigger(Some(piler), &bound.id) => {
                    let side = combat.bridge(piler.borrow().side);
                    FightSide::add_gold(
                        &side,
                        combat,
                        bound.params.borrow().num("gold"),
                        Some(piler),
                    );
                }
                "mouse_fencing_master" if combat.trigger(Some(piler), &bound.id) => {
                    combat.buff(
                        Some(piler),
                        bound.params.borrow().num("attack"),
                        0,
                        Some(piler),
                        true,
                    );
                }
                _ => {}
            }
        }
    }

    // 8.4.2 A Cousin lands outward from the source and never waits for a vacancy.
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
                &Dictionary::new(),
                golden,
                crate::core::units::stat_block::StatBlock::UNSET,
            );
            if made.is_none() {
                break;
            }
            landed += 1;
        }
        landed
    }
}
