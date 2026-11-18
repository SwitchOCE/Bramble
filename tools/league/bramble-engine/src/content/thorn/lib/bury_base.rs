#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/lib/bury_base.gd
// Bury (SHARED-RULES, Briars): once a turn for each Bury unit on the board, a shop unit (not a
// spell) leaves the shop, its pool copy goes back (5.3.7), an entry for it goes into the
// Compost, then the unit's effect resolves, as many times as "Your Bury effects happen" says
// (Old Mother Midden). The thorn_bury_* mechanics extend this and write bury_effect.
// Rules.ask query: how many times a Bury's effect resolves (base 1).
// The mechanic's id, for its trigger.
// What follows the Bury.
pub const Q_BURY_TIMES: &str = "thorn_bury_times";
use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct BuryBase;
pub type BuryBaseRef=Rc<RefCell<BuryBase>>;
impl ToState for BuryBase {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for BuryBase {
 fn has_ability(&self) -> bool { true }
 fn ability_target(&self, _params: &MechanicParamsRef) -> Target { Target::ShopUnit }
 fn on_ability(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, _target: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/lib/bury_base.gd:on_ability") }
}
impl BuryBase {
 pub fn mechanic_id(&self) -> String { "thorn_bury".to_owned() }
 pub fn bury_effect(&self, _ctx: &mut RecruitContext, _unit: Option<&UnitRef>, _params: &MechanicParamsRef) { // TODO(port mechanics): the base implementation is intentionally a no-op.
 }
}
