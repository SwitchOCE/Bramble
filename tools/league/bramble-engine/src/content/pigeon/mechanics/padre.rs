#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/padre.gd
// Padre: after a friendly unit dies (9.7.2 step 3), give the slot it died in +amount/+amount
// permanently: on the real slot as well as in the fight (SHARED-RULES 38). `limit` a fight, a
// fight count that carries across a return (SHARED-RULES 21), shown as uses left. Only while
// the Padre is alive (the core skips gone listeners).
pub const USED: &str = "pigeon_padre_uses";
#[derive(Clone,Default)]
pub struct Padre;
pub type PadreRef=Rc<RefCell<Padre>>;
impl ToState for Padre {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Padre {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out.insert("limit",Variant::Int(Kind::Threshold as i64));out }
 fn after_friendly_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, dead: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/padre.gd:after_friendly_death") }
}
