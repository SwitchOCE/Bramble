#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/units/unit.gd`; gameplay TODO bodies belong to the later port workers.
use crate::core::mechanics::mechanic_spec::MechanicSpec;
use crate::core::units::unit_text::UnitText;
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::mechanics::bound_mechanic::BoundMechanicRef;

use crate::core::mechanics::mechanic_registry::MechanicRegistryRef;

use crate::core::units::stat_block::{StatBlock, StatBlockRef};
use crate::core::units::unit_def::UnitDefRef;

// GDScript rule and contract comments:
// One card a player holds, in hand or on the recruit board: a unit or a Tavern spell.
// `copies` counts copies of a real card for sell value (4.3.3–4.3.4). A unit starts with one
// copy, and a triple combines three. `bought_copies` tracks origin for Compost and token sales.
// A Bought unit starts with one bought copy, and a Created unit starts with zero.
// Own text first (golden already applied to its numbers), then granted mechanics.
// Board slot, or -1 in hand.
// Lasting mechanic numbers on this unit (a medal count, a charge), kept for the game and
// copied into each fight. Keys are mechanic-chosen names.
// Mechanic numbers that reset at the start of each turn (uses of an ability this turn).
// Keywords this unit has from an aura or its slot, recalculated with auras (12.2.1).
// Every mechanic whose hooks run for this unit: its own text, then what auras and its slot give.
// Has a death effect (Mechanic.has_death_effect), its own or given.
// 11.1.1 gain a keyword (no parameters). False if the unit has it already or it is unknown.
// Gains a mechanic with parameters ('Give a unit "+1 Fury"'), checked like card data. Unlike a
// keyword it may stack: a second grant adds another, and a mechanic that sums its numbers (Fury)
// adds them up. The numbers are the giver's (already doubled if the giver is golden), so a golden
// target never doubles them again (7.3.5). Use RecruitContext.give_effect or
// FightSide.give_effect, which log it. False when the mechanic is unknown or the params are wrong.
// The keyword mechanics (those with no parameters), for display.
// JSON-shaped view for logs and the UI.
pub type UnitRef = Rc<RefCell<Unit>>;
pub struct Unit {
    pub uid: i64,
    pub def: Option<UnitDefRef>,
    pub golden: bool,
    pub copies: i64,
    pub bought_copies: i64,
    pub stats: Option<StatBlockRef>,
    pub mechanics: Array<BoundMechanicRef>,
    pub slot: i64,
    pub worked_this_turn: bool,
    pub counters: Dictionary,
    pub turn_counters: Dictionary,
    pub aura_mechanics: Array<BoundMechanicRef>,
}
impl Default for Unit {
    fn default() -> Self {
        Self {
            uid: 0,
            def: None,
            golden: false,
            copies: 1,
            bought_copies: 0,
            stats: None,
            mechanics: Array::new(),
            slot: -1,
            worked_this_turn: false,
            counters: Default::default(),
            turn_counters: Default::default(),
            aura_mechanics: Array::new(),
        }
    }
}
impl ToState for Unit {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "uid" => &self.uid,
            "def" => &self.def,
            "golden" => &self.golden,
            "copies" => &self.copies,
            "bought_copies" => &self.bought_copies,
            "stats" => &self.stats,
            "mechanics" => &self.mechanics,
            "slot" => &self.slot,
            "worked_this_turn" => &self.worked_this_turn,
            "counters" => &self.counters,
            "turn_counters" => &self.turn_counters,
            "aura_mechanics" => &self.aura_mechanics,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "uid",
            "def",
            "golden",
            "copies",
            "bought_copies",
            "stats",
            "mechanics",
            "slot",
            "worked_this_turn",
            "counters",
            "turn_counters",
            "aura_mechanics",
        ]
    }
}
impl Unit {
    pub fn create(
        card: &UnitDefRef,
        new_uid: i64,
        is_golden: bool,
        registry: &MechanicRegistryRef,
        stat_max: i64,
    ) -> UnitRef {
        let factor = if is_golden { 2 } else { 1 };
        let definition = card.borrow();
        let made = Self {
            uid: new_uid,
            def: Some(card.clone()),
            golden: is_golden,
            stats: Some(StatBlock::of(
                definition.attack * factor,
                definition.health * factor,
                stat_max,
            )),
            ..Self::default()
        };
        for spec in definition.mechanics.borrow().iter() {
            let bound = registry.borrow().bind(spec, is_golden, false);
            made.mechanics.push(bound.clone());
            let bound = bound.borrow();
            let supply = bound.params.borrow().num("supply");
            if supply > 0 {
                made.counters
                    .insert(format!("supply:{}", bound.id), supply.into());
            }
        }
        Rc::new(RefCell::new(made))
    }
    pub fn is_bought(&self) -> bool {
        self.bought_copies > 0
    }
    pub fn is_spell(&self) -> bool {
        self.def
            .as_ref()
            .expect("unit definition")
            .borrow()
            .is_spell()
    }
    pub fn attack(&self) -> i64 {
        self.stats.as_ref().expect("unit stats").borrow().attack()
    }
    pub fn health(&self) -> i64 {
        self.stats
            .as_ref()
            .expect("unit stats")
            .borrow()
            .max_health()
    }
    pub fn has_mechanic(&self, mechanic_id: &str) -> bool {
        // A pure membership query needs no concatenated hooks snapshot. Hook dispatch
        // still uses hooks() so its live-array and callback semantics are unchanged.
        self.mechanics
            .borrow()
            .iter()
            .chain(self.aura_mechanics.borrow().iter())
            .any(|bound| bound.borrow().id == mechanic_id)
    }
    pub fn hooks(&self) -> Array<BoundMechanicRef> {
        if self.aura_mechanics.is_empty() {
            return self.mechanics.clone();
        }
        let out = self.mechanics.duplicate();
        out.borrow_mut()
            .extend(self.aura_mechanics.borrow().iter().cloned());
        out
    }
    pub fn has_death_effect(&self) -> bool {
        self.hooks().borrow().iter().any(|bound| {
            bound
                .borrow()
                .mechanic
                .as_ref()
                .is_some_and(|mechanic| mechanic.has_death_effect())
        })
    }
    pub fn counter(&self, key: &str) -> i64 {
        self.counters.get(key).as_i64()
    }
    pub fn turn_counter(&self, key: &str) -> i64 {
        self.turn_counters.get(key).as_i64()
    }
    pub fn grant(&mut self, registry: &MechanicRegistryRef, mechanic_id: &str) -> bool {
        if self.has_mechanic(mechanic_id) || !registry.borrow().has(mechanic_id) {
            return false;
        }
        self.mechanics.push(registry.borrow().bind(
            &MechanicSpec::new(mechanic_id, None),
            self.golden,
            true,
        ));
        true
    }
    pub fn grant_effect(
        &mut self,
        registry: &MechanicRegistryRef,
        mechanic_id: &str,
        raw: &Dictionary,
    ) -> bool {
        let Some(bound) = registry.borrow().bind_given(mechanic_id, raw) else {
            return false;
        };
        self.mechanics.push(bound);
        true
    }
    pub fn keyword_ids(&self) -> Array<String> {
        let mut out = Vec::new();
        for bound in self.hooks().borrow().iter() {
            let bound = bound.borrow();
            let printed = self
                .def
                .as_ref()
                .expect("unit definition")
                .borrow()
                .keywords
                .has(&bound.id);
            if (printed || bound.params.borrow().is_empty()) && !out.contains(&bound.id) {
                out.push(bound.id.clone());
            }
        }
        out.into()
    }
    pub fn view(&self) -> Dictionary {
        let definition = self.def.as_ref().expect("unit definition");
        crate::state_dict! {
            "uid"=>&self.uid,"id"=>&definition.borrow().id,"slot"=>&self.slot,
            "attack"=>&self.attack(),"health"=>&self.health(),"golden"=>&self.golden,
            "bought"=>&self.is_bought(),"worked_this_turn"=>&self.worked_this_turn,"keywords"=>&self.keyword_ids(),
            "counters"=>&UnitText::counters_view(&self.counters),
            "effects"=>&UnitText::effects_view(&self.mechanics),"totals"=>&UnitText::totals_view(&self.hooks()),
            "text"=>&UnitText::text_of(definition,&self.mechanics,self.golden),"reminders"=>&definition.borrow().reminders,
        }.as_dict()
    }
    pub fn new() -> Self {
        Self::default()
    }
}
