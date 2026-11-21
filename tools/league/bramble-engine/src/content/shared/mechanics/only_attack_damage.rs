use crate::core::combat::combat_unit::CombatUnitRef;
use crate::core::mechanics::{mechanic::*, mechanic_params::MechanicParamsRef};
use crate::{Dictionary, ToState, Variant};
#[derive(Default)]
pub struct OnlyAttackDamage;
impl ToState for OnlyAttackDamage {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl Mechanic for OnlyAttackDamage {
    fn combat_query(
        &self,
        _unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        _params: &MechanicParamsRef,
    ) -> i64 {
        if query == Q_ONLY_ATTACK_DAMAGE {
            1
        } else {
            value
        }
    }
}
