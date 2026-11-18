#![allow(unused_imports, unused_variables)]
//! Port of `src/core/combat/fight_side.gd`.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::mechanics::bound_mechanic::BoundMechanicRef;
use crate::core::mechanics::mechanic_spec::MechanicSpec;
use crate::core::state::card_heap::{CardHeap, CardHeapRef};

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::CombatUnitRef;

use crate::core::recruit::player_state::PlayerStateRef;

use crate::core::combat::fight_auras::FightAuras;
use crate::core::state::slot_state::{SlotState, SlotStateRef};

use crate::core::units::unit::UnitRef;

// GDScript rule and contract comments:
// A fight hook may use any of these, so the fight API is one class on purpose.
// One side of a fight and its bridge to the player (12.1.1, 9.1.1's exception). Mechanics reach
// it with combat.bridge(n). It holds the player's lasting numbers and heaps (the real ones when the
// side writes back, copies for the ghost or a bare test fight), the slot effects copied into the
// fight (8.5.2), and this fight's per-side numbers. "Permanently" changes also go to the real
// unit, slot or player when the side writes back; otherwise they last this fight only.
// The player, or null for a bare fight (tests).
// True when permanent changes reach the player (a live player; not the ghost).
// Units of this side that died this fight (9.7), tokens included.
// Numbers a mechanic keeps for this side for this fight only.
// Heap name -> the `n` of each entry marked used for this fight (heap_use); the heap itself
// doesn't change.
// The percent of their Attack buff this side's slots give for the rest of the fight (base 100;
// the Edgewright sets 200). Kept if the unit that set it dies (set_slot_attack_percent).
// The recruit unit (board or hand) a fight unit copies, to read; null for one made in the
// fight. A ghost or saved board has one too; use real_unit to change it.
// The recruit-board unit a fight unit copies, when this side writes back; else null.
// A player-level number ("this game", 12.1.1). Lasts the game when this side writes back.
// A number on a unit. `permanent` writes it to the recruit unit too (Unit.counters).
// The named heap, made empty on first use (the player's own when this side writes back).
// Spends the `count` lowest entries (CardHeap.spend_lowest). False, and nothing spent, if the
// heap has fewer.
// Marks the `count` highest-tier entries not yet used this fight (newest first on a tie) used
// for this fight; they stay in the heap. False, and nothing marked, if fewer are unused. The
// `heap_use` event names each entry (`ids`, `entries` by `n`) so a screen shows which.
// "Copy the highest-tier unit in your Compost" (Old Stump, Elder Mother): marks the highest-tier
// entry not yet used this fight and returns it ({"id", "tier", "n"}), or {} with nothing marked
// when none is left. Right when the heap changes mid-fight: marks name entries, not a count.
// Entries still in the heap and not yet marked used this fight.
// Takes the highest entry (CardHeap.take_highest); &"" when empty.
// "Your slots give double Attack this fight" (SHARED-RULES 13): the side's slots give `percent`
// of their stored Attack buff for the rest of the fight, even if `source` dies. Two don't stack:
// the bigger applies. Logged as `slot_percent`; every unit whose Attack changes gets `stats`.
// The Attack the slot gives this fight: its stored buff at the fight's percent (what a unit
// there gets, and what anything that reads a slot's Attack buff should read).
// A slot as a screen shows it in a fight: the stored buff and keywords, plus `given_attack`
// (what it gives at this fight's percent) and the `percent`.
// 8.5 a slot buff, and optionally a keyword the slot gives. This fight only, unless
// `permanent` and this side writes back (8.5.2).
// Sets a slot's buff to these values, unscaled (a copy is not a buff given: Colour Ensign,
// SHARED-RULES 12). This fight only, unless `permanent` and this side writes back.
// Clears a keyword from a slot (moving a Guard post): this fight, or for good.
// 11.1.1 a unit gains a keyword (a mechanic with no parameters): this fight, or for good.
// A unit gains a mechanic with parameters ("+2 Fury" onto a unit with none: Sett Sexton,
// Sword-heir): this fight, or also on the recruit unit when `permanent` and this side writes
// back. `raw` holds its parameters as card data does; the numbers are the giver's, never doubled
// by a golden target. Its on_combat_begin runs; logged as `effect`. False when unknown or bad.
// Gold earned in the fight, paid at the start of the next turn; nothing for a copy side.
// Heap name -> its size, for the fight log.
pub type FightSideRef = Rc<RefCell<FightSide>>;
pub struct FightSide {
    pub index: i64,
    pub player: Option<PlayerStateRef>,
    pub writes_back: bool,
    pub counters: Dictionary,
    pub heaps: Dictionary<CardHeapRef>,
    pub slots: Array<SlotStateRef>,
    pub standing: Array<BoundMechanicRef>,
    pub deaths: i64,
    pub state: Dictionary,
    pub used: Dictionary<Array<i64>>,
    pub slot_attack_percent: i64,
    pub _combat_ref: Option<Weak<RefCell<Combat>>>,
}
impl Default for FightSide {
    fn default() -> Self {
        Self {
            index: 0,
            player: None,
            writes_back: false,
            counters: Default::default(),
            heaps: Default::default(),
            slots: Array::new(),
            standing: Array::new(),
            deaths: 0,
            state: Default::default(),
            used: Default::default(),
            slot_attack_percent: 100,
            _combat_ref: None,
        }
    }
}
impl ToState for FightSide {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "index" => &self.index,
            "player" => &self.player,
            "writes_back" => &self.writes_back,
            "counters" => &self.counters,
            "heaps" => &self.heaps,
            "slots" => &self.slots,
            "standing" => &self.standing,
            "deaths" => &self.deaths,
            "state" => &self.state,
            "used" => &self.used,
            "slot_attack_percent" => &self.slot_attack_percent,
            "_combat_ref" => &if self._combat_ref.is_some() { Variant::dictionary(Default::default()) } else { Variant::Nil },
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "index",
            "player",
            "writes_back",
            "counters",
            "heaps",
            "slots",
            "standing",
            "deaths",
            "state",
            "used",
            "slot_attack_percent",
            "_combat_ref",
        ]
    }
}
impl FightSide {
    pub fn create(
        combat: &CombatRef,
        side: i64,
        owner: Option<&PlayerStateRef>,
        live: bool,
        slot_count: i64,
    ) -> FightSideRef {
        let mut made = Self {
            _combat_ref: Some(Rc::downgrade(combat)),
            index: side,
            player: owner.cloned(),
            writes_back: owner.is_some() && live,
            ..Self::default()
        };
        if let Some(owner) = owner {
            made.standing = owner.borrow().standing.clone();
            made.counters = if made.writes_back {
                owner.borrow().counters.clone()
            } else {
                owner.borrow().counters.duplicate()
            };
            if made.writes_back {
                made.heaps = owner.borrow().heaps.clone();
            } else {
                let heaps = owner.borrow().heaps.clone();
                let mut i = 0;
                while i < heaps.len() {
                    let (key, heap_found) = heaps
                        .borrow()
                        .get_index(i)
                        .map(|(key, heap)| (key.clone(), heap.clone()))
                        .expect("owner heap");
                    made.heaps
                        .borrow_mut()
                        .insert(key, heap_found.borrow().duplicate_heap());
                    i += 1;
                }
            }
            let slots = owner.borrow().slots.clone();
            let mut i = 0;
            while i < slots.len() {
                let each_slot = slots.get(i).expect("owner slot");
                made.slots.push(each_slot.borrow().duplicate_slot());
                i += 1;
            }
        }
        while (made.slots.len() as i64) < slot_count {
            made.slots.push(Rc::new(RefCell::new(SlotState::new())));
        }
        Rc::new(RefCell::new(made))
    }
    pub fn _combat(&self) -> Option<CombatRef> {
        self._combat_ref.as_ref().and_then(Weak::upgrade)
    }
    pub fn recruit_unit(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
    ) -> Option<UnitRef> {
        let player = self.player.as_ref()?;
        let unit = unit?;
        let recruit_uid = unit.borrow().recruit_uid;
        if recruit_uid < 0 {
            return None;
        }
        player.borrow().find_uid(recruit_uid)
    }
    pub fn real_unit(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>) -> Option<UnitRef> {
        if !self.writes_back {
            return None;
        }
        let unit = unit?;
        let recruit_uid = unit.borrow().recruit_uid;
        if recruit_uid < 0 {
            return None;
        }
        self.player
            .as_ref()
            .expect("live player")
            .borrow()
            .find_uid(recruit_uid)
    }
    pub fn counter(&self, combat: &mut Combat, key: &str) -> i64 {
        self.counters.get(key).as_i64()
    }
    pub fn add_counter(
        side: &FightSideRef,
        combat: &mut Combat,
        key: &str,
        amount: i64,
        source: Option<&CombatUnitRef>,
    ) {
        combat
            .registry
            .as_ref()
            .expect("combat registry")
            .borrow_mut()
            .check_name(key, "player counter");
        let value = side.borrow().counter(combat, key).wrapping_add(amount);
        side.borrow().counters.insert(key, Variant::Int(value));
        if combat.keep_events {
            let event =
                crate::state_dict! { "type" => "player_counter", "key" => key, "value" => &value }
                    .as_dict();
            combat.log_side(side, &event, source);
        }
        combat._refresh_auras();
    }
    pub fn add_unit_counter(
        side: &FightSideRef,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        key: &str,
        amount: i64,
        permanent: bool,
        source: Option<&CombatUnitRef>,
    ) {
        combat
            .registry
            .as_ref()
            .expect("combat registry")
            .borrow_mut()
            .check_name(key, "unit counter");
        let unit = unit.expect("counter unit");
        let value = unit.borrow().counter(key).wrapping_add(amount);
        unit.borrow().counters.insert(key, Variant::Int(value));
        let real = if permanent {
            side.borrow().real_unit(combat, Some(unit))
        } else {
            None
        };
        if let Some(real) = &real {
            let value = real.borrow().counter(key).wrapping_add(amount);
            real.borrow().counters.insert(key, Variant::Int(value));
        }
        let (slot, uid, value) = {
            let unit = unit.borrow();
            (unit.slot, unit.uid, unit.counter(key))
        };
        if combat.keep_events {
            let event = crate::state_dict! {
                "type" => "counter", "slot" => &slot, "uid" => &uid, "key" => key,
                "value" => &value, "permanent" => &real.is_some(),
            }
            .as_dict();
            combat.log_side(side, &event, source);
        }
    }
    pub fn heap(&mut self, combat: &mut Combat, heap_name: &str) -> CardHeapRef {
        if !self.heaps.borrow().contains_key(heap_name) {
            combat
                .registry
                .as_ref()
                .expect("combat registry")
                .borrow_mut()
                .check_name(heap_name, "heap");
            self.heaps
                .borrow_mut()
                .insert(heap_name.to_owned(), Rc::new(RefCell::new(CardHeap::new())));
        }
        self.heaps
            .borrow()
            .get(heap_name)
            .cloned()
            .expect("named heap")
    }
    pub fn heap_add(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        card_id: &str,
        tier: i64,
        source: Option<&CombatUnitRef>,
    ) {
        let heap = side.borrow_mut().heap(combat, heap_name);
        heap.borrow_mut().add(card_id, tier);
        let size = side.borrow_mut().heap(combat, heap_name).borrow().size();
        if combat.keep_events {
            let event = crate::state_dict! { "type" => "heap_add", "heap" => heap_name, "id" => card_id, "size" => &size }.as_dict();
            combat.log_side(side, &event, source);
        }
        let index = side.borrow().index;
        combat._notify_heap_added(index, heap_name, card_id);
        combat._refresh_auras();
    }
    pub fn heap_spend(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        count: i64,
        source: Option<&CombatUnitRef>,
    ) -> bool {
        let heap = side.borrow_mut().heap(combat, heap_name);
        let spent = heap.borrow_mut().spend_lowest(count);
        if spent.is_empty() {
            return false;
        }
        Self::_heap_removed(side, combat, heap_name, &spent, source);
        true
    }
    pub fn heap_use(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        count: i64,
        source: Option<&CombatUnitRef>,
    ) -> bool {
        if side.borrow_mut().heap_unused(combat, heap_name) < count || count <= 0 {
            return false;
        }
        let marked = Array::new();
        for _ in 0..count {
            marked.push(side.borrow_mut()._mark(combat, heap_name));
        }
        Self::_log_use(side, combat, heap_name, &marked, source);
        true
    }
    pub fn heap_use_highest(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        source: Option<&CombatUnitRef>,
    ) -> Dictionary {
        if side.borrow_mut().heap_unused(combat, heap_name) <= 0 {
            return Dictionary::new();
        }
        let entry = side.borrow_mut()._mark(combat, heap_name);
        Self::_log_use(
            side,
            combat,
            heap_name,
            &Array::from([entry.clone()]),
            source,
        );
        entry
    }
    pub fn heap_unused(&mut self, combat: &mut Combat, heap_name: &str) -> i64 {
        let marks = self
            .used
            .borrow()
            .get(heap_name)
            .cloned()
            .unwrap_or_default();
        let mut count = 0;
        let entries = self.heap(combat, heap_name).borrow().entries.clone();
        let mut i = 0;
        while i < entries.len() {
            let entry = entries.get(i).expect("heap entry");
            if !marks.has(&entry.get("n").as_i64()) {
                count += 1;
            }
            i += 1;
        }
        count
    }
    pub fn _mark(&mut self, combat: &mut Combat, heap_name: &str) -> Dictionary {
        let marks = self
            .used
            .borrow()
            .get(heap_name)
            .cloned()
            .unwrap_or_default();
        let skip = marks.borrow().iter().copied().map(Variant::Int).collect();
        let entry = self.heap(combat, heap_name).borrow().highest_except(&skip);
        marks.push(entry.get("n").as_i64());
        self.used.borrow_mut().insert(heap_name.to_owned(), marks);
        entry
    }
    pub fn _log_use(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        marked: &Array<Dictionary>,
        source: Option<&CombatUnitRef>,
    ) {
        if !combat.keep_events {
            return;
        }
        let ids: Array<String> = marked
            .borrow()
            .iter()
            .map(|entry| entry.get("id").as_text())
            .collect();
        let entries: Array<i64> = marked
            .borrow()
            .iter()
            .map(|entry| entry.get("n").as_i64())
            .collect();
        let unused = side.borrow_mut().heap_unused(combat, heap_name);
        if combat.keep_events {
            let event = crate::state_dict! { "type" => "heap_use", "heap" => heap_name, "count" => &marked.len(), "ids" => &ids, "entries" => &entries, "unused" => &unused }.as_dict();
            combat.log_side(side, &event, source);
        }
    }
    pub fn heap_take(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        source: Option<&CombatUnitRef>,
    ) -> String {
        let heap = side.borrow_mut().heap(combat, heap_name);
        let card_id = heap.borrow_mut().take_highest();
        if !card_id.is_empty() {
            Self::_heap_removed(
                side,
                combat,
                heap_name,
                &Array::from([card_id.clone()]),
                source,
            );
        }
        card_id
    }
    pub fn _heap_removed(
        side: &FightSideRef,
        combat: &mut Combat,
        heap_name: &str,
        ids: &Array<String>,
        source: Option<&CombatUnitRef>,
    ) {
        let size = side.borrow_mut().heap(combat, heap_name).borrow().size();
        if combat.keep_events {
            let event = crate::state_dict! { "type" => "heap_remove", "heap" => heap_name, "ids" => ids, "size" => &size }.as_dict();
            combat.log_side(side, &event, source);
        }
        combat._refresh_auras();
    }
    pub fn slot(&mut self, combat: &mut Combat, slot_index: i64) -> SlotStateRef {
        self.slots.get(slot_index as usize).expect("fight slot")
    }
    pub fn set_slot_attack_percent(
        side: &FightSideRef,
        combat: &mut Combat,
        percent: i64,
        source: Option<&CombatUnitRef>,
    ) {
        if percent <= side.borrow().slot_attack_percent {
            return;
        }
        side.borrow_mut().slot_attack_percent = percent;
        if combat.keep_events {
            let event =
                crate::state_dict! { "type" => "slot_percent", "percent" => &percent }.as_dict();
            combat.log_side(side, &event, source);
        }
        combat._refresh_auras();
    }
    pub fn slot_attack_given(side: &FightSideRef, combat: &mut Combat, slot_index: i64) -> i64 {
        let attack = side
            .borrow()
            .slots
            .get(slot_index as usize)
            .expect("fight slot")
            .borrow()
            .attack;
        let index = side.borrow().index;
        let percent = FightAuras::slot_attack_percent(combat, index);
        (attack.wrapping_mul(percent) as f64 / 100.0) as i64
    }
    pub fn slot_view(side: &FightSideRef, combat: &mut Combat, slot_index: i64) -> Dictionary {
        let out = side
            .borrow()
            .slots
            .get(slot_index as usize)
            .expect("fight slot")
            .borrow()
            .view();
        out.insert(
            "given_attack",
            Variant::Int(Self::slot_attack_given(side, combat, slot_index)),
        );
        let index = side.borrow().index;
        out.insert(
            "percent",
            Variant::Int(FightAuras::slot_attack_percent(combat, index)),
        );
        out
    }
    pub fn slot_buff(
        side: &FightSideRef,
        combat: &mut Combat,
        slot_index: i64,
        attack: i64,
        health: i64,
        permanent: bool,
        source: Option<&CombatUnitRef>,
        keyword: &str,
    ) {
        let lasting = permanent && side.borrow().writes_back;
        let player = side.borrow().player.clone();
        let (mut attack, mut health) = (attack, health);
        if let Some(player) = &player {
            let percent = combat.rules_percent(player);
            attack = (attack.wrapping_mul(percent) as f64 / 100.0) as i64;
            health = (health.wrapping_mul(percent) as f64 / 100.0) as i64;
        }
        let targets = Array::from([side
            .borrow()
            .slots
            .get(slot_index as usize)
            .expect("fight slot")]);
        if lasting {
            targets.push(
                player
                    .as_ref()
                    .expect("live player")
                    .borrow()
                    .slots
                    .get(slot_index as usize)
                    .expect("player slot"),
            );
        }
        let mut i = 0;
        while i < targets.len() {
            let each_slot = targets.get(i).expect("buff slot");
            let mut each_slot = each_slot.borrow_mut();
            each_slot.attack = each_slot.attack.wrapping_add(attack);
            each_slot.health = each_slot.health.wrapping_add(health);
            if !keyword.is_empty() && !each_slot.keywords.has(&keyword.to_owned()) {
                each_slot.keywords.push(keyword.to_owned());
            }
            i += 1;
        }
        Self::_log_slot(side, combat, slot_index, attack, health, lasting, source);
    }
    pub fn slot_set(
        side: &FightSideRef,
        combat: &mut Combat,
        slot_index: i64,
        attack: i64,
        health: i64,
        permanent: bool,
        source: Option<&CombatUnitRef>,
    ) {
        let lasting = permanent && side.borrow().writes_back;
        let targets = Array::from([side
            .borrow()
            .slots
            .get(slot_index as usize)
            .expect("fight slot")]);
        if lasting {
            targets.push(
                side.borrow()
                    .player
                    .as_ref()
                    .expect("live player")
                    .borrow()
                    .slots
                    .get(slot_index as usize)
                    .expect("player slot"),
            );
        }
        let before = targets.get(targets.len() - 1).expect("last slot");
        let change = {
            let before = before.borrow();
            // Godot's Vector2i constructor narrows each component to a signed 32-bit integer.
            (
                attack.wrapping_sub(before.attack) as i32 as i64,
                health.wrapping_sub(before.health) as i32 as i64,
            )
        };
        let mut i = 0;
        while i < targets.len() {
            let each_slot = targets.get(i).expect("set slot");
            let mut each_slot = each_slot.borrow_mut();
            each_slot.attack = attack;
            each_slot.health = health;
            i += 1;
        }
        Self::_log_slot(
            side, combat, slot_index, change.0, change.1, lasting, source,
        );
    }
    pub fn slot_clear_keyword(
        side: &FightSideRef,
        combat: &mut Combat,
        slot_index: i64,
        keyword: &str,
        permanent: bool,
        source: Option<&CombatUnitRef>,
    ) {
        let lasting = permanent && side.borrow().writes_back;
        let targets = Array::from([side
            .borrow()
            .slots
            .get(slot_index as usize)
            .expect("fight slot")]);
        if lasting {
            targets.push(
                side.borrow()
                    .player
                    .as_ref()
                    .expect("live player")
                    .borrow()
                    .slots
                    .get(slot_index as usize)
                    .expect("player slot"),
            );
        }
        let mut i = 0;
        while i < targets.len() {
            let each_slot = targets.get(i).expect("keyword slot");
            let keywords = each_slot.borrow().keywords.clone();
            let index = keywords.borrow().iter().position(|found| found == keyword);
            if let Some(index) = index {
                keywords.borrow_mut().remove(index);
            }
            i += 1;
        }
        Self::_log_slot(side, combat, slot_index, 0, 0, lasting, source);
    }
    pub fn _log_slot(
        side: &FightSideRef,
        combat: &mut Combat,
        slot_index: i64,
        attack: i64,
        health: i64,
        lasting: bool,
        source: Option<&CombatUnitRef>,
    ) {
        if combat.keep_events {
            let total = Self::slot_view(side, combat, slot_index);
            let event = crate::state_dict! { "type" => "slot", "slot" => &slot_index, "attack" => &attack, "health" => &health, "total" => &total, "permanent" => &lasting }.as_dict();
            combat.log_side(side, &event, source);
        }
        combat._refresh_auras();
    }
    pub fn give_keyword(
        side: &FightSideRef,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        keyword: &str,
        permanent: bool,
        source: Option<&CombatUnitRef>,
    ) -> bool {
        let Some(unit) = unit else {
            return false;
        };
        let registry = combat.registry.clone().expect("combat registry");
        if unit.borrow().gone || !registry.borrow().has(keyword) {
            return false;
        }
        let mut lasting = false;
        if permanent {
            let real = side.borrow().real_unit(combat, Some(unit));
            if let Some(real) = real {
                lasting = real.borrow_mut().grant(&registry, keyword);
            }
        }
        let mechanics = unit.borrow().mechanics.clone();
        if mechanics
            .borrow()
            .iter()
            .any(|bound| bound.borrow().id == keyword)
        {
            return lasting;
        }
        let golden = unit.borrow().golden;
        let bound = registry
            .borrow()
            .bind(&MechanicSpec::new(keyword, None), golden, true);
        unit.borrow().mechanics.push(bound.clone());
        let (mechanic, params) = {
            let bound = bound.borrow();
            (
                bound.mechanic.clone().expect("keyword mechanic"),
                bound.params.clone(),
            )
        };
        mechanic.on_combat_begin(combat, Some(unit), &params);
        let (slot, uid) = {
            let unit = unit.borrow();
            (unit.slot, unit.uid)
        };
        if combat.keep_events {
            let event = crate::state_dict! { "type" => "keyword", "slot" => &slot, "uid" => &uid, "keyword" => keyword, "on" => &true }.as_dict();
            combat.log_side(side, &event, source);
        }
        true
    }
    pub fn give_effect(
        side: &FightSideRef,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        mechanic_id: &str,
        raw: &Dictionary,
        permanent: bool,
        source: Option<&CombatUnitRef>,
    ) -> bool {
        let Some(unit) = unit else {
            return false;
        };
        if unit.borrow().gone {
            return false;
        }
        let registry = combat.registry.clone().expect("combat registry");
        let Some(bound) = registry.borrow().bind_given(mechanic_id, raw) else {
            return false;
        };
        let real = if permanent {
            side.borrow().real_unit(combat, Some(unit))
        } else {
            None
        };
        if let Some(real) = &real {
            real.borrow_mut().grant_effect(&registry, mechanic_id, raw);
        }
        unit.borrow().mechanics.push(bound.clone());
        let (mechanic, params) = {
            let bound = bound.borrow();
            (
                bound.mechanic.clone().expect("given mechanic"),
                bound.params.clone(),
            )
        };
        mechanic.on_combat_begin(combat, Some(unit), &params);
        let (slot, uid) = {
            let unit = unit.borrow();
            (unit.slot, unit.uid)
        };
        if combat.keep_events {
            let event = crate::state_dict! { "type" => "effect", "slot" => &slot, "uid" => &uid, "mechanic" => mechanic_id, "params" => &raw.duplicate(), "permanent" => &real.is_some() }.as_dict();
            combat.log_side(side, &event, source);
        }
        combat._refresh_auras();
        true
    }
    pub fn add_gold(
        side: &FightSideRef,
        combat: &mut Combat,
        amount: i64,
        source: Option<&CombatUnitRef>,
    ) {
        if !side.borrow().writes_back {
            return;
        }
        let player = side.borrow().player.clone().expect("live player");
        {
            let mut player = player.borrow_mut();
            player.gold_next_turn = player.gold_next_turn.wrapping_add(amount);
        }
        if combat.keep_events {
            let event =
                crate::state_dict! { "type" => "gold", "amount" => &amount, "next_turn" => &true }
                    .as_dict();
            combat.log_side(side, &event, source);
        }
    }
    pub fn heap_sizes(&self, combat: &mut Combat) -> Dictionary {
        let out = Dictionary::new();
        let mut i = 0;
        while i < self.heaps.len() {
            let (key, found) = self
                .heaps
                .borrow()
                .get_index(i)
                .map(|(key, heap)| (key.clone(), heap.clone()))
                .expect("side heap");
            out.insert(key, Variant::Int(found.borrow().size()));
            i += 1;
        }
        out
    }
    pub fn state_int(&self, combat: &mut Combat, key: &str) -> i64 {
        self.state.get(key).as_i64()
    }
    pub fn set_state(&mut self, combat: &mut Combat, key: &str, value: i64) {
        combat
            .registry
            .as_ref()
            .expect("combat registry")
            .borrow_mut()
            .check_name(key, "side state");
        self.state.insert(key, Variant::Int(value));
    }
    pub fn new() -> Self {
        Self::default()
    }
}
