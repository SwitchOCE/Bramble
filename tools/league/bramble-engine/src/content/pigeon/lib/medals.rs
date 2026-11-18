#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/content/pigeon/lib/medals.gd
// Medals (SHARED-RULES, Pigeons own): a count on the unit, each a permanent +2/+2 of its own.
// Decorated is 3 or more. Shared by the Pigeon mechanics; not a mechanic itself.
// Earns `count` Medals in the Recruit Phase: the count, then the unit's own +2/+2 each.
// Earns `count` Medals in a fight, on the fight unit and on the real one at once (kept if it
// dies in the same exchange, SHARED-RULES 35). The count goes first so the buff's aura refresh
// sees it (Decorated mid-fight).
pub const MEDAL: &str = "pigeon_medal";
pub const DECORATED_AT: i64 = 3;
pub const STATS: i64 = 2;
#[derive(Clone, Default)]
pub struct Medals;
pub type MedalsRef = Rc<RefCell<Medals>>;
impl ToState for Medals {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Medals {
    pub fn earn(
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        count: i64,
        source: Option<&UnitRef>,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if count <= 0 {
            return;
        }
        ctx.add_unit_counter(unit, MEDAL, count, source);
        ctx.buff(unit, STATS * count, STATS * count, true, source);
    }
    pub fn earn_in_fight(combat: &mut Combat, unit: Option<&CombatUnitRef>, count: i64) {
        let Some(unit) = unit else {
            return;
        };
        if count <= 0 {
            return;
        }
        let side_index = unit.borrow().side;
        let side = combat.bridge(side_index);
        crate::core::combat::fight_side::FightSide::add_unit_counter(
            &side,
            combat,
            Some(unit),
            MEDAL,
            count,
            true,
            Some(unit),
        );
        combat.buff(Some(unit), STATS * count, STATS * count, Some(unit), true);
    }
    pub fn decorated(view: &AuraContext, slot: i64) -> bool {
        view.unit_counter(slot, MEDAL) >= DECORATED_AT
    }
    pub fn is_pigeon(view: &AuraContext, slot: i64) -> bool {
        view.def_at(slot)
            .is_some_and(|def| def.borrow().has_tribe("Pigeon"))
    }
}
