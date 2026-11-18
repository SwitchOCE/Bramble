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
// Source: src/core/mechanics/keywords/divine_shield.gd
// 11.2.2 Divine Shield (example keyword): the first time this unit would take damage in a
// combat, it takes none and the shield is lost. Since no damage is dealt, it also stops
// Venomous, which stays unused (see the README's list of settled gaps).
pub const UP: &str = "divine_shield_up";
#[derive(Clone, Default)]
pub struct DivineShield;
pub type DivineShieldRef = Rc<RefCell<DivineShield>>;
impl ToState for DivineShield {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for DivineShield {
    fn on_combat_begin(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/core/mechanics/keywords/divine_shield.gd:on_combat_begin")
    }
    fn absorb_damage(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        amount: i64,
        _from_attack: bool,
        _params: &MechanicParamsRef,
    ) -> i64 {
        // TODO(port mechanics)
        todo!("port src/core/mechanics/keywords/divine_shield.gd:absorb_damage")
    }
}
