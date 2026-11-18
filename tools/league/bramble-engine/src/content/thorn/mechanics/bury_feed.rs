#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/bury_feed.gd
// Bury: Give your Briars +N/+N permanently (Leafmould Carter, Old Mother Midden): every Briar on
// the board, this one included.

#[derive(Clone,Default)]
pub struct BuryFeed;
pub type BuryFeedRef=Rc<RefCell<BuryFeed>>;
impl ToState for BuryFeed {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for BuryFeed {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn has_ability(&self)->bool {true}
 fn ability_target(&self,_params:&MechanicParamsRef)->Target{Target::ShopUnit}
 fn on_ability(&self,ctx:&mut RecruitContext,unit:Option<&UnitRef>,_target:Option<&UnitRef>,params:&MechanicParamsRef){
// TODO(port mechanics): inherited BuryBase implementation, dispatching this bury_effect.
todo!("port src/content/thorn/lib/bury_base.gd:on_ability")
}
}
impl BuryFeed {
 pub fn mechanic_id(&self) -> String { "thorn_bury_feed".to_owned() }
 pub fn bury_effect(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/bury_feed.gd:bury_effect") }
}
