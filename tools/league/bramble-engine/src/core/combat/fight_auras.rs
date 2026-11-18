#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/fight_auras.gd`; gameplay TODO bodies belong to the later port workers.
use std::{cell::RefCell, rc::{Rc, Weak}};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::state::aura_context::{AuraContextRef};

use crate::core::mechanics::bound_mechanic::{BoundMechanicRef};

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::{CombatUnitRef};

// GDScript rule and contract comments:
// 12.2.1 auras, standing auras and slot effects (8.5) in a fight, recalculated on both boards
// whenever a board, a player number or a heap changes (Combat.refresh). Each unit whose Attack,
// Health or keywords change gets a "stats" event, so a replay never shows stale numbers. Losing
// aura or slot Health never takes a unit below 1.
// One aura pass over a side: clears and reapplies auras, slot keywords and grants. The view it
// built is returned (read_stats says whether any aura read a unit's numbers).
// `totals` is empty on pass 1 (stats read are own stats plus the slot) and pass 1's totals on
// pass 2.
// What a screen shows of a unit that auras and slots can change: Attack, Health, keywords.
// The percent of their Attack buff a side's slots give this fight (SHARED-RULES 13): the
// bigger of the side's fight-long number (FightSide.slot_attack_percent, set by an effect such
// as the Edgewright's and kept if it dies) and Q_SLOT_ATTACK_PERCENT asked through
// Combat.side_query (units on the board, then standing mechanics, with the side set).
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
        Rc::new(RefCell::new(Self { _combat_ref:Some(Rc::downgrade(combat)), ..Self::default() }))
    }
    pub fn refresh(&mut self, combat: &mut Combat, log_changes: bool) {
        todo!("port src/core/combat/fight_auras.gd:refresh")
    }
    pub fn _pass(&mut self, combat: &mut Combat, side_index: i64, living: &Array<CombatUnitRef>, totals: &Array<[i64; 3]>) -> AuraContextRef {
        todo!("port src/core/combat/fight_auras.gd:_pass")
    }
    pub fn shown(unit: Option<&CombatUnitRef>) -> Array<Variant> {
        todo!("port src/core/combat/fight_auras.gd:shown")
    }
    pub fn slot_attack_percent(combat: &mut Combat, side_index: i64) -> i64 {
        todo!("port src/core/combat/fight_auras.gd:slot_attack_percent")
    }
    pub fn _view(&mut self, combat: &mut Combat, side_index: i64, living: &Array<CombatUnitRef>) -> AuraContextRef {
        todo!("port src/core/combat/fight_auras.gd:_view")
    }
    pub fn _stats_of(&mut self, combat: &mut Combat, living: &Array<CombatUnitRef>) -> Array<[i64; 3]> {
        todo!("port src/core/combat/fight_auras.gd:_stats_of")
    }
    pub fn _apply(&mut self, combat: &mut Combat, view: &AuraContextRef, bound: &BoundMechanicRef, source_slot: i64, living: &Array<CombatUnitRef>, grants: &Dictionary) {
        todo!("port src/core/combat/fight_auras.gd:_apply")
    }
    pub fn _give_keyword(&mut self, combat: &mut Combat, unit: Option<&CombatUnitRef>, keyword: &str) {
        todo!("port src/core/combat/fight_auras.gd:_give_keyword")
    }
    pub fn new() -> Self { Self::default() }
}
