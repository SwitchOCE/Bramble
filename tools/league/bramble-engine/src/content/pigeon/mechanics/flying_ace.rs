//! Mirrors src/content/pigeon/mechanics/flying_ace.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef, fight_side::FightSide},
    mechanics::mechanic_params::MechanicParamsRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct FlyingAce;
const USED: &str = "pigeon_flying_ace_uses";

impl ToState for FlyingAce {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for FlyingAce {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "amount" => &(Kind::Number as i64), "limit" => &(Kind::Number as i64), }.as_dict()
    }

    fn on_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        const ID: &str = "pigeon_flying_ace";
        let Some(unit) = unit else { return };
        let limit = params.borrow().num("limit");
        if unit.borrow().fight_count(ID) < limit && combat.trigger(Some(unit), ID) {
            let (side, slot) = {
                let mut unit = unit.borrow_mut();
                unit.add_fight_count(ID, 1);
                (unit.side, unit.slot)
            };
            let side = combat.bridge(side);
            FightSide::add_renown(
                &side,
                combat,
                slot,
                params.borrow().num("amount"),
                Some(unit),
            );
            let left = limit - unit.borrow().fight_count(ID);
            combat.show_uses(Some(unit), USED, left, Some(unit));
        }
    }
}
