use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::{Dictionary, ToState, Variant};
#[derive(Default)]
pub struct HitEnemySummon;
impl ToState for HitEnemySummon {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
}
impl Mechanic for HitEnemySummon {
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
        const USES: &str = "core_weasel_uses";
        let unit = unit.unwrap();
        if entered.borrow().side == unit.borrow().side
            || entered.borrow().reservist
            || entered.borrow().is_dead()
        {
            return;
        }
        let limit = params.borrow().num("limit");
        if unit.borrow().should_die() || unit.borrow().fight_count(USES) >= limit {
            return;
        }
        if combat.trigger(Some(unit), "hit_enemy_summon") {
            unit.borrow_mut().add_fight_count(USES, 1);
            let left = limit - unit.borrow().fight_count(USES);
            combat.show_uses(Some(unit), USES, left, Some(unit));
            combat.hit(Some(unit), Some(entered), 100);
        }
    }
}
