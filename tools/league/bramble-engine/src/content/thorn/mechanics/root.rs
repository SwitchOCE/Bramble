#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/root.gd
// Root N: the first time this dies each fight, spend N Compost to return it (9.7.2 step 4),
// through the core's return protocol. Once a fight for each unit (a fight count, carried across
// any return), not a choice. It offers when the Compost holds N entries; the core picks Root
// before a Molt (RETURN_FIRST), so a unit with both uses Molt only when the Compost can't pay
// or its Root is used. It comes back as it stands on the recruit board at full Health; a unit
// with no recruit-board self (a token, a copy) comes back plain. With no free slot the core
// returns nothing and nothing is spent. Root from several sources (its own and The Old Hedge's)
// returns once and pays the lowest cost: aura grants combine by MIN, and of the Roots left only
// the cheapest offers.
// Fight count on the unit: its Root was used this fight.
// Health that means "full" (the core takes damage = max Health - this, never below 0).
// True when `params` is the unit's cheapest Root (the first of the cheapest, in hook order).
pub const USED: &str = "thorn_root_used";
pub const FULL: i64 = 1 << 30;
use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct Root;
pub type RootRef=Rc<RefCell<Root>>;
impl ToState for Root {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Root {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("cost",Variant::Int(Kind::Threshold as i64));out }
 fn grant_combine(&self, _param: &str) -> Combine { Combine::Min }
 fn return_offer(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) -> i64 { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/root.gd:return_offer") }
 fn return_priority(&self, _params: &MechanicParamsRef) -> i64 { RETURN_FIRST }
 fn return_as_recruit(&self, _params: &MechanicParamsRef) -> bool { true }
 fn pay_return(&self, combat: &mut Combat, gone: &CombatUnitRef, back: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/root.gd:pay_return") }
}
impl Root {
 pub fn _cheapest(unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) -> bool { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/root.gd:_cheapest") }
}
