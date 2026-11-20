#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/state/fight_report.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::units::unit::UnitRef;

// GDScript rule and contract comments:
// What a player's units learn after their fight (Mechanic.after_fight): the outcome and which
// of the player's own units were on the board at the end.
// 1 won, 0 tie, -1 lost.
// The opponent's player id (Matchmaking.GHOST for the ghost).
// Recruit uids of this player's units alive (themselves or a return) at the end.
// Friendly units that died in the fight, tokens included.
// Outnumbered: how many more counted units the enemy had at fight start (Combat.outnumbered_by).
pub type FightReportRef = Rc<RefCell<FightReport>>;
pub struct FightReport {
    pub outcome: i64,
    pub opponent: i64,
    pub survivors: Array<i64>,
    pub deaths: i64,
    pub outnumbered_by: i64,
}
impl Default for FightReport {
    fn default() -> Self {
        Self {
            outcome: 0,
            opponent: -1,
            survivors: Array::new(),
            deaths: 0,
            outnumbered_by: 0,
        }
    }
}
impl ToState for FightReport {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "outcome" => &self.outcome,
            "opponent" => &self.opponent,
            "survivors" => &self.survivors,
            "deaths" => &self.deaths,
            "outnumbered_by" => &self.outnumbered_by,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "outcome",
            "opponent",
            "survivors",
            "deaths",
            "outnumbered_by",
        ]
    }
}
impl FightReport {
    pub fn survived(&self, unit: Option<&UnitRef>) -> bool {
        unit.is_some_and(|unit| self.survivors.borrow().contains(&unit.borrow().uid))
    }
    pub fn won(&self) -> bool {
        self.outcome > 0
    }
    pub fn new() -> Self {
        Self::default()
    }
}
