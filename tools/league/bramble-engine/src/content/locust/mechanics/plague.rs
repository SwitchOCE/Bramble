#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/plague.gd
// The Eighth Plague. After a friendly unit dies (9.7.2 step 3), deal damage to a random enemy,
// either row, equal to the number of friendly deaths this fight times `per` (1; 2 on a golden):
// the 10th death deals 10. The core counts a side's deaths as each one resolves
// (FightSide.deaths), so deaths before this unit arrived count and the second of two deaths in
// one batch reads 2; a death effect set off without a death doesn't count.

#[derive(Clone,Default)]
pub struct Plague;
pub type PlagueRef=Rc<RefCell<Plague>>;
impl ToState for Plague {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Plague {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("per",Variant::Int(Kind::Number as i64));out }
 fn after_friendly_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _dead: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/plague.gd:after_friendly_death") }
}
