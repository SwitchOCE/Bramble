//! Mirrors src/content/pigeon/mechanics/air_marshal.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef},
    mechanics::mechanic_params::{Kind, MechanicParamsRef},
};
use crate::{Dictionary, ToState, Variant};

pub struct AirMarshal;
const USED: &str = "pigeon_air_marshal_uses";

impl ToState for AirMarshal {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for AirMarshal {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"limit" => &(Kind::Number as i64)}.as_dict()
    }
    fn on_fight_enter(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        entered: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        const ID: &str = "pigeon_air_marshal";
        let Some(unit) = unit else { return };
        let limit = params.borrow().num("limit");
        {
            let entered = entered.borrow();
            if entered.side != unit.borrow().side
                || !entered.reservist
                || entered.gone
                || entered.should_die()
            {
                return;
            }
        }
        if unit.borrow().fight_count(ID) < limit && combat.trigger(Some(unit), ID) {
            unit.borrow_mut().add_fight_count(ID, 1);
            let left = limit - unit.borrow().fight_count(ID);
            let show_uses = |combat: &mut Combat| {
                combat.show_uses(Some(unit), USED, left, Some(unit));
            };
            if !combat.attack_now(Some(entered), None, false, Some(&show_uses)) {
                unit.borrow_mut().add_fight_count(ID, -1);
            }
        }
    }
}
