use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::{Dictionary, ToState, Variant};
#[derive(Default)]
pub struct StingKiller;
impl ToState for StingKiller {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl Mechanic for StingKiller {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"damage" => &(Kind::Number as i64)}.as_dict()
    }
    fn has_death_effect(&self) -> bool {
        true
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if let Some(killer) = combat.killer_of(unit.unwrap())
            && !killer.borrow().is_dead()
            && combat.trigger(unit, "sting_killer")
        {
            combat.deal_damage(unit, Some(&killer), params.borrow().num("damage"), false);
        }
    }
}
