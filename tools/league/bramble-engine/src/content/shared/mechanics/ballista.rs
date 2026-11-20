use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::{Dictionary, ToState, Variant};
#[derive(Default)]
pub struct Ballista;
impl ToState for Ballista {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl Mechanic for Ballista {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"times" => &(Kind::Number as i64)}.as_dict()
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.unwrap();
        for i in 0..params.borrow().num("times") {
            let Some(target) = combat.weakest_enemy(Some(unit)) else {
                return;
            };
            if unit.borrow().attack() <= 0 || combat.halted() {
                return;
            }
            if i == 0 && !combat.trigger(Some(unit), "ballista") {
                return;
            }
            combat.hit(Some(unit), Some(&target), 100);
        }
    }
}
