#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/sexton.gd
// Sett Sexton: after another friendly Badger dies (9.7.2 step 3), every friendly Badger on the
// board at that moment, this one included, has +N Fury for the rest of this fight (a Badger with
// no Fury now has Fury N). Badgers that arrive later don't get it; the outnumbered count doesn't
// change.

use crate::content::badger::lib::badger_rules::BadgerRules as BadgerRules;
#[derive(Clone,Default)]
pub struct Sexton;
pub type SextonRef=Rc<RefCell<Sexton>>;
impl ToState for Sexton {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Sexton {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("fury",Variant::Int(Kind::Number as i64));out }
 fn after_friendly_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, dead: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/sexton.gd:after_friendly_death") }
}
