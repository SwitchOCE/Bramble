#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/combat_unit.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::board::board_geometry::BoardGeometryRef;

use crate::core::mechanics::bound_mechanic::BoundMechanicRef;

use crate::core::mechanics::mechanic_registry::MechanicRegistryRef;

use crate::core::units::stat_block::StatBlockRef;
use crate::core::units::unit::{Unit, UnitRef};
use crate::core::units::unit_def::UnitDefRef;
use crate::core::units::unit_text::UnitText;

// GDScript rule and contract comments:
// A unit's copy for one combat (9.1.1). Its stat layers are copied from the recruit unit and
// this-combat changes go in the combat layer, so the recruit board never changes (12.1.2).
// Mechanic state for this combat (a shield that is up, a counter) lives in `state`.
// Current slot, or its last-known slot once it has left the board (12.2.3).
// Keywords from auras and the slot, recalculated with auras (12.2.1).
// This fight's mechanic state (a shield that is up, a counter for this fight only).
// Lasting numbers copied from the recruit unit (Unit.counters); Combat.add_counter changes
// them, and writes back when permanent.
// 9.4.5 "attacked this cycle".
// 10.1.2 on its side's board when combat began.
// The recruit unit this copies; -1 for a unit made in combat.
// 9.10.3 how many times this unit has come back.
// Removed from the board (died). A dead unit never comes back as this object (9.8.2).
// Destroyed outright (Venomous): dies at the next death check whatever its Health.
// Bought (4.3.1): the recruit unit came from the shop; false for tokens, copies and units made
// in the fight (Created).
// Per-fight limits ("5 a fight", "the first time each fight"), carried by the core across a
// return (SHARED-RULES 21): the returned unit is the same unit for every "a fight" limit. Use
// fight_count / add_fight_count; keep other fight state in `state`, which a return does not
// carry.
// Uses left a screen shows ("5 a fight", Molt charges): key -> uses left (Combat.show_uses).
// A per-fight limit's count (fight_counts), carried across a return.
// Every mechanic whose hooks run for this unit: its own, then what auras and its slot give.
// Has a death effect (Mechanic.has_death_effect), its own or given.
// A combat rule about this unit (Mechanic.Q_*), asked of each of its mechanics in order.
// Mechanics with parameters that auras or the slot gave this unit ("Root 1"), for pills.
pub type CombatUnitRef = Rc<RefCell<CombatUnit>>;
pub struct CombatUnit {
    pub uid: i64,
    pub def: Option<UnitDefRef>,
    pub golden: bool,
    pub side: i64,
    pub slot: i64,
    pub stats: Option<StatBlockRef>,
    pub damage: i64,
    pub mechanics: Array<BoundMechanicRef>,
    pub aura_mechanics: Array<BoundMechanicRef>,
    pub state: Dictionary,
    pub counters: Dictionary,
    pub flagged: bool,
    pub starting: bool,
    pub recruit_uid: i64,
    pub returns: i64,
    pub gone: bool,
    pub destroyed: bool,
    pub bought: bool,
    pub fight_counts: Dictionary,
    pub uses: Dictionary,
}
impl Default for CombatUnit {
    fn default() -> Self {
        Self {
            uid: 0,
            def: None,
            golden: false,
            side: 0,
            slot: -1,
            stats: None,
            damage: 0,
            mechanics: Array::new(),
            aura_mechanics: Array::new(),
            state: Default::default(),
            counters: Default::default(),
            flagged: false,
            starting: false,
            recruit_uid: -1,
            returns: 0,
            gone: false,
            destroyed: false,
            bought: false,
            fight_counts: Default::default(),
            uses: Default::default(),
        }
    }
}
impl ToState for CombatUnit {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "uid" => &self.uid,
            "def" => &self.def,
            "golden" => &self.golden,
            "side" => &self.side,
            "slot" => &self.slot,
            "stats" => &self.stats,
            "damage" => &self.damage,
            "mechanics" => &self.mechanics,
            "aura_mechanics" => &self.aura_mechanics,
            "state" => &self.state,
            "counters" => &self.counters,
            "flagged" => &self.flagged,
            "starting" => &self.starting,
            "recruit_uid" => &self.recruit_uid,
            "returns" => &self.returns,
            "gone" => &self.gone,
            "destroyed" => &self.destroyed,
            "bought" => &self.bought,
            "fight_counts" => &self.fight_counts,
            "uses" => &self.uses,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "uid",
            "def",
            "golden",
            "side",
            "slot",
            "stats",
            "damage",
            "mechanics",
            "aura_mechanics",
            "state",
            "counters",
            "flagged",
            "starting",
            "recruit_uid",
            "returns",
            "gone",
            "destroyed",
            "bought",
            "fight_counts",
            "uses",
        ]
    }
}
impl CombatUnit {
    pub fn from_unit(unit: &UnitRef, new_uid: i64, unit_side: i64) -> CombatUnitRef {
        let unit = unit.borrow();
        Rc::new(RefCell::new(Self {
            uid: new_uid,
            def: unit.def.clone(),
            golden: unit.golden,
            side: unit_side,
            slot: unit.slot,
            stats: Some(
                unit.stats
                    .as_ref()
                    .expect("unit stats")
                    .borrow()
                    .duplicate_block(),
            ),
            mechanics: unit.mechanics.duplicate(),
            counters: unit.counters.duplicate(),
            starting: true,
            recruit_uid: unit.uid,
            bought: unit.bought_copies > 0,
            ..Self::default()
        }))
    }
    pub fn fresh(
        card: &UnitDefRef,
        new_uid: i64,
        unit_side: i64,
        is_golden: bool,
        registry: &MechanicRegistryRef,
        stat_max: i64,
    ) -> CombatUnitRef {
        let unit = Unit::create(card, new_uid, is_golden, registry, stat_max);
        let unit = unit.borrow();
        Rc::new(RefCell::new(Self {
            uid: new_uid,
            def: Some(card.clone()),
            golden: is_golden,
            side: unit_side,
            stats: unit.stats.clone(),
            mechanics: unit.mechanics.clone(),
            ..Self::default()
        }))
    }
    pub fn attack(&self) -> i64 {
        self.stats.as_ref().expect("combat stats").borrow().attack()
    }
    pub fn max_health(&self) -> i64 {
        self.stats
            .as_ref()
            .expect("combat stats")
            .borrow()
            .max_health()
    }
    pub fn health(&self) -> i64 {
        self.max_health() - self.damage
    }
    pub fn should_die(&self) -> bool {
        !self.gone && (self.health() <= 0 || self.destroyed)
    }
    pub fn fight_count(&self, key: &str) -> i64 {
        self.fight_counts.get(key).as_i64()
    }
    pub fn add_fight_count(&mut self, key: &str, amount: i64) {
        self.fight_counts
            .insert(key, Variant::Int(self.fight_count(key) + amount));
    }
    pub fn state_int(&self, key: &str) -> i64 {
        self.state.get(key).as_i64()
    }
    pub fn set_state(&mut self, key: &str, value: i64) {
        self.state.insert(key, Variant::Int(value));
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
    pub fn query(unit: &CombatUnitRef, name: &str, base: i64) -> i64 {
        let mut value = base;
        let hooks = unit.borrow().hooks();
        for bound in hooks.borrow().iter() {
            let bound = bound.borrow();
            if let Some(mechanic) = &bound.mechanic {
                value = mechanic.combat_query(Some(unit), name, value, &bound.params);
            }
        }
        value
    }
    pub fn _grants_view(&self) -> Array<Variant> {
        let out = Array::new();
        for bound in self.aura_mechanics.to_vec() {
            let shown = bound.borrow().params.borrow().to_dict();
            if !shown.is_empty() {
                shown.insert("mechanic", bound.borrow().id.clone().into());
                out.push(Variant::Dictionary(shown));
            }
        }
        out
    }
    pub fn view(&self, geometry: &BoardGeometryRef) -> Dictionary {
        let keywords = Array::new();
        for bound in self.hooks().to_vec() {
            let bound = bound.borrow();
            if bound.params.borrow().is_empty() && !keywords.has(&bound.id) {
                keywords.push(bound.id.clone());
            }
        }
        let def = self.def.as_ref().unwrap();
        crate::state_dict!{"uid"=>&self.uid,"recruit_uid"=>&self.recruit_uid,"id"=>&def.borrow().id,"side"=>&self.side,"slot"=>&self.slot,"label"=>&geometry.borrow().label(self.slot),"attack"=>&self.attack(),"health"=>&self.health(),"golden"=>&self.golden,"bought"=>&self.bought,"keywords"=>&keywords,"grants"=>&self._grants_view(),"effects"=>&UnitText::effects_view(&self.mechanics),"totals"=>&UnitText::totals_view(&self.hooks()),"counters"=>&UnitText::counters_view(&self.counters),"uses"=>&self.uses.duplicate(),"text"=>&UnitText::text_of(def,&self.mechanics,self.golden),"reminders"=>&def.borrow().reminders}.as_dict()
    }
    pub fn new() -> Self {
        Self::default()
    }
}
