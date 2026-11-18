#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/effects/death_summon.gd
// Own death effect (9.7.2 step 2): summon `count` copies of `card`, the first into this unit's
// slot (8.4.1), the rest by 8.4.2-8.4.4.

#[derive(Clone,Default)]
pub struct DeathSummon;
pub type DeathSummonRef=Rc<RefCell<DeathSummon>>;
impl ToState for DeathSummon {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for DeathSummon {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("card",Variant::Int(Kind::Text as i64));out.insert("count",Variant::Int(Kind::Number as i64));out }
 fn on_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/effects/death_summon.gd:on_death") }
 fn has_death_effect(&self) -> bool { true }
}
