#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/badger/mechanics/relic.gd
// Relic Seeker: after each fight, gain N gold for every 2 units you were outnumbered by, win or
// lose. Only one Relic Seeker pays: the one that pays most, the first in reading order on a tie.
// It was on the board in the fight, since the board doesn't change between the fight and this.
// The gold is the player's now; gold carries over, so it is spent next turn.
pub const RELIC: &str = "badger_relic";
#[derive(Clone,Default)]
pub struct Relic;
pub type RelicRef=Rc<RefCell<Relic>>;
impl ToState for Relic {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Relic {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("gold",Variant::Int(Kind::Number as i64));out }
 fn after_fight(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, report: &FightReportRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/relic.gd:after_fight") }
}
impl Relic {
 pub fn _gold(unit: Option<&UnitRef>) -> i64 { // TODO(port mechanics)
 todo!("port src/content/badger/mechanics/relic.gd:_gold") }
}
