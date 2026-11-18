#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/glean.gd
// Gleaner. After a friendly unit dies (9.7.2 step 3, not its own), deal `amount` damage to the
// enemy with the most Health left, either row; a tie goes to the first in reading order.

#[derive(Clone,Default)]
pub struct Glean;
pub type GleanRef=Rc<RefCell<Glean>>;
impl ToState for Glean {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Glean {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn after_friendly_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _dead: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/glean.gd:after_friendly_death") }
}
