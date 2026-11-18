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
// Source: src/content/pigeon/mechanics/colour_ensign.gd
// Colour Ensign: Start of fight (set-up pass): this slot copies your strongest slot's buff
// (Attack plus Health; first in reading order on a tie), for this fight, if it is bigger than
// its own. A copy is not a buff given (FightSide.slot_set), so the Sergeant Major doesn't double
// it; it stays on the slot for the fight after the Ensign dies. Golden: the slots next to it
// copy it too.

#[derive(Clone, Default)]
pub struct ColourEnsign;
pub type ColourEnsignRef = Rc<RefCell<ColourEnsign>>;
impl ToState for ColourEnsign {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for ColourEnsign {
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/colour_ensign.gd:on_start_of_combat")
    }
}
