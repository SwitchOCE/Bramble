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
// Source: src/core/mechanics/effects/attacked_gain.gd
// When this is attacked (9.6.1 step 1): gain +health this combat, before damage.

#[derive(Clone, Default)]
pub struct AttackedGain;
pub type AttackedGainRef = Rc<RefCell<AttackedGain>>;
impl ToState for AttackedGain {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for AttackedGain {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("health", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_attacked(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/core/mechanics/effects/attacked_gain.gd:on_attacked")
    }
}
