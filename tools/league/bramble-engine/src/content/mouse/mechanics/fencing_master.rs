#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/fencing_master.gd
// Fencing Master: the first time each of your Mice piles on in a fight (the Master included),
// it gains +attack Attack permanently; a Cousin keeps it for the fight. Each Master gives its
// own. Made in MouseRules.after_pile_on while the Master is on the board.

#[derive(Clone,Default)]
pub struct FencingMaster;
pub type FencingMasterRef=Rc<RefCell<FencingMaster>>;
impl ToState for FencingMaster {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for FencingMaster {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("attack",Variant::Int(Kind::Number as i64));out }
}
