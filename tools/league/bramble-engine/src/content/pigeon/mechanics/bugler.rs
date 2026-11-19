//! Mirrors src/content/pigeon/mechanics/bugler.gd.
use crate::content::pigeon::lib::private_call::PrivateCall;
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef},
    mechanics::mechanic_params::MechanicParamsRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct Bugler;

impl ToState for Bugler {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Bugler {
    fn param_kinds(&self) -> Dictionary {
        PrivateCall::param_kinds()
    }
    fn after_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else { return };
        PrivateCall::after_friendly_death(combat, unit, dead);
    }

    fn after_death_round(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if let Some(unit) = unit {
            PrivateCall::after_death_round(combat, unit, params, "pigeon_bugler");
        }
    }
}
