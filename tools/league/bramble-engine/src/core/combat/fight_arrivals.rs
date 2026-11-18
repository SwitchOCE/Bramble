#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/fight_arrivals.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::board::board_geometry::BoardGeometryRef;

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::{CombatUnit, CombatUnitRef};
use crate::core::mechanics::mechanic::{self, Hook, HookArgs};

use crate::core::units::unit::UnitRef;

// GDScript rule and contract comments:
// Who fills a slot that empties in a fight, in one place (SHARED-RULES slot-fill order). After a
// round of deaths: first each dying unit's own summons and returns (Combat's death steps 2 and
// 4), then Reserve units step into the slots friends died in (the side's fill-first slot, such
// as a Guard post, then reading order), then waiting summons in one line (Hoppers, Compost
// copies) into empty slots in reading order, then the after_death_round hook (a Recruiting
// Sergeant's Private). SHARED-RULES ruling 6.
// Per side: CombatUnits from the hand waiting to step in (Reserve), in hand order.
// Per side: waiting summons, {"id", "source", "payload"}, in landing order.
// Copies each side's hand units that have Reserve (Q_RESERVE), or every hand unit when the
// side says so (Q_HAND_RESERVE), with their buffs, as waiting units. Spells stay behind.
// The reserve as the fight log shows it at the start: [[unit view], [unit view]].
// Queues a summon that found no room; it keeps its source and payload.
// The slot-fill order after one round of deaths. `emptied` [[slot], [slot]]: slots units died
// in this round. Active side first.
pub type FightArrivalsRef = Rc<RefCell<FightArrivals>>;
pub struct FightArrivals {
    pub reserve: Array<Array<CombatUnitRef>>,
    pub waiting: Array<Array<WaitingSummon>>,
    pub _combat_ref: Option<Weak<RefCell<Combat>>>,
}
impl Default for FightArrivals {
    fn default() -> Self {
        Self {
            reserve: Array::from(vec![Array::new(), Array::new()]),
            waiting: Array::from(vec![Array::new(), Array::new()]),
            _combat_ref: None,
        }
    }
}
impl ToState for FightArrivals {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "reserve" => &self.reserve,
            "waiting" => &self.waiting,
            "_combat_ref" => &if self._combat_ref.is_some() { Variant::dictionary(Default::default()) } else { Variant::Nil },
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["reserve", "waiting", "_combat_ref"]
    }
}
impl FightArrivals {
    pub fn create(combat: &CombatRef) -> FightArrivalsRef {
        Rc::new(RefCell::new(Self {
            _combat_ref: Some(Rc::downgrade(combat)),
            ..Self::default()
        }))
    }
    pub fn _combat(&self) -> Option<CombatRef> {
        self._combat_ref.as_ref().and_then(Weak::upgrade)
    }
    pub fn take_reserve(&mut self, combat: &mut Combat, hands: &Array<Array<UnitRef>>) {
        for side in 0..2.min(hands.len()) {
            let everyone = combat.side_query(side as i64, mechanic::Q_HAND_RESERVE, 0) != 0;
            let queue = self.reserve.get(side).unwrap();
            let hand = hands.get(side).unwrap();
            let mut i = 0;
            while let Some(card) = hand.get(i) {
                i += 1;
                if card.borrow().is_spell() {
                    continue;
                }
                let copy = CombatUnit::from_unit(&card, combat._take_uid(), side as i64);
                copy.borrow_mut().slot = -1;
                copy.borrow_mut().starting = false;
                if everyone || CombatUnit::query(&copy, mechanic::Q_RESERVE, 0) != 0 {
                    queue.push(copy);
                }
            }
        }
    }
    pub fn reserve_view(&self, combat: &mut Combat, geometry: &BoardGeometryRef) -> Array<Variant> {
        (0..2)
            .map(|side| {
                Variant::Array(
                    self.reserve
                        .get(side)
                        .unwrap()
                        .to_vec()
                        .into_iter()
                        .map(|u| Variant::Dictionary(u.borrow().view(geometry)))
                        .collect(),
                )
            })
            .collect()
    }
    pub fn wait(
        &mut self,
        combat: &mut Combat,
        side_index: i64,
        card_id: &str,
        source: Option<&CombatUnitRef>,
        payload: &Dictionary,
        golden: bool,
    ) {
        self.waiting
            .get(side_index as usize)
            .unwrap()
            .push(WaitingSummon {
                id: card_id.into(),
                source: source.cloned(),
                payload: payload.clone(),
                golden,
            });
    }
    pub fn after_deaths(
        &mut self,
        combat: &mut Combat,
        emptied: &Array<Array<i64>>,
        active_side: i64,
    ) {
        for side in [active_side, 1 - active_side] {
            self._step_in(combat, side, &emptied.get(side as usize).unwrap());
        }
        for side in [active_side, 1 - active_side] {
            self._land(combat, side);
        }
        for side in [active_side, 1 - active_side] {
            combat._notify(side, Hook::AfterDeathRound, &HookArgs::None);
        }
    }
    pub fn _step_in(&mut self, combat: &mut Combat, side_index: i64, died_in: &Array<i64>) {
        let queue = self.reserve.get(side_index as usize).unwrap();
        if queue.is_empty() {
            return;
        }
        let mut open = Vec::new();
        for slot in died_in.to_vec() {
            if combat.unit_at(side_index, slot).is_none() && !open.contains(&slot) {
                open.push(slot);
            }
        }
        crate::util::godot_sort::sort(&mut open);
        let first = combat.side_query(side_index, mechanic::Q_FILL_FIRST, -1);
        if let Some(i) = open.iter().position(|s| *s == first) {
            open.remove(i);
            open.insert(0, first);
        }
        for slot in open {
            if queue.is_empty() || combat.halted() {
                return;
            }
            let unit = queue.borrow_mut().remove(0);
            combat._enter(Some(&unit), slot, None, "reserve", &Dictionary::new());
        }
    }
    pub fn _land(&mut self, combat: &mut Combat, side_index: i64) {
        let queue = self.waiting.get(side_index as usize).unwrap();
        while !queue.is_empty() && !combat.halted() {
            let occupied = combat._occupied(side_index);
            let slot = combat
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .summon_slot(&occupied, -1, false);
            if slot < 0 {
                return;
            }
            let entry = queue.borrow_mut().remove(0);
            let card = combat
                .library
                .as_ref()
                .unwrap()
                .borrow()
                .get_card(&entry.id)
                .unwrap();
            let new_uid = combat._take_uid();
            let unit = CombatUnit::fresh(
                &card,
                new_uid,
                side_index,
                entry.golden,
                combat.registry.as_ref().unwrap(),
                combat.config.as_ref().unwrap().borrow().stat_max,
            );
            for (k, v) in entry.payload.borrow().iter() {
                unit.borrow().state.insert(k, v.clone());
            }
            combat._enter(
                Some(&unit),
                slot,
                entry.source.as_ref(),
                "summon",
                &crate::state_dict! {"waited"=>&true,"payload"=>&entry.payload}.as_dict(),
            );
        }
    }
    pub fn new() -> Self {
        Self::default()
    }
}
#[derive(Clone)]
pub struct WaitingSummon {
    pub id: String,
    pub source: Option<CombatUnitRef>,
    pub payload: Dictionary,
    pub golden: bool,
}
impl ToState for WaitingSummon {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "id"=>&self.id, "source"=>&self.source, "payload"=>&self.payload, "golden"=>&self.golden }
    }
}
