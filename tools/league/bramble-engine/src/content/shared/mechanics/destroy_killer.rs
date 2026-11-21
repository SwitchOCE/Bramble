use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{mechanic::*, mechanic_params::MechanicParamsRef};
use crate::{Dictionary, ToState, Variant};
#[derive(Default)]
pub struct DestroyKiller;
impl ToState for DestroyKiller {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl Mechanic for DestroyKiller {
    fn has_death_effect(&self) -> bool {
        true
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        if let Some(killer) = combat.killer_of(unit.unwrap())
            && !killer.borrow().is_dead()
            && combat.trigger(unit, "destroy_killer")
        {
            combat.destroy(unit, Some(&killer));
        }
    }
}
