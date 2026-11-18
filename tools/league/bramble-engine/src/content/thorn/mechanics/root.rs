#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::compost_rules::HEAP;
use crate::core::combat::fight_side::FightSide;
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
// Source: src/content/thorn/mechanics/root.gd
// Root N: the first time this dies each fight, spend N Compost to return it (9.7.2 step 4),
// through the core's return protocol. Once a fight for each unit (a fight count, carried across
// any return), not a choice. It offers when the Compost holds N entries; the core picks Root
// before a Molt (RETURN_FIRST), so a unit with both uses Molt only when the Compost can't pay
// or its Root is used. It comes back as it stands on the recruit board at full Health; a unit
// with no recruit-board self (a token, a copy) comes back plain. With no free slot the core
// returns nothing and nothing is spent. Root from several sources (its own and The Old Hedge's)
// returns once and pays the lowest cost: aura grants combine by MIN, and of the Roots left only
// the cheapest offers.
// Fight count on the unit: its Root was used this fight.
// Health that means "full" (the core takes damage = max Health - this, never below 0).
// True when `params` is the unit's cheapest Root (the first of the cheapest, in hook order).
pub const USED: &str = "thorn_root_used";
pub const FULL: i64 = 1 << 30;
use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct Root;
pub type RootRef = Rc<RefCell<Root>>;
impl ToState for Root {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Root {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("cost", Variant::Int(Kind::Threshold as i64));
        out
    }
    fn grant_combine(&self, _param: &str) -> Combine {
        Combine::Min
    }
    fn return_offer(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        let unit = unit.unwrap();
        if unit.borrow().fight_count(USED) > 0 || !Self::_cheapest(Some(unit), params) {
            return 0;
        }
        let index = unit.borrow().side;
        let side = combat.bridge(index);
        if side.borrow_mut().heap(combat, HEAP).borrow().size() < params.borrow().num("cost") {
            return 0;
        }
        FULL
    }
    fn return_priority(&self, _params: &MechanicParamsRef) -> i64 {
        RETURN_FIRST
    }
    fn return_as_recruit(&self, _params: &MechanicParamsRef) -> bool {
        true
    }
    fn pay_return(
        &self,
        combat: &mut Combat,
        gone: &CombatUnitRef,
        back: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        back.borrow_mut().add_fight_count(USED, 1);
        let cost = params.borrow().num("cost");
        if cost > 0 {
            let index = gone.borrow().side;
            let side = combat.bridge(index);
            FightSide::heap_spend(&side, combat, HEAP, cost, Some(gone));
        }
        combat.show_status(Some(back), "thorn_root", false, Some(gone));
    }
}
impl Root {
    pub fn _cheapest(unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) -> bool {
        let mut best: Option<BoundMechanicRef> = None;
        let hooks = unit.unwrap().borrow().hooks();
        let mut index = 0;
        while index < hooks.len() {
            let bound = hooks.get(index).unwrap();
            index += 1;
            if bound.borrow().id != "thorn_root" {
                continue;
            }
            if best.as_ref().is_none_or(|best| {
                bound.borrow().params.borrow().num("cost")
                    < best.borrow().params.borrow().num("cost")
            }) {
                best = Some(bound);
            }
        }
        best.is_some_and(|best| Rc::ptr_eq(&best.borrow().params, params))
    }
}
