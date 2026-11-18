#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/campaigner.gd
// Old Campaigner: after each fight, earn `medals` Medals, or `survived` if its fight copy was
// alive at the end. Decorated (3+ Medals): Stiff Upper Lip, given to itself as an aura so it
// follows the Medal count in both phases.

use crate::content::pigeon::lib::medals::Medals as Medals;
#[derive(Clone,Default)]
pub struct Campaigner;
pub type CampaignerRef=Rc<RefCell<Campaigner>>;
impl ToState for Campaigner {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Campaigner {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("medals",Variant::Int(Kind::Number as i64));out.insert("survived",Variant::Int(Kind::Number as i64));out }
 fn after_fight(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, report: &FightReportRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/campaigner.gd:after_fight") }
 fn has_aura(&self) -> bool { true }
 fn aura_keywords(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<String> { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/campaigner.gd:aura_keywords") }
}
