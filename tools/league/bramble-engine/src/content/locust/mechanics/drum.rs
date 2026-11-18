#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/drum.gd
// War-drummer. Whenever this attacks (every attack, out-of-turn ones too), from the front row
// only: a unit in the slots behind it (8.2.1) that has a death effect, at random if two, has
// its death effects resolve `times` times where it stands. Nothing died: no death counts, no
// "after a friendly unit dies", no return (ruling 31). Dirge-singer doubles each (ruling 33).

#[derive(Clone,Default)]
pub struct Drum;
pub type DrumRef=Rc<RefCell<Drum>>;
impl ToState for Drum {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Drum {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn on_attack(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _defender: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/drum.gd:on_attack") }
}
