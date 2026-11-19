//! Mirrors src/content/mouse/mechanics/hand_me_down.gd.
use crate::content::mouse::lib::mouse_rules::MouseRules;
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::MechanicParamsRef};
use crate::{Dictionary, ToState, Variant};

/// Hand-me-down (11.7.12–11.7.13) is a death effect (9.7.2 step 2).
/// When triggered on a living unit, it still passes to the nearest other Mouse.
pub struct HandMeDown;

impl ToState for HandMeDown {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for HandMeDown {
    fn has_death_effect(&self) -> bool {
        true
    }

    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        if let Some(unit) = unit {
            MouseRules::hand_me_down(combat, unit);
        }
    }
}
