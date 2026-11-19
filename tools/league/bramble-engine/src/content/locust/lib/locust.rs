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
// Source: src/content/locust/lib/locust.gd
// Names and small rules the Locust mechanics share (not a mechanic: the loader only registers
// scripts in mechanics/). Design: docs/ideation-track-2/tribes/locust/.
// Player numbers (SHARED-RULES: Tide +N, Hopper bonus).
// Molt charges, as per-fight counts on the unit (CombatUnit.fight_count; the core carries them
// across a return): extra ones given this fight (Skin-shedder) and those used. The screen sees
// what is left as `uses` under the Molt id.
// How many Hoppers each Hopper summon makes (Mother of Thousands); asked as a side_query in a
// fight and through Rules.ask in the Recruit Phase.
// Eat: the mechanics that eat, the Gorger's once-a-turn mark and the mark on an eaten sale.
// Hoppers one summon makes in a fight: `count` times the side's multiplier.
// The same in the Recruit Phase, from the recruit board.
// Summons `count` Hoppers in a fight from `slot` (own slot first for a dying unit's own
// effect); with no room they wait (SHARED-RULES, Waiting).
// Summons Hoppers on the recruit board from the slot the unit left (an eaten unit's death
// effect): the first into that slot when it is empty (8.4.1), the rest nearest (8.4.2); with no
// room they are lost (8.4.5).
// Printed Molt is one charge a fight; Skin-shedder adds MOLT_EXTRA for this fight.
// Who eats a sale: each sold unit is eaten once. A Gorger that hasn't eaten this turn first
// (reading order), else, for a sold Locust, the first Granary Glutton. Null for none.
// Eat: `unit` gains the sold unit's own stats (times `times`) permanently, then the sold
// unit's death effects resolve in the Recruit Phase (SHARED-RULES, Eat; ruling 43).
// The sale is eaten once, and a Gorger eats once a turn (turn counters clear each turn).
pub const TRIBE: &str = "Locust";
pub const HOPPER: &str = "hopper";
pub const TIDE: &str = "locust_tide";
pub const HOPPER_BONUS: &str = "locust_hopper_bonus";
pub const MOLT: &str = "locust_molt";
pub const MOLT_EXTRA: &str = "locust_molt_extra";
pub const MOLT_USED: &str = "locust_molt_used";
pub const Q_HOPPER_TIMES: &str = "locust_hopper_times";
pub const GORGE: &str = "locust_gorge";
pub const GLUT: &str = "locust_glut";
pub const ATE: &str = "locust_ate";
pub const EATEN: &str = "locust_eaten";
#[derive(Clone, Default)]
pub struct Locust;
pub type LocustRef = Rc<RefCell<Locust>>;
impl ToState for Locust {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Locust {
    pub fn hopper_count(combat: &mut Combat, side: i64, count: i64) -> i64 {
        count * combat.side_query(side, Q_HOPPER_TIMES, 1).max(1)
    }
    pub fn recruit_hopper_count(ctx: &mut RecruitContext, count: i64) -> i64 {
        let times = ctx.ask(Q_HOPPER_TIMES, 1);
        count * times.max(1)
    }
    pub fn summon_hoppers(
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        count: i64,
        own_slot_first: bool,
    ) {
        let side = unit.unwrap().borrow().side;
        for _i in 0..Self::hopper_count(combat, side, count) {
            let (side, slot) = {
                let unit = unit.unwrap().borrow();
                (unit.side, unit.slot)
            };
            combat.summon(
                side,
                HOPPER,
                slot,
                own_slot_first,
                unit,
                true,
                &Dictionary::new(),
                false,
            );
        }
    }
    pub fn recruit_summon_hoppers(ctx: &mut RecruitContext, unit: Option<&UnitRef>, count: i64) {
        for _i in 0..Self::recruit_hopper_count(ctx, count) {
            let slot = unit.unwrap().borrow().slot;
            ctx.summon(HOPPER, slot, true, false);
        }
    }
    pub fn molt_charges(unit: Option<&CombatUnitRef>) -> i64 {
        let unit = unit.unwrap().borrow();
        let printed = i64::from(
            unit.def
                .as_ref()
                .unwrap()
                .borrow()
                .keywords
                .has(&MOLT.to_owned()),
        );
        printed + unit.fight_count(MOLT_EXTRA)
    }
    pub fn molt_left(unit: Option<&CombatUnitRef>) -> i64 {
        Self::molt_charges(unit) - unit.unwrap().borrow().fight_count(MOLT_USED)
    }
    pub fn eater(player: Option<&PlayerStateRef>, sold: &UnitRef) -> Option<UnitRef> {
        if sold.borrow().is_spell() || sold.borrow().turn_counter(EATEN) > 0 {
            return None;
        }
        let board = player.unwrap().borrow().board_units();
        let mut index = 0;
        while index < board.len() {
            let unit = board.get(index).unwrap();
            index += 1;
            if unit.borrow().has_mechanic(GORGE) && unit.borrow().turn_counter(ATE) == 0 {
                return Some(unit);
            }
        }
        if sold
            .borrow()
            .def
            .as_ref()
            .unwrap()
            .borrow()
            .has_tribe(TRIBE)
        {
            let board = player.unwrap().borrow().board_units();
            let mut index = 0;
            while index < board.len() {
                let unit = board.get(index).unwrap();
                index += 1;
                if unit.borrow().has_mechanic(GLUT) {
                    return Some(unit);
                }
            }
        }
        None
    }
    pub fn eat(
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        sold: &UnitRef,
        mechanic_id: &str,
        times: i64,
    ) {
        let eater = Self::eater(ctx.player.as_ref(), sold);
        let same = match (eater.as_ref(), unit) {
            (Some(eater), Some(unit)) => Rc::ptr_eq(eater, unit),
            (None, None) => true,
            _ => false,
        };
        if !same || !ctx.trigger(unit, mechanic_id) {
            return;
        }
        // The sale is eaten once, and a Gorger eats once a turn (turn counters clear each turn).
        ctx.add_turn_counter(sold, EATEN, 1, unit);
        let unit = unit.unwrap();
        if mechanic_id == GORGE {
            ctx.add_turn_counter(unit, ATE, 1, Some(unit));
        }
        let gain_attack = sold.borrow().stats.as_ref().unwrap().borrow().own_attack() * times;
        let gain_health = sold.borrow().stats.as_ref().unwrap().borrow().own_health() * times;
        ctx.buff(unit, gain_attack, gain_health, true, Some(unit));
        ctx.run_death_effects(sold);
    }
}
