//! Mirrors src/content/pigeon/mechanics/colour_ensign.gd.
use crate::Array;
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef, fight_side::FightSide},
    mechanics::mechanic::SOC_SETUP,
    mechanics::mechanic_params::MechanicParamsRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct ColourEnsign;

impl ToState for ColourEnsign {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for ColourEnsign {
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else { return };
        let (side, slot, golden) = {
            let unit = unit.borrow();
            (unit.side, unit.slot, unit.golden)
        };
        let side = combat.bridge(side);
        let slots = side.borrow().slots.clone();
        let highest = slots
            .iter_live()
            .map(|slot| slot.borrow().renown)
            .fold(0, i64::max);
        let targets = Array::from([slot]);
        if golden {
            targets.borrow_mut().extend(
                combat
                    .geometry
                    .as_ref()
                    .unwrap()
                    .borrow()
                    .adjacent(slot)
                    .iter_live(),
            );
        }
        let changes: Vec<_> = targets
            .iter_live()
            .filter(|slot| slots.get(*slot as usize).unwrap().borrow().renown < highest)
            .collect();
        if changes.is_empty() || !combat.trigger(Some(unit), "pigeon_colour_ensign") {
            return;
        }
        for slot in changes {
            FightSide::copy_renown(&side, combat, slot, highest, Some(unit));
        }
    }
}
