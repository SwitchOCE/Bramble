#![allow(unused_imports, unused_variables)]
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
// Source: src/content/thorn/lib/compost_rules.gd
// The Briars' shared rules (docs/ideation-track-2/tribes/thorn/units.json "rules"), used by the
// thorn mechanics. Not a mechanic: it sits outside mechanics/ so the loader doesn't register it.
// Stateless. The core marks which Compost entries were copied this fight
// (FightSide.heap_use_highest); Root's once a fight is a fight count (root.gd).
// The Compost: one heap on each player for the whole game.
// CombatUnit.state on an Elder Mother copy: +N/+N for each Compost entry when it lands.
// True when `params` belongs to the first bound mechanic with this id on the unit (own text
// first, then aura grants). Keywords that add up (Thorns, Grow) act once, from the first.
// The sum of one parameter over every bound mechanic with this id (Thorns 2 + Thorns 6).
// True when a side has an empty slot for a summon (a dying unit still holds its slot until the
// death check, as the core counts it).
// An Elder Mother copy that just landed gains +N/+N for each Compost entry, once.
// The Briars on a recruit board, in reading order.
pub const HEAP: &str = "thorn_compost";
pub const BRIAR: &str = "Briar";
pub const ELDER_PER: &str = "thorn_elder_per";
#[derive(Clone, Default)]
pub struct CompostRules;
pub type CompostRulesRef = Rc<RefCell<CompostRules>>;
impl ToState for CompostRules {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl CompostRules {
    pub fn is_first(
        hooks: &Array<BoundMechanicRef>,
        mechanic_id: &str,
        params: &MechanicParamsRef,
    ) -> bool {
        let mut index = 0;
        while index < hooks.len() {
            let bound = hooks.get(index).unwrap();
            index += 1;
            if bound.borrow().id == mechanic_id {
                return Rc::ptr_eq(&bound.borrow().params, params);
            }
        }
        false
    }
    pub fn total(hooks: &Array<BoundMechanicRef>, mechanic_id: &str, param: &str) -> i64 {
        let mut sum = 0;
        let mut index = 0;
        while index < hooks.len() {
            let bound = hooks.get(index).unwrap();
            index += 1;
            if bound.borrow().id == mechanic_id {
                sum += bound.borrow().params.borrow().num(param);
            }
        }
        sum
    }
    pub fn has_room(combat: &mut Combat, side_index: i64) -> bool {
        let slot_count = combat.geometry.as_ref().unwrap().borrow().slot_count;
        for slot in 0..slot_count {
            if combat.unit_at(side_index, slot).is_none() {
                return true;
            }
        }
        false
    }
    pub fn elder_bonus(combat: &mut Combat, entered: &CombatUnitRef) {
        let per = entered.borrow().state_int(ELDER_PER);
        if per <= 0 {
            return;
        }
        entered.borrow_mut().set_state(ELDER_PER, 0);
        let index = entered.borrow().side;
        let side = combat.bridge(index);
        let size = side.borrow_mut().heap(combat, HEAP).borrow().size();
        if size > 0 && combat.trigger(Some(entered), "thorn_elder_mother") {
            combat.buff(Some(entered), per * size, per * size, None, false);
        }
    }
    pub fn briars(player: Option<&PlayerStateRef>) -> Array<UnitRef> {
        let out = Array::new();
        let units = player.unwrap().borrow().board_units();
        let mut index = 0;
        while index < units.len() {
            let unit = units.get(index).unwrap();
            index += 1;
            if unit
                .borrow()
                .def
                .as_ref()
                .unwrap()
                .borrow()
                .has_tribe(BRIAR)
            {
                out.push(unit);
            }
        }
        out
    }
}
