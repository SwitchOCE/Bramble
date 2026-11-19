//! Mirrors src/content/pigeon/lib/private_call.gd.
use crate::Dictionary;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef},
    mechanics::{
        mechanic::Q_FILL_FIRST,
        mechanic_params::{Kind, MechanicParamsRef},
    },
};

pub struct PrivateCall;

impl PrivateCall {
    pub fn param_kinds() -> Dictionary {
        crate::state_dict! {
            "limit" => &(Kind::Threshold as i64),
            "golden_limit" => &(Kind::Threshold as i64),
        }
        .as_dict()
    }

    pub fn limit(params: &MechanicParamsRef) -> i64 {
        let params = params.borrow();
        params.num(if params.golden {
            "golden_limit"
        } else {
            "limit"
        })
    }

    pub fn after_friendly_death(combat: &mut Combat, unit: &CombatUnitRef, dead: &CombatUnitRef) {
        let key = unit.borrow().uid.to_string();
        let arrivals = combat.arrivals.as_ref().unwrap().borrow();
        let slots = arrivals
            .witnessed
            .borrow()
            .get(&key)
            .cloned()
            .unwrap_or_default();
        slots.push(dead.borrow().slot);
        arrivals.witnessed.borrow_mut().insert(key, slots);
    }

    pub fn after_death_round(
        combat: &mut Combat,
        unit: &CombatUnitRef,
        params: &MechanicParamsRef,
        id: &str,
    ) {
        let (key, side) = {
            let unit = unit.borrow();
            (unit.uid.to_string(), unit.side)
        };
        let slots = combat
            .arrivals
            .as_ref()
            .unwrap()
            .borrow()
            .witnessed
            .borrow_mut()
            .shift_remove(&key)
            .unwrap_or_default();
        let limit = Self::limit(params);
        let post = combat.side_query(side, Q_FILL_FIRST, -1);
        let index = slots.borrow().iter().position(|slot| *slot == post);
        if let Some(index) = index {
            let mut slots = slots.borrow_mut();
            slots.remove(index);
            slots.insert(0, post);
        }
        for slot in slots.iter_live() {
            {
                let unit = unit.borrow();
                if unit.gone
                    || unit.should_die()
                    || combat.halted()
                    || unit.fight_count(id) >= limit
                {
                    return;
                }
            }
            if combat.unit_at(side, slot).is_none() && combat.trigger(Some(unit), id) {
                unit.borrow_mut().add_fight_count(id, 1);
                combat.step_in(side, "private", slot, Some(unit), false);
            }
        }
    }
}
