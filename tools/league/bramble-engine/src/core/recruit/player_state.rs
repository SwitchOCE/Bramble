//! Port of `src/core/recruit/player_state.gd`.
#![allow(unused_variables)]
use crate::core::mechanics::bound_mechanic::BoundMechanicRef;
use crate::core::state::{
    card_heap::{CardHeap, CardHeapRef},
    fight_report::FightReportRef,
    slot_state::{SlotState, SlotStateRef},
};
use crate::core::units::unit::UnitRef;
use crate::core::util::core_util::CoreUtil;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};

pub type PlayerStateRef = Rc<RefCell<PlayerState>>;
#[derive(Clone)]
pub struct PlayerState {
    pub id: i64,
    pub health: i64,
    pub armor: i64,
    pub gold: i64,
    // Gold earned in a fight, added at the start of the next turn (3.2.1 with the income).
    pub gold_next_turn: i64,
    // The last fight's report, used once when this player next recruits.
    pub last_fight_report: Option<FightReportRef>,
    pub tier: i64,
    // 4.6.3 turns waited on the current tier since the last upgrade (the discount's age).
    pub turns_waited: i64,
    // 4.4.4 paid refreshes this turn.
    pub refreshes_paid: i64,
    // 4.5.1 freeze toggles this turn.
    pub freezes_used: i64,
    pub frozen: bool,
    // 6.1.1 the shop's unit and spell slots: card ids, NO_CARD for an empty slot (4.2.3).
    pub shop_units: Array<String>,
    pub shop_spells: Array<String>,
    // 7.1 cards in hand, in the order gained.
    pub hand: Array<UnitRef>,
    /// Gained units waiting for their recruit target, in gain order.
    pub recruit_choices: Array<UnitRef>,
    // 8.1 the recruit board: one entry per slot, null for an empty slot.
    pub board: Array<Option<UnitRef>>,
    // 6.2 Discover options being shown. Empty when none is pending.
    pub discover_options: Array<String>,
    // Waiting Discovers, oldest first. Options are drawn when shown.
    pub discover_queue: Array<(i64, i64)>,
    // 12.1.1 "this game": lasting player-level numbers mechanics keep (a tribe-wide bonus).
    pub counters: Dictionary,
    pub heaps: Dictionary<CardHeapRef>,
    // 8.5 one SlotState per board slot.
    pub slots: Array<SlotStateRef>,
    pub standing: Array<BoundMechanicRef>,
    pub alive: bool,
    pub turn_ended: bool,
    // 2.3.2 the opponent faced in each past round, latest last (-1 = the ghost).
    pub opponents: Array<i64>,
    pub eliminated_round: i64,
    // 1.1.3 final place, 0 while still playing.
    pub placement: i64,
}
impl Default for PlayerState {
    fn default() -> Self {
        Self {
            id: 0,
            health: 40,
            armor: 0,
            gold: 0,
            gold_next_turn: 0,
            last_fight_report: None,
            tier: 1,
            turns_waited: 0,
            refreshes_paid: 0,
            freezes_used: 0,
            frozen: false,
            shop_units: Array::new(),
            shop_spells: Array::new(),
            hand: Array::new(),
            recruit_choices: Array::new(),
            board: Array::new(),
            discover_options: Array::new(),
            discover_queue: Array::new(),
            counters: Dictionary::new(),
            heaps: Dictionary::new(),
            slots: Array::new(),
            standing: Array::new(),
            alive: true,
            turn_ended: false,
            opponents: Array::new(),
            eliminated_round: 0,
            placement: 0,
        }
    }
}
impl PlayerState {
    pub const NO_CARD: &'static str = "";
    pub fn new() -> Self {
        Self::default()
    }
    pub fn create(
        player_id: i64,
        slot_count: i64,
        starting_health: i64,
        start_armor: i64,
    ) -> PlayerStateRef {
        let player = Self {
            id: player_id,
            health: starting_health,
            armor: start_armor,
            ..Self::default()
        };
        player.board.borrow_mut().resize(slot_count as usize, None);
        for _i in 0..slot_count {
            player
                .slots
                .borrow_mut()
                .push(Rc::new(RefCell::new(SlotState::default())));
        }
        Rc::new(RefCell::new(player))
    }
    pub fn counter(&self, key: &str) -> i64 {
        self.counters
            .borrow()
            .get(key)
            .map(CoreUtil::to_int)
            .unwrap_or(0)
    }
    pub fn heap(&mut self, heap_name: &str) -> CardHeapRef {
        self.heaps
            .borrow_mut()
            .entry(heap_name.to_owned())
            .or_insert_with(|| Rc::new(RefCell::new(CardHeap::new())))
            .clone()
    }
    pub fn has_standing(&self, mechanic_id: &str) -> bool {
        self.standing
            .borrow()
            .iter()
            .any(|bound| bound.borrow().id == mechanic_id)
    }
    pub fn board_units(&self) -> Array<UnitRef> {
        Array::from(
            self.board
                .borrow()
                .iter()
                .filter_map(Clone::clone)
                .collect::<Vec<_>>(),
        )
    }
    pub fn board_count(&self) -> i64 {
        self.board_units().borrow().len() as i64
    }
    pub fn empty_slots(&self) -> Array<i64> {
        Array::from(
            self.board
                .borrow()
                .iter()
                .enumerate()
                .filter_map(|(index, unit)| unit.is_none().then_some(index as i64))
                .collect::<Vec<_>>(),
        )
    }
    pub fn occupied(&self) -> Array<bool> {
        Array::from(
            self.board
                .borrow()
                .iter()
                .map(Option::is_some)
                .collect::<Vec<_>>(),
        )
    }
    pub fn place(&mut self, unit: &UnitRef, slot: i64) {
        self.board.borrow_mut()[slot as usize] = Some(unit.clone());
        unit.borrow_mut().slot = slot;
    }
    pub fn remove_from_board(&mut self, unit: &UnitRef) {
        let slot = unit.borrow().slot;
        if slot >= 0
            && self.board.borrow()[slot as usize]
                .as_ref()
                .is_some_and(|found| Rc::ptr_eq(found, unit))
        {
            self.board.borrow_mut()[slot as usize] = None;
        }
        unit.borrow_mut().slot = -1;
    }
    // A sold source can still have a last slot, so check actual board membership.
    pub fn mark_worked(&self, unit: Option<&UnitRef>) {
        let Some(unit) = unit else { return };
        let slot = unit.borrow().slot;
        if slot >= 0
            && self
                .board
                .get(slot as usize)
                .flatten()
                .is_some_and(|here| Rc::ptr_eq(&here, unit))
        {
            unit.borrow_mut().worked_this_turn = true;
        }
    }

    pub fn find_uid(&self, uid: i64) -> Option<UnitRef> {
        for unit in self.hand.borrow().iter() {
            if unit.borrow().uid == uid {
                return Some(unit.clone());
            }
        }
        for unit in self.board.borrow().iter().flatten() {
            if unit.borrow().uid == uid {
                return Some(unit.clone());
            }
        }
        None
    }
    pub fn all_cards(&self) -> Array<UnitRef> {
        let out = self.board_units();
        out.borrow_mut().extend(self.hand.borrow().iter().cloned());
        out
    }
    pub fn view(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("id", self.id.to_state());
        out.insert("health", self.health.to_state());
        out.insert("armor", self.armor.to_state());
        out.insert("gold", self.gold.to_state());
        out.insert("tier", self.tier.to_state());
        out.insert("alive", self.alive.to_state());
        out.insert("frozen", self.frozen.to_state());
        out.insert("shop_units", self.shop_units.to_state());
        out.insert("shop_spells", self.shop_spells.to_state());
        out.insert(
            "hand",
            Variant::array(
                self.hand
                    .borrow()
                    .iter()
                    .map(|u| u.borrow().view().to_state())
                    .collect(),
            ),
        );
        out.insert(
            "board",
            Variant::array(
                self.board
                    .borrow()
                    .iter()
                    .map(|u| Self::_slot_view(u.as_ref()))
                    .collect(),
            ),
        );
        out.insert("discover", self.discover_options.to_state());
        out.insert(
            "discovers_waiting",
            (self.discover_queue.len() as i64).to_state(),
        );
        out.insert(
            "counters",
            crate::core::units::unit_text::UnitText::counters_view(&self.counters).to_state(),
        );
        out.insert(
            "recruit_choices",
            Variant::array(
                self.recruit_choices
                    .iter_live()
                    .map(|u| u.borrow().uid.into())
                    .collect(),
            ),
        );
        out.insert("heaps", self._heaps_view().to_state());
        out.insert(
            "slots",
            Variant::array(
                self.slots
                    .borrow()
                    .iter()
                    .map(|s| s.borrow().view().to_state())
                    .collect(),
            ),
        );
        out.insert(
            "standing",
            Variant::array(
                self.standing
                    .borrow()
                    .iter()
                    .map(|b| b.borrow().id.to_state())
                    .collect(),
            ),
        );
        out.insert("placement", self.placement.to_state());
        out
    }
    pub fn _heaps_view(&self) -> Dictionary {
        let out = Dictionary::new();
        for (key, heap_found) in self.heaps.borrow().iter() {
            out.insert(key, heap_found.borrow().view().to_state());
        }
        out
    }
    pub fn _slot_view(unit: Option<&UnitRef>) -> Variant {
        match unit {
            None => Variant::Nil,
            Some(unit) => unit.borrow().view().to_state(),
        }
    }
}
impl ToState for PlayerState {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "id"=> &self.id, "health"=> &self.health, "armor"=> &self.armor,
            "gold"=> &self.gold, "gold_next_turn"=> &self.gold_next_turn, "last_fight_report"=> &self.last_fight_report, "tier"=> &self.tier,
            "turns_waited"=> &self.turns_waited, "refreshes_paid"=> &self.refreshes_paid,
            "freezes_used"=> &self.freezes_used, "frozen"=> &self.frozen,
            "shop_units"=> &self.shop_units, "shop_spells"=> &self.shop_spells,
            "hand"=> &self.hand, "recruit_choices"=> &self.recruit_choices, "board"=> &self.board, "discover_options"=> &self.discover_options,
            "discover_queue"=> &self.discover_queue, "counters"=> &self.counters, "heaps"=> &self.heaps,
            "slots"=> &self.slots, "standing"=> &self.standing, "alive"=> &self.alive,
            "turn_ended"=> &self.turn_ended, "opponents"=> &self.opponents,
            "eliminated_round"=> &self.eliminated_round, "placement"=> &self.placement,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "id",
            "health",
            "armor",
            "gold",
            "gold_next_turn",
            "last_fight_report",
            "tier",
            "turns_waited",
            "refreshes_paid",
            "freezes_used",
            "frozen",
            "shop_units",
            "shop_spells",
            "hand",
            "recruit_choices",
            "board",
            "discover_options",
            "discover_queue",
            "counters",
            "heaps",
            "slots",
            "standing",
            "alive",
            "turn_ended",
            "opponents",
            "eliminated_round",
            "placement",
        ]
    }
}

// Rule comments retained for the pending bodies:
// at the default (2.2.5) and armor at 0 (2.2.6).
