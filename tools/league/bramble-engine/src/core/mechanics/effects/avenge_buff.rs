#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/core/mechanics/effects/avenge_buff.gd
// A death counter (9.7.4, like HSBG's Avenge): each time `every` friendly units have died this
// combat, give all friendly units +attack/+health this combat. `every` is a threshold, so a
// golden copy keeps it (7.3.5).
pub const COUNT: &str = "avenge_count";
#[derive(Clone,Default)]
pub struct AvengeBuff;
pub type AvengeBuffRef=Rc<RefCell<AvengeBuff>>;
impl ToState for AvengeBuff {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for AvengeBuff {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("every",Variant::Int(Kind::Threshold as i64));out.insert("attack",Variant::Int(Kind::Number as i64));out.insert("health",Variant::Int(Kind::Number as i64));out }
 fn on_friendly_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _dead: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/core/mechanics/effects/avenge_buff.gd:on_friendly_death") }
}
