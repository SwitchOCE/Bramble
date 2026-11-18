#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/edgewright.gd
// Edgewright: start of fight (set-up pass), your slots give double Attack this fight (golden:
// triple). The stored buffs don't change; the side reads them at that percent for the rest of the
// fight, even if the Edgewright dies (FightSide.set_slot_attack_percent). Two don't stack: the
// bigger applies. It stacks once with the give-time doubling (SHARED-RULES 13).

#[derive(Clone,Default)]
pub struct Edgewright;
pub type EdgewrightRef=Rc<RefCell<Edgewright>>;
impl ToState for Edgewright {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Edgewright {
 fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 { SOC_SETUP }
 fn on_start_of_combat(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/edgewright.gd:on_start_of_combat") }
}
