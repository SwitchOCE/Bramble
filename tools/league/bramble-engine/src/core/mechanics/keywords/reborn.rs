#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/core/mechanics/keywords/reborn.gd
// 11.2.4 Reborn (example keyword): the first time this unit dies in a combat, it returns with
// 1 Health as a fresh copy (9.8.2) and can't return again that combat. Through the return
// protocol, as a plain return (a Molt or Root on the same unit is asked the same way).

#[derive(Clone, Default)]
pub struct Reborn;
pub type RebornRef = Rc<RefCell<Reborn>>;
impl ToState for Reborn {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Reborn {
    fn return_offer(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) -> i64 {
        // TODO(port mechanics)
        todo!("port src/core/mechanics/keywords/reborn.gd:return_offer")
    }
    fn pay_return(
        &self,
        combat: &mut Combat,
        gone: &CombatUnitRef,
        back: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/core/mechanics/keywords/reborn.gd:pay_return")
    }
}
