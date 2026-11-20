//! Mirrors src/content/pigeon/mechanics/colonel.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef},
    mechanics::mechanic::Q_HAND_RENOWN_TIMES,
    mechanics::mechanic_params::MechanicParamsRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct Colonel;

impl ToState for Colonel {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Colonel {
    fn side_query(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        if unit.is_some() && query == Q_HAND_RENOWN_TIMES {
            return value.max(if params.borrow().golden { 3 } else { 2 });
        }
        value
    }
}
