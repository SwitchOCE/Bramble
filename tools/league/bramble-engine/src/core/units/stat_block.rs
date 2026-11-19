#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/units/stat_block.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

// GDScript rule and contract comments:
// Attack and Health computed from layers, never mutated in place (architecture notes 4;
// prototype lesson 4): base (golden already doubled) -> "set to" -> permanent additions ->
// this-turn additions -> this-combat additions -> auras -> the slot's buff (8.5) -> Renown -> clamp
// (1.2.4). Damage is kept apart:
// Health = maximum Health - damage (9.6.3).
// 8.5 the buff of the slot the unit stands in; recalculated with auras.
// Own stats (SHARED-RULES 43): printed and every buff on the unit itself, this fight's gains
// included; never its slot's buff, its Renown, auras or lent stats. Every effect that copies, keeps or takes
// a unit's stats reads these.
// A copy for combat (9.1.1): this-turn layers have already ended (3.4.1 step 2).
// 12.1.1 "this turn" ends.
pub type StatBlockRef = Rc<RefCell<StatBlock>>;
#[derive(Clone)]
pub struct StatBlock {
    pub base_attack: i64,
    pub base_health: i64,
    pub set_attack: i64,
    pub set_health: i64,
    pub perm_attack: i64,
    pub perm_health: i64,
    pub turn_attack: i64,
    pub turn_health: i64,
    pub combat_attack: i64,
    pub combat_health: i64,
    pub aura_attack: i64,
    pub aura_health: i64,
    pub slot_attack: i64,
    pub slot_health: i64,
    /// Renown from the slot, recalculated with auras and excluded from own stats.
    pub renown: i64,
    pub stat_max: i64,
}
impl Default for StatBlock {
    fn default() -> Self {
        Self {
            base_attack: 0,
            base_health: 0,
            set_attack: Self::UNSET,
            set_health: Self::UNSET,
            perm_attack: 0,
            perm_health: 0,
            turn_attack: 0,
            turn_health: 0,
            combat_attack: 0,
            combat_health: 0,
            aura_attack: 0,
            aura_health: 0,
            slot_attack: 0,
            slot_health: 0,
            renown: 0,
            stat_max: 1000000000,
        }
    }
}
impl ToState for StatBlock {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "base_attack" => &self.base_attack,
            "base_health" => &self.base_health,
            "set_attack" => &self.set_attack,
            "set_health" => &self.set_health,
            "perm_attack" => &self.perm_attack,
            "perm_health" => &self.perm_health,
            "turn_attack" => &self.turn_attack,
            "turn_health" => &self.turn_health,
            "combat_attack" => &self.combat_attack,
            "combat_health" => &self.combat_health,
            "aura_attack" => &self.aura_attack,
            "aura_health" => &self.aura_health,
            "slot_attack" => &self.slot_attack,
            "slot_health" => &self.slot_health,
            "renown" => &self.renown,
            "stat_max" => &self.stat_max,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "base_attack",
            "base_health",
            "set_attack",
            "set_health",
            "perm_attack",
            "perm_health",
            "turn_attack",
            "turn_health",
            "combat_attack",
            "combat_health",
            "aura_attack",
            "aura_health",
            "slot_attack",
            "slot_health",
            "renown",
            "stat_max",
        ]
    }
}
impl StatBlock {
    pub const UNSET: i64 = -1;
    pub fn of(start_attack: i64, start_health: i64, cap: i64) -> StatBlockRef {
        Rc::new(RefCell::new(Self {
            base_attack: start_attack,
            base_health: start_health,
            stat_max: cap,
            ..Self::default()
        }))
    }
    pub fn attack(&self) -> i64 {
        let value = if self.set_attack == Self::UNSET {
            self.base_attack
        } else {
            self.set_attack
        };
        (value
            + self.perm_attack
            + self.turn_attack
            + self.combat_attack
            + self.aura_attack
            + self.slot_attack
            + self.renown)
            .clamp(0, self.stat_max)
    }
    pub fn own_attack(&self) -> i64 {
        let value = if self.set_attack == Self::UNSET {
            self.base_attack
        } else {
            self.set_attack
        };
        (value + self.perm_attack + self.turn_attack + self.combat_attack).clamp(0, self.stat_max)
    }
    pub fn own_health(&self) -> i64 {
        let value = if self.set_health == Self::UNSET {
            self.base_health
        } else {
            self.set_health
        };
        (value + self.perm_health + self.turn_health + self.combat_health).clamp(0, self.stat_max)
    }
    pub fn max_health(&self) -> i64 {
        let value = if self.set_health == Self::UNSET {
            self.base_health
        } else {
            self.set_health
        };
        (value
            + self.perm_health
            + self.turn_health
            + self.combat_health
            + self.aura_health
            + self.slot_health
            + self.renown)
            .clamp(0, self.stat_max)
    }
    pub fn duplicate_block(&self) -> StatBlockRef {
        Rc::new(RefCell::new(self.clone()))
    }
    pub fn end_turn(&mut self) {
        self.turn_attack = 0;
        self.turn_health = 0;
    }
    pub fn new() -> Self {
        Self::default()
    }
}
