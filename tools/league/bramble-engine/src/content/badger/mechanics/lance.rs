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
// Hedge Lancer: Start of fight (main pass): this attacks immediately and takes no damage from
// anything while that attack resolves (SHARED-RULES 26). Its later attacks are normal.

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
        crate::state_dict! {"attack_repeats" => &UnitText::repeat_suffix(params.borrow().num("attacks"))}.as_dict()
    }

    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if combat.trigger(unit, "badger_lance") {
            for _ in 0..params.borrow().num("attacks") {
                if !combat.attack_now(unit, None, true, None) {
                    break;
                }
            }
        }
    }
}
