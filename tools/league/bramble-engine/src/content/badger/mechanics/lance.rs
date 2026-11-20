#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::unit_text::UnitText;
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/content/badger/mechanics/lance.gd
// Hedge Lancer: its first attacks take no damage while they resolve (SHARED-RULES 26).

#[derive(Clone, Default)]
pub struct Lance;
pub type LanceRef = Rc<RefCell<Lance>>;
impl ToState for Lance {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Lance {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"attacks" => &(Kind::Number as i64)}.as_dict()
    }

    fn text_params(&self, params: &MechanicParamsRef) -> Dictionary {
        let count = params.borrow().num("attacks");
        let when = if count == 1 {
            "time this attacks".to_owned()
        } else {
            format!("{count} times this attacks")
        };
        crate::state_dict! {"when_attacking" => &when}.as_dict()
    }
    fn protect_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) -> bool {
        const LANCE: &str = "badger_lance";
        let unit = unit.unwrap();
        if unit.borrow().fight_count(LANCE) >= params.borrow().num("attacks")
            || !combat.trigger(Some(unit), LANCE)
        {
            return false;
        }
        unit.borrow_mut().add_fight_count(LANCE, 1);
        true
    }
}
