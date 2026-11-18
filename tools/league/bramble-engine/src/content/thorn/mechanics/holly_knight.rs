#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/holly_knight.gd
// Your front-row Briars have +N Thorns for every 3 units in your Compost (Holly Knight). An
// aura, recalculated whenever the Compost or the board changes; it adds to printed Thorns and
// counts this unit too when it stands in front. Two Holly Knights add up.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct HollyKnight;
pub type HollyKnightRef=Rc<RefCell<HollyKnight>>;
impl ToState for HollyKnight {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for HollyKnight {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn has_aura(&self) -> bool { true }
 fn aura_grants(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, params: &MechanicParamsRef) -> Array<Dictionary> { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/holly_knight.gd:aura_grants") }
}
