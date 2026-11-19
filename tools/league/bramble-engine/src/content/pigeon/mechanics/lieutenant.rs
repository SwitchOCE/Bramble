//! Mirrors src/content/pigeon/mechanics/lieutenant.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef},
    mechanics::mechanic_params::MechanicParamsRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct Lieutenant;

impl ToState for Lieutenant {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Lieutenant {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "percent" => &(Kind::Number as i64), }.as_dict()
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else { return };
        let (side, slot) = {
            let unit = unit.borrow();
            (unit.side, unit.slot)
        };
        let geometry = combat.geometry.as_ref().unwrap().clone();
        let row = geometry.borrow().row_of(slot);
        let mut dealers = Vec::new();
        for slot in row.iter_live() {
            let Some(here) = combat.unit_at(side, slot) else {
                return;
            };
            if here.borrow().gone {
                return;
            }
            dealers.push(here);
        }
        if !combat.trigger(Some(unit), "pigeon_lieutenant") {
            return;
        }
        for dealer in dealers {
            let (side, slot) = {
                let dealer = dealer.borrow();
                (dealer.side, dealer.slot)
            };
            let here = combat
                .bridge(side)
                .borrow()
                .slots
                .get(slot as usize)
                .unwrap();
            let amount = (here
                .borrow()
                .renown
                .wrapping_mul(params.borrow().num("percent")) as f64
                / 100.0) as i64;
            if amount <= 0 || combat.halted() {
                continue;
            }
            let target = combat.unit_at(1 - side, geometry.borrow().across(slot));
            if let Some(target) = target
                && !target.borrow().should_die()
            {
                combat.deal_damage(Some(&dealer), Some(&target), amount, false);
            }
        }
    }
}
