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
// Source: src/content/pigeon/mechanics/stiff_upper_lip.gd
// Stiff Upper Lip: the first time damage would kill this each fight, it stays on 1 Health. Any
// kind of damage; not a death and not a return. Destroy effects don't go through damage, so they
// ignore it. Once a fight for each unit, whatever gives it: a fight count, which a return carries
// (SHARED-RULES 21), so a unit that returns as it stands keeps it used. A plain-copy return has
// no Medals, so it is not Decorated and has none.
pub const USED: &str = "pigeon_stiff_upper_lip_used";
#[derive(Clone, Default)]
pub struct StiffUpperLip;
pub type StiffUpperLipRef = Rc<RefCell<StiffUpperLip>>;
impl ToState for StiffUpperLip {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for StiffUpperLip {
    fn absorb_damage(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        amount: i64,
        _from_attack: bool,
        _params: &MechanicParamsRef,
    ) -> i64 {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/stiff_upper_lip.gd:absorb_damage")
    }
}
