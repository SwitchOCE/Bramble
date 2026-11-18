#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/effects/rally_gain.gd
// Whenever this attacks (9.6.1 step 2, like HSBG's Rally): gain +attack this combat.

#[derive(Clone,Default)]
pub struct RallyGain;
pub type RallyGainRef=Rc<RefCell<RallyGain>>;
impl ToState for RallyGain {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for RallyGain {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out }
 fn on_attack(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _defender: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/effects/rally_gain.gd:on_attack") }
}
