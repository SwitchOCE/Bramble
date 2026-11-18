#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/grudge_keeper.gd
// Grudge-keeper: your Knights have Grudge N. Paid by badger_grudge_pay (the biggest keeper, once
// for each Knight); this aura shows it on the Knights with no Grudge of their own, from the first
// keeper in reading order.
pub const KEEPER: &str = "badger_grudge_keeper";
use crate::content::badger::lib::badger_rules::BadgerRules as BadgerRules;
#[derive(Clone,Default)]
pub struct GrudgeKeeper;
pub type GrudgeKeeperRef=Rc<RefCell<GrudgeKeeper>>;
impl ToState for GrudgeKeeper {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for GrudgeKeeper {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("grudge",Variant::Int(Kind::Number as i64));out }
 fn has_aura(&self) -> bool { true }
 fn aura_grants(&self, view: &mut AuraContext, source_slot: i64, target_slot: i64, params: &MechanicParamsRef) -> Array<Dictionary> { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/grudge_keeper.gd:aura_grants") }
}
impl GrudgeKeeper {
 pub fn _has(def: Option<&UnitDefRef>, mechanic_id: &str) -> bool { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/grudge_keeper.gd:_has") }
}
