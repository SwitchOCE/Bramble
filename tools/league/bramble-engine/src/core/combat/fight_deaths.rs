#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/fight_deaths.gd`; gameplay TODO bodies belong to the later port workers.
use std::{cell::RefCell, rc::{Rc, Weak}};
use crate::{Array, Dictionary, ToState, Variant};

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::{CombatUnitRef};

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
        Self {
            _combat_ref: None,
        }
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
        Rc::new(RefCell::new(Self { _combat_ref:Some(Rc::downgrade(combat)), ..Self::default() }))
    }
    pub fn _combat(&self) -> Option<CombatRef> {
        self._combat_ref.as_ref().and_then(Weak::upgrade)
    }
    pub fn resolve(&mut self, combat: &mut Combat, active_side: i64) {
        todo!("port src/core/combat/fight_deaths.gd:resolve")
    }
    pub fn _death_steps(&mut self, combat: &mut Combat, dying: &Array<CombatUnitRef>, active_side: i64) {
        todo!("port src/core/combat/fight_deaths.gd:_death_steps")
    }
    pub fn _try_return(&mut self, combat: &mut Combat, unit: Option<&CombatUnitRef>) -> Option<CombatUnitRef> {
        todo!("port src/core/combat/fight_deaths.gd:_try_return")
    }
    pub fn finish(&mut self, combat: &mut Combat) -> Dictionary {
        todo!("port src/core/combat/fight_deaths.gd:finish")
    }
    pub fn _unique(values: &Array<i64>) -> Array<i64> {
        todo!("port src/core/combat/fight_deaths.gd:_unique")
    }
    pub fn uids(&self, combat: &mut Combat, side_index: i64) -> Array<i64> {
        todo!("port src/core/combat/fight_deaths.gd:uids")
    }
    pub fn board_view(&self, combat: &mut Combat, side_index: i64) -> Array<Variant> {
        todo!("port src/core/combat/fight_deaths.gd:board_view")
    }
    pub fn slots_view(&self, combat: &mut Combat, side_index: i64) -> Array<Variant> {
        todo!("port src/core/combat/fight_deaths.gd:slots_view")
    }
    pub fn new() -> Self { Self::default() }
}
