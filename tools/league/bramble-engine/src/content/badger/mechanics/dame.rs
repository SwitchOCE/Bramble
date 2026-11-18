#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/dame.gd
// Dame of the Old Sett: while she is on the board, every friendly unit whose type line says
// Knight, herself included, has +N Fury and Overrun. Two Dames add up. Her Fury is borrowed:
// Sword-heir doesn't take it.

use crate::content::badger::lib::badger_rules::BadgerRules as BadgerRules;
#[derive(Clone,Default)]
pub struct Dame;
pub type DameRef=Rc<RefCell<Dame>>;
impl ToState for Dame {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Dame {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("fury",Variant::Int(Kind::Number as i64));out }
 fn has_aura(&self) -> bool { true }
 fn aura_grants(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, params: &MechanicParamsRef) -> Array<Dictionary> { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/dame.gd:aura_grants") }
 fn aura_keywords(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, _params: &MechanicParamsRef) -> Array<String> { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/dame.gd:aura_keywords") }
}
