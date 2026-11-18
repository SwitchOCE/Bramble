#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/fight_deaths.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::{CombatUnit, CombatUnitRef};
use crate::core::combat::fight_side::FightSide;
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::{Hook, HookArgs},
};
fn binding(
    bound: &BoundMechanicRef,
) -> (
    crate::core::mechanics::mechanic::MechanicRef,
    crate::core::mechanics::mechanic_params::MechanicParamsRef,
) {
    let b = bound.borrow();
    (b.mechanic.clone().unwrap(), b.params.clone())
}

// GDScript rule and contract comments:
// Death resolution (rulebook 9.7), the one return protocol (9.8, SHARED-RULES 15-22) and the
// end of a fight (9.9, 10.1.2), for Combat. Mechanics never call this; they act through Combat.
// 9.7: every unit at 0 Health or destroyed dies. Dying units leave their slots first (9.7.1);
// then, in order active side first then reading order (9.7.3): step 1 kills and "whenever a
// unit dies"; step 2 own death effects and friendly death counters; step 3 "after a friendly
// unit dies"; step 4 returns; step 5 "after a friendly unit returns"; then the slot-fill order
// (FightArrivals: Reserve, waiting summons, after_death_round); new deaths start another pass
// (step 6).
// 9.8.2-9.8.3, 9.10.3, SHARED-RULES 15-22: the one return protocol. Every mechanic on the dying
// unit may offer a return (Mechanic.return_offer); the highest return_priority wins (Root's
// RETURN_FIRST before Molt's RETURN_PLAIN, ruling 17), ties in hook order; with no offer the
// unit stays dead (the one way to return: Molt, Root and the core's Reborn all offer here). One
// return for each death,
// at most config.return_limit a fight for one unit. The unit comes back to its own slot, else
// the nearest empty one:
// - as a plain copy (a fresh card, golden kept, no counters, buffs or given keywords; 9.8.2,
// glossary "Plain copy"), or as its recruit unit stands when the chosen offer says so
// (return_as_recruit: Root, ruling 16);
// - carrying its per-fight limits (CombatUnit.fight_counts, ruling 21) and its uses shown.
// The chosen mechanic's pay_return runs, then on_returned for every mechanic the dead unit had;
// then it is logged as one `return` event (the new unit's view as it now stands, `from_uid`,
// `mechanic`), followed by what those hooks logged. Not a summon, and on_fight_enter does not
// hear it (ruling 22: a return is not joining the fight). "After a friendly unit returns"
// follows in death step 5.
// 9.9 and 10.1.2: the winner, and how many of each side's starting units were killed (a
// starting unit is killed unless it, or its return, is alive on its own side at the end).
// The fight log's views of a side: its unit uids, its units, its slots.
pub type FightDeathsRef = Rc<RefCell<FightDeaths>>;
pub struct FightDeaths {
    pub _combat_ref: Option<Weak<RefCell<Combat>>>,
}
impl Default for FightDeaths {
    fn default() -> Self {
        Self { _combat_ref: None }
    }
}
impl ToState for FightDeaths {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "_combat_ref" => &if self._combat_ref.is_some() { Variant::dictionary(Default::default()) } else { Variant::Nil },
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["_combat_ref"]
    }
}
impl FightDeaths {
    pub fn create(combat: &CombatRef) -> FightDeathsRef {
        Rc::new(RefCell::new(Self {
            _combat_ref: Some(Rc::downgrade(combat)),
        }))
    }
    pub fn _combat(&self) -> Option<CombatRef> {
        self._combat_ref.as_ref().and_then(Weak::upgrade)
    }
    pub fn resolve(&mut self, combat: &mut Combat, active_side: i64) {
        while combat._halt_reason.is_empty() {
            let dying = Array::new();
            for side in [active_side, 1 - active_side] {
                for unit in combat._board(side).to_vec() {
                    if unit.borrow().should_die() {
                        dying.push(unit);
                    }
                }
            }
            if dying.is_empty() {
                return;
            }
            let emptied = Array::from(vec![Array::new(), Array::new()]);
            for unit in dying.to_vec() {
                let side = unit.borrow().side;
                let slot = unit.borrow().slot;
                let id = unit.borrow().uid;
                emptied.get(side as usize).unwrap().push(slot);
                unit.borrow_mut().gone = true;
                combat.sides.get(side as usize).unwrap().borrow_mut()[slot as usize] = None;
                combat._units_cache.borrow_mut()[side as usize] = None;
                let killer = combat._hit_by.borrow().get(&id).cloned().flatten();
                if combat.keep_events {
                    combat._log(&crate::state_dict!{"type"=>"death","side"=>&side,"slot"=>&slot,"uid"=>&id,"killer_uid"=>&killer.map_or(-1,|k|k.borrow().uid)}.as_dict());
                }
            }
            combat._refresh_auras();
            self._death_steps(combat, &dying, active_side);
            let back = Array::new();
            for unit in dying.to_vec() {
                if let Some(returned) = self._try_return(combat, Some(&unit)) {
                    back.push(returned);
                }
            }
            for unit in back.to_vec() {
                combat._notify_friends(
                    &unit,
                    Hook::AfterFriendlyReturn,
                    &HookArgs::FriendlyReturn { back: unit.clone() },
                );
            }
            let mut arrivals = {
                let a = combat.arrivals.as_ref().unwrap().borrow();
                super::fight_arrivals::FightArrivals {
                    reserve: a.reserve.clone(),
                    waiting: a.waiting.clone(),
                    _combat_ref: a._combat_ref.clone(),
                }
            };
            arrivals.after_deaths(combat, &emptied, active_side);
        }
    }
    pub fn _death_steps(
        &mut self,
        combat: &mut Combat,
        dying: &Array<CombatUnitRef>,
        active_side: i64,
    ) {
        for unit in dying.to_vec() {
            let killer = combat
                ._hit_by
                .borrow()
                .get(&unit.borrow().uid)
                .cloned()
                .flatten();
            if let Some(killer) = killer
                && killer.borrow().side != unit.borrow().side
            {
                let hooks = killer.borrow().hooks();
                let mut i = 0;
                while let Some(bound) = hooks.get(i) {
                    i += 1;
                    let (m, p) = binding(&bound);
                    m.on_kill(combat, Some(&killer), &unit, &p);
                }
            }
        }
        for unit in dying.to_vec() {
            for side in [active_side, 1 - active_side] {
                combat._notify(
                    side,
                    Hook::OnAnyDeath,
                    &HookArgs::Death { dead: unit.clone() },
                );
            }
        }
        for unit in dying.to_vec() {
            combat.run_death_effects(Some(&unit));
            let side = unit.borrow().side;
            combat._notify(
                side,
                Hook::OnFriendlyDeath,
                &HookArgs::Death { dead: unit.clone() },
            );
        }
        // SHARED-RULES (The Eighth Plague): count each death immediately before its after hook.
        for unit in dying.to_vec() {
            let side = unit.borrow().side;
            combat.bridge(side).borrow_mut().deaths += 1;
            combat._notify(
                side,
                Hook::AfterFriendlyDeath,
                &HookArgs::Death { dead: unit.clone() },
            );
        }
    }
    pub fn _try_return(
        &mut self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
    ) -> Option<CombatUnitRef> {
        let unit = unit.unwrap();
        if unit.borrow().returns >= combat.config.as_ref().unwrap().borrow().return_limit
            || !combat._halt_reason.is_empty()
        {
            return None;
        }
        let mut chosen = None;
        let mut health = 0;
        let mut best = -1;
        let hooks = unit.borrow().hooks();
        let mut i = 0;
        while let Some(bound) = hooks.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            let offered = m.return_offer(combat, Some(unit), &p);
            let rank = m.return_priority(&p);
            if offered > 0 && rank > best {
                chosen = Some(bound);
                health = offered;
                best = rank;
            }
        }
        let chosen = chosen?;
        let (m, p) = binding(&chosen);
        let as_recruit = m.return_as_recruit(&p);
        let side = unit.borrow().side;
        let own_slot = unit.borrow().slot;
        let occupied = combat._occupied(side);
        let slot = combat
            .geometry
            .as_ref()
            .unwrap()
            .borrow()
            .summon_slot(&occupied, own_slot, true);
        let mechanic_id = chosen.borrow().id.clone();
        if slot < 0 || !combat.trigger(Some(unit), &mechanic_id) {
            return None;
        }
        let card = unit.borrow().def.clone().unwrap();
        let new_uid = combat._take_uid();
        let golden = unit.borrow().golden;
        let mut back = CombatUnit::fresh(
            &card,
            new_uid,
            side,
            golden,
            combat.registry.as_ref().unwrap(),
            combat.config.as_ref().unwrap().borrow().stat_max,
        );
        let recruit_copy = combat
            .bridge(side)
            .borrow()
            .recruit_unit(combat, Some(unit));
        if as_recruit && let Some(recruit_copy) = recruit_copy {
            back = CombatUnit::from_unit(&recruit_copy, new_uid, side);
        }
        {
            let u = unit.borrow();
            let mut b = back.borrow_mut();
            b.bought = u.bought;
            b.returns = u.returns + 1;
            b.starting = u.starting;
            b.recruit_uid = u.recruit_uid;
            b.fight_counts = u.fight_counts.duplicate();
            b.uses = u.uses.duplicate();
            b.damage = (b.max_health() - health).max(0);
        }
        combat._place(Some(&back), slot);
        let outer = std::mem::take(&mut combat._held);
        let outer_holding = combat._holding;
        combat._holding = true;
        m.pay_return(combat, unit, &back, &p);
        let hooks = unit.borrow().hooks();
        let mut i = 0;
        while let Some(bound) = hooks.get(i) {
            i += 1;
            let (m, p) = binding(&bound);
            m.on_returned(combat, unit, &back, &p);
        }
        let after = std::mem::replace(&mut combat._held, outer);
        combat._holding = outer_holding;
        if combat.keep_events {
            let event = back.borrow().view(combat.geometry.as_ref().unwrap());
            event.insert("type", "return".into());
            event.insert("from_uid", unit.borrow().uid.into());
            event.insert("mechanic", mechanic_id.into());
            event.insert("source_uid", unit.borrow().uid.into());
            combat._log(&event);
        }
        for later in after.to_vec() {
            combat._release(&later);
        }
        Some(back)
    }
    pub fn finish(&mut self, combat: &mut Combat) -> Dictionary {
        let alive = [!combat._board_empty(0), !combat._board_empty(1)];
        let mut winner = -1_i64;
        if combat._halt_reason == Combat::REASON_BOARD_EMPTY && alive[0] != alive[1] {
            winner = if alive[0] { 0 } else { 1 };
        }
        let mut killed = [0_i64; 2];
        let mut starting = [0_i64; 2];
        let kept = Array::from(vec![Array::new(), Array::new()]);
        for side in 0..2 {
            let survivors: Array<i64> = combat
                ._board(side as i64)
                .to_vec()
                .into_iter()
                .filter(|u| u.borrow().starting)
                .map(|u| u.borrow().recruit_uid)
                .collect();
            let started = combat._starting_uids.get(side).unwrap();
            starting[side] = started.len() as i64;
            kept.borrow_mut()[side] = Self::_unique(&survivors);
            killed[side] = (started.len() as i64 - Self::_unique(&survivors).len() as i64).max(0);
        }
        let survivors = Array::from(vec![self.uids(combat, 0), self.uids(combat, 1)]);
        let deaths = [
            combat.bridge(0).borrow().deaths,
            combat.bridge(1).borrow().deaths,
        ];
        combat.result=crate::state_dict!{"winner"=>&winner,"reason"=>&combat._halt_reason,"starting"=>&starting,"killed"=>&killed,"attacks"=>&combat._attacks,"triggers"=>&combat._triggers,"survivors"=>&survivors,"survivor_recruit_uids"=>&kept,"deaths"=>&deaths,"outnumbered_by"=>&[combat.outnumbered_by(0),combat.outnumbered_by(1)]}.as_dict();
        if combat.keep_events {
            let end = combat.result.duplicate();
            end.insert("type", "combat_end".into());
            combat._log(&end);
        }
        combat.result.clone()
    }
    pub fn _unique(values: &Array<i64>) -> Array<i64> {
        let out = Array::new();
        for value in values.to_vec() {
            if !out.has(&value) {
                out.push(value);
            }
        }
        out
    }
    pub fn uids(&self, combat: &mut Combat, side_index: i64) -> Array<i64> {
        combat
            ._board(side_index)
            .to_vec()
            .into_iter()
            .map(|u| u.borrow().uid)
            .collect()
    }
    pub fn board_view(&self, combat: &mut Combat, side_index: i64) -> Array<Variant> {
        combat
            ._board(side_index)
            .to_vec()
            .into_iter()
            .map(|u| Variant::Dictionary(u.borrow().view(combat.geometry.as_ref().unwrap())))
            .collect()
    }
    pub fn slots_view(&self, combat: &mut Combat, side_index: i64) -> Array<Variant> {
        let out = Array::new();
        let count = combat.geometry.as_ref().unwrap().borrow().slot_count;
        for slot in 0..count {
            let side = combat.bridge(side_index);
            out.push(Variant::Dictionary(FightSide::slot_view(
                &side, combat, slot,
            )));
        }
        out
    }
    pub fn new() -> Self {
        Self::default()
    }
}
