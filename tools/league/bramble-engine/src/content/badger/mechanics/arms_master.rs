#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/arms_master.gd
// Master-at-Arms: when played (7.2.3), give a friendly unit on the board (any tribe, this one
// included) +N Fury for good: a badger_fury of its own that adds to the Fury it has. A plain
// copy of the unit doesn't have it. The number is this card's; a golden target doesn't double it.

use crate::content::badger::lib::badger_rules::BadgerRules as BadgerRules;
#[derive(Clone,Default)]
pub struct ArmsMaster;
pub type ArmsMasterRef=Rc<RefCell<ArmsMaster>>;
impl ToState for ArmsMaster {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for ArmsMaster {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("fury",Variant::Int(Kind::Number as i64));out }
 fn play_target(&self, _params: &MechanicParamsRef) -> Target { Target::FriendlyUnit }
 fn on_played(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, target: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/arms_master.gd:on_played") }
}
