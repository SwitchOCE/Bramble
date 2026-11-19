#![allow(unused_imports, unused_variables)]
//! Port of `src/core/combat/fight_auras.gd`.
use crate::core::mechanics::mechanic::{
    AURA_GRANTS, AURA_KEYWORDS, AURA_STATS, Q_HAND_RENOWN_TIMES,
};
use crate::core::mechanics::mechanic_spec::MechanicSpec;
use crate::core::state::aura_context::{AuraContext, AuraContextRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::mechanics::bound_mechanic::BoundMechanicRef;

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::CombatUnitRef;

// GDScript rule and contract comments:
// 12.2.1 auras, standing auras, slot effects (8.5) and Renown in a fight, recalculated on both boards
// whenever a board, a player number or a heap changes (Combat.refresh). Each unit whose Attack,
// Health or keywords change gets a "stats" event, so a replay never shows stale numbers. Losing
// aura or Renown Health never takes a unit below 1.
// One aura pass over a side: clears and reapplies auras, slot keywords and grants. The view it
// built is returned in GDScript; Rust returns just its read_stats flag.
// `totals` is empty on pass 1 (stats read are own stats plus Renown) and pass 1's totals on
// pass 2.
// What a screen shows of a unit that auras and slots can change: Attack, Health, keywords.
// Each slot's unit's (Attack, maximum Health, Health) as it stands now, for AuraContext.stats.
pub type FightAurasRef = Rc<RefCell<FightAuras>>;
pub struct FightAuras {
    pub _combat_ref: Option<Weak<RefCell<Combat>>>,
    pub _keyword_binds: Dictionary<BoundMechanicRef>,
}
impl Default for FightAuras {
    fn default() -> Self {
        Self {
            _combat_ref: None,
            _keyword_binds: Default::default(),
        }
    }
}
impl ToState for FightAuras {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "_combat_ref" => &if self._combat_ref.is_some() { Variant::dictionary(Default::default()) } else { Variant::Nil },
            "_keyword_binds" => &self._keyword_binds,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["_combat_ref", "_keyword_binds"]
    }
}
impl FightAuras {
    pub fn create(combat: &CombatRef) -> FightAurasRef {
        Rc::new(RefCell::new(Self {
            _combat_ref: Some(Rc::downgrade(combat)),
            ..Self::default()
        }))
    }
    pub fn refresh(&mut self, combat: &mut Combat, log_changes: bool) {
        // The pre-aura health check is a rule (keep a living unit above zero).
        // Attack/keyword snapshots and comparisons only serve presentation events.
        let log_changes = log_changes && combat.keep_events;
        for side_index in 0..2 {
            let living = combat._board(side_index);
            let side_bridge = combat.bridge(side_index);
            let mut times = -1;
            let mut before = Vec::with_capacity(living.len());
            let mut i = 0;
            while i < living.len() {
                let unit = living.get(i).expect("living unit");
                let shown = log_changes.then(|| Self::shown(Some(&unit)));
                before.push((unit.borrow().health(), shown));
                let (slot, renown_slot, from_hand) = {
                    let unit = unit.borrow();
                    (unit.slot, unit.renown_slot, unit.from_hand)
                };
                let here = side_bridge
                    .borrow()
                    .slots
                    .get(slot as usize)
                    .expect("fight slot");
                let renown = here.borrow().renown;
                let stats = unit.borrow().stats.clone().expect("combat unit stats");
                stats.borrow_mut().renown = 0;
                if renown_slot == slot && renown != 0 {
                    if from_hand && times < 0 {
                        times = combat.side_query(side_index, Q_HAND_RENOWN_TIMES, 1).max(1);
                    }
                    stats.borrow_mut().renown =
                        renown.wrapping_mul(if from_hand { times } else { 1 });
                }
                i += 1;
            }
            // Pass 1 reads each unit's own stats plus Renown; if an aura read a unit's numbers
            // (Lends), pass 2 runs again on the totals pass 1 gave, so a lender lends what it shows.
            if self._pass(combat, side_index, &living, &Array::new()) {
                let totals = self._stats_of(combat, &living);
                self._pass(combat, side_index, &living, &totals);
            }
            for (i, (was_health, was)) in before.iter().enumerate() {
                let unit = living.get(i).expect("living unit");
                let health = unit.borrow().health();
                if *was_health > 0 && health <= 0 && !unit.borrow().destroyed {
                    let mut unit = unit.borrow_mut();
                    unit.damage = unit.damage.wrapping_sub(1_i64.wrapping_sub(health));
                }
                if log_changes
                    && Self::shown(Some(&unit)) != *was.as_ref().expect("shown stats")
                    && !combat
                        ._placing
                        .as_ref()
                        .is_some_and(|placing| Rc::ptr_eq(placing, &unit))
                {
                    let event = unit
                        .borrow()
                        .view(combat.geometry.as_ref().expect("combat geometry"));
                    event.insert("type", Variant::from("stats"));
                    let stats = unit.borrow().stats.clone().expect("combat unit stats");
                    let stats = stats.borrow();
                    event.insert("renown", Variant::Int(stats.renown));
                    event.insert("aura_attack", Variant::Int(stats.aura_attack));
                    event.insert("aura_health", Variant::Int(stats.aura_health));
                    event.insert("after", Variant::Int(combat.events.len() as i64 - 1));
                    drop(stats);
                    combat._log(&event);
                }
            }
        }
    }
    pub fn _pass(
        &mut self,
        combat: &mut Combat,
        side_index: i64,
        living: &Array<CombatUnitRef>,
        totals: &Array<[i64; 3]>,
    ) -> bool {
        let side_bridge = combat.bridge(side_index);
        // The caller only reads read_stats. Build its context lazily at the first
        // aura: metadata queries and slot-keyword binding cannot read or change it.
        // With no aura, no rule observes the unused defs/counter/stat snapshots.
        let mut view: Option<AuraContextRef> = None;
        let mut i = 0;
        while i < living.len() {
            let unit = living.get(i).expect("living unit");
            let (stats, slot) = {
                let unit = unit.borrow();
                (unit.stats.clone().expect("combat unit stats"), unit.slot)
            };
            stats.borrow_mut().aura_attack = 0;
            stats.borrow_mut().aura_health = 0;
            unit.borrow_mut().aura_mechanics = Array::new();
            let keywords = side_bridge
                .borrow()
                .slots
                .get(slot as usize)
                .expect("fight slot")
                .borrow()
                .keywords
                .clone();
            let mut k = 0;
            while k < keywords.len() {
                let keyword = keywords.get(k).expect("slot keyword");
                self._give_keyword(combat, Some(&unit), &keyword);
                k += 1;
            }
            i += 1;
        }
        let grants = Dictionary::new();
        let mut i = 0;
        while i < living.len() {
            let source = living.get(i).expect("aura source");
            let mechanics = source.borrow().mechanics.clone();
            let mut j = 0;
            while j < mechanics.len() {
                let bound = mechanics.get(j).expect("aura bound mechanic");
                let mechanic = bound.borrow().mechanic.clone().expect("bound mechanic");
                if mechanic.has_aura() {
                    let slot = source.borrow().slot;
                    let view = view.get_or_insert_with(|| {
                        self._view_for_pass(combat, side_index, living, totals)
                    });
                    self._apply(combat, view, &bound, slot, living, &grants);
                }
                j += 1;
            }
            i += 1;
        }
        let standing = side_bridge.borrow().standing.clone();
        let mut i = 0;
        while i < standing.len() {
            let bound = standing.get(i).expect("standing aura");
            let mechanic = bound.borrow().mechanic.clone().expect("bound mechanic");
            if mechanic.has_aura() {
                let view = view
                    .get_or_insert_with(|| self._view_for_pass(combat, side_index, living, totals));
                self._apply(combat, view, &bound, -1, living, &grants);
            }
            i += 1;
        }
        let read_stats = view.as_ref().is_some_and(|v| v.borrow().read_stats);
        // Binding an absent grant list only allocates empty arrays; it runs no hooks.
        if grants.is_empty() {
            return read_stats;
        }
        let mut i = 0;
        while i < living.len() {
            let unit = living.get(i).expect("living unit");
            let given = grants.get(&unit.borrow().uid.to_string()).as_array();
            let bound = combat
                .registry
                .as_ref()
                .expect("combat registry")
                .borrow()
                .bind_grants(&given);
            let aura_mechanics = unit.borrow().aura_mechanics.clone();
            aura_mechanics
                .borrow_mut()
                .extend(bound.borrow().iter().cloned());
            i += 1;
        }
        read_stats
    }
    fn _view_for_pass(
        &mut self,
        combat: &mut Combat,
        side_index: i64,
        living: &Array<CombatUnitRef>,
        totals: &Array<[i64; 3]>,
    ) -> AuraContextRef {
        let stats = if !totals.is_empty() {
            totals.clone()
        } else {
            self._stats_of(combat, living)
        };
        self._view_with_stats(combat, side_index, living, stats)
    }

    pub fn shown(unit: Option<&CombatUnitRef>) -> Array<Variant> {
        let unit = unit.expect("shown unit");
        let keywords = Array::new();
        let aura_mechanics = unit.borrow().aura_mechanics.clone();
        let mut i = 0;
        while i < aura_mechanics.len() {
            let bound = aura_mechanics.get(i).expect("aura mechanic");
            let (id, params) = {
                let bound = bound.borrow();
                (bound.id.clone(), bound.params.clone())
            };
            keywords.push(Variant::array(vec![
                Variant::String(id),
                Variant::Dictionary(params.borrow().to_dict()),
            ]));
            i += 1;
        }
        let unit = unit.borrow();
        Array::from([
            Variant::Int(unit.attack()),
            Variant::Int(unit.health()),
            Variant::Array(keywords),
        ])
    }
    pub fn _view(
        &mut self,
        combat: &mut Combat,
        side_index: i64,
        living: &Array<CombatUnitRef>,
    ) -> AuraContextRef {
        self._view_with_stats(combat, side_index, living, Array::new())
    }
    fn _view_with_stats(
        &mut self,
        combat: &mut Combat,
        side_index: i64,
        living: &Array<CombatUnitRef>,
        stats: Array<[i64; 3]>,
    ) -> AuraContextRef {
        let side_bridge = combat.bridge(side_index);
        let slot_count = combat
            .geometry
            .as_ref()
            .expect("combat geometry")
            .borrow()
            .slot_count as usize;
        let mut defs = vec![None; slot_count];
        let reservist_slots = Array::new();
        let mut counters = vec![None; slot_count];
        let mut i = 0;
        while i < living.len() {
            let unit = living.get(i).expect("living unit");
            let unit = unit.borrow();
            if unit.reservist {
                reservist_slots.push(unit.slot);
            }
            defs[unit.slot as usize] = unit.def.clone();
            counters[unit.slot as usize] = Some(unit.counters.clone());
            i += 1;
        }
        // Allocate empty dictionaries only for empty slots. Source defaults that
        // were immediately overwritten were unreachable, so omitting them is equivalent.
        let unit_counters = counters
            .into_iter()
            .map(Option::unwrap_or_default)
            .collect();
        let side_bridge = side_bridge.borrow();
        Rc::new(RefCell::new(AuraContext {
            geometry: combat.geometry.clone(),
            defs: defs.into(),
            reservist_slots,
            in_combat: true,
            counters: side_bridge.counters.clone(),
            heaps: side_bridge.heaps.clone(),
            unit_counters,
            outnumbered_by: combat.outnumbered_by(side_index),
            stats,
            read_stats: false,
        }))
    }
    pub fn _stats_of(
        &mut self,
        combat: &mut Combat,
        living: &Array<CombatUnitRef>,
    ) -> Array<[i64; 3]> {
        let slots = combat
            .geometry
            .as_ref()
            .expect("combat geometry")
            .borrow()
            .slot_count as usize;
        let mut out = vec![[0, 0, 0]; slots];
        let mut i = 0;
        while i < living.len() {
            let unit = living.get(i).expect("living unit");
            let unit = unit.borrow();
            let stats = unit.stats.as_ref().expect("combat stats").borrow();
            // Pure reads of the same StatBlock: health() is max_health() - damage.
            let max_health = stats.max_health();
            // Godot's Vector3i constructor narrows each component to a signed 32-bit integer.
            out[unit.slot as usize] = [
                stats.attack() as i32 as i64,
                max_health as i32 as i64,
                (max_health - unit.damage) as i32 as i64,
            ];
            i += 1;
        }
        out.into()
    }
    pub fn _apply(
        &mut self,
        combat: &mut Combat,
        view: &AuraContextRef,
        bound: &BoundMechanicRef,
        source_slot: i64,
        living: &Array<CombatUnitRef>,
        grants: &Dictionary,
    ) {
        let (mechanic, params) = {
            let bound = bound.borrow();
            (
                bound.mechanic.clone().expect("aura mechanic"),
                bound.params.clone(),
            )
        };
        // Only omit inherited trait defaults: they return zero or fresh empty arrays
        // and cannot read the context. Remaining hooks keep the source's exact order.
        let parts = mechanic.aura_parts();
        let mut i = 0;
        while i < living.len() {
            let target = living.get(i).expect("aura target");
            let slot = target.borrow().slot;
            if parts & AURA_STATS != 0 {
                let gain = mechanic.aura(&mut view.borrow_mut(), source_slot, slot, &params);
                let stats = target.borrow().stats.clone().expect("combat unit stats");
                {
                    let mut stats = stats.borrow_mut();
                    // The source hook returns Vector2i, whose components are signed 32-bit integers.
                    stats.aura_attack = stats.aura_attack.wrapping_add(gain.0 as i32 as i64);
                    stats.aura_health = stats.aura_health.wrapping_add(gain.1 as i32 as i64);
                }
            }
            if parts & AURA_KEYWORDS != 0 {
                let keywords =
                    mechanic.aura_keywords(&mut view.borrow_mut(), source_slot, slot, &params);
                let mut j = 0;
                while j < keywords.len() {
                    let keyword = keywords.get(j).expect("aura keyword");
                    self._give_keyword(combat, Some(&target), &keyword);
                    j += 1;
                }
            }
            if parts & AURA_GRANTS != 0 {
                let given =
                    mechanic.aura_grants(&mut view.borrow_mut(), source_slot, slot, &params);
                if !given.is_empty() {
                    let key = target.borrow().uid.to_string();
                    let list = grants.get(&key).as_array();
                    list.borrow_mut()
                        .extend(given.borrow().iter().cloned().map(Variant::Dictionary));
                    grants.insert(key, Variant::Array(list));
                }
            }
            i += 1;
        }
    }
    pub fn _give_keyword(
        &mut self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        keyword: &str,
    ) {
        let unit = unit.expect("aura keyword unit");
        let registry = combat.registry.as_ref().expect("combat registry");
        if !registry.borrow().has(keyword) || unit.borrow().has_mechanic(keyword) {
            return;
        }
        if !self._keyword_binds.borrow().contains_key(keyword) {
            let bound = registry
                .borrow()
                .bind(&MechanicSpec::new(keyword, None), false, true);
            self._keyword_binds
                .borrow_mut()
                .insert(keyword.to_owned(), bound);
        }
        let bound = self
            ._keyword_binds
            .borrow()
            .get(keyword)
            .cloned()
            .expect("cached keyword bind");
        unit.borrow().aura_mechanics.push(bound);
    }
    pub fn new() -> Self {
        Self::default()
    }
}
