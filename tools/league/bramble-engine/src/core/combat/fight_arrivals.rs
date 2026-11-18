#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/combat/fight_arrivals.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::board::board_geometry::BoardGeometryRef;

use crate::core::combat::combat::{Combat, CombatRef};
use crate::core::combat::combat_unit::CombatUnitRef;

use crate::core::units::unit::UnitRef;

// GDScript rule and contract comments:
// Who fills a slot that empties in a fight, in one place (SHARED-RULES slot-fill order). After a
// round of deaths: first each dying unit's own summons and returns (Combat's death steps 2 and
// 4), then Reserve units step into the slots friends died in (the side's fill-first slot, such
// as a Guard post, then reading order), then waiting summons in one line (Hoppers, Compost
// copies) into empty slots in reading order, then the after_death_round hook (a Recruiting
// Sergeant's Private). SHARED-RULES ruling 6.
// Per side: CombatUnits from the hand waiting to step in (Reserve), in hand order.
// Per side: waiting summons, {"id", "source", "payload"}, in landing order.
// Copies each side's hand units that have Reserve (Q_RESERVE), or every hand unit when the
// side says so (Q_HAND_RESERVE), with their buffs, as waiting units. Spells stay behind.
// The reserve as the fight log shows it at the start: [[unit view], [unit view]].
// Queues a summon that found no room; it keeps its source and payload.
// The slot-fill order after one round of deaths. `emptied` [[slot], [slot]]: slots units died
// in this round. Active side first.
pub type FightArrivalsRef = Rc<RefCell<FightArrivals>>;
pub struct FightArrivals {
    pub reserve: Array<Array<CombatUnitRef>>,
    pub waiting: Array<Array<WaitingSummon>>,
    pub _combat_ref: Option<Weak<RefCell<Combat>>>,
}
impl Default for FightArrivals {
    fn default() -> Self {
        Self {
            reserve: Array::from(vec![Array::new(), Array::new()]),
            waiting: Array::from(vec![Array::new(), Array::new()]),
            _combat_ref: None,
        }
    }
}
impl ToState for FightArrivals {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "reserve" => &self.reserve,
            "waiting" => &self.waiting,
            "_combat_ref" => &if self._combat_ref.is_some() { Variant::dictionary(Default::default()) } else { Variant::Nil },
        }
    }
    fn field_names() -> &'static [&'static str] {
        &["reserve", "waiting", "_combat_ref"]
    }
}
impl FightArrivals {
    pub fn create(combat: &CombatRef) -> FightArrivalsRef {
        Rc::new(RefCell::new(Self {
            _combat_ref: Some(Rc::downgrade(combat)),
            ..Self::default()
        }))
    }
    pub fn _combat(&self) -> Option<CombatRef> {
        self._combat_ref.as_ref().and_then(Weak::upgrade)
    }
    pub fn take_reserve(&mut self, combat: &mut Combat, hands: &Array<Array<UnitRef>>) {
        todo!("port src/core/combat/fight_arrivals.gd:take_reserve")
    }
    pub fn reserve_view(&self, combat: &mut Combat, geometry: &BoardGeometryRef) -> Array<Variant> {
        todo!("port src/core/combat/fight_arrivals.gd:reserve_view")
    }
    pub fn wait(
        &mut self,
        combat: &mut Combat,
        side_index: i64,
        card_id: &str,
        source: Option<&CombatUnitRef>,
        payload: &Dictionary,
        golden: bool,
    ) {
        todo!("port src/core/combat/fight_arrivals.gd:wait")
    }
    pub fn after_deaths(
        &mut self,
        combat: &mut Combat,
        emptied: &Array<Array<i64>>,
        active_side: i64,
    ) {
        todo!("port src/core/combat/fight_arrivals.gd:after_deaths")
    }
    pub fn _step_in(&mut self, combat: &mut Combat, side_index: i64, died_in: &Array<i64>) {
        todo!("port src/core/combat/fight_arrivals.gd:_step_in")
    }
    pub fn _land(&mut self, combat: &mut Combat, side_index: i64) {
        todo!("port src/core/combat/fight_arrivals.gd:_land")
    }
    pub fn new() -> Self {
        Self::default()
    }
}
#[derive(Clone)]
pub struct WaitingSummon {
    pub id: String,
    pub source: Option<CombatUnitRef>,
    pub payload: Dictionary,
    pub golden: bool,
}
impl ToState for WaitingSummon {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "id"=>&self.id, "source"=>&self.source, "payload"=>&self.payload, "golden"=>&self.golden }
    }
}
