#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/hoppers_on_death.gd
// Green Recruit. When this dies, summon `count` Hoppers: the first into its slot (8.4.1), the
// rest nearest (8.4.2); with no room they wait. Set off without a death (War-drummer) its slot
// is taken, so all go nearest or wait. Eaten in the shop they land on the recruit board.

use crate::content::locust::lib::locust::Locust as Locust;
#[derive(Clone,Default)]
pub struct HoppersOnDeath;
pub type HoppersOnDeathRef=Rc<RefCell<HoppersOnDeath>>;
impl ToState for HoppersOnDeath {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for HoppersOnDeath {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("count",Variant::Int(Kind::Number as i64));out }
 fn has_death_effect(&self) -> bool { true }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/hoppers_on_death.gd:on_death") }
 fn on_recruit_death(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/hoppers_on_death.gd:on_recruit_death") }
}
