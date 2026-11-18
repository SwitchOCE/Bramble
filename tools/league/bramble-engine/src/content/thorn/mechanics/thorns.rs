#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/thorns.gd
// Thorns N: whenever this is attacked, deal N damage to the attacker first (9.6.1 step 1). Not
// an attack and not a Hit. Thorns from several sources add up: the first Thorns on the unit
// deals the total. An attacker it kills doesn't attack (the core ends the attack). An attack
// that takes no damage takes none (the core's NO_DAMAGE). A kill is noted for Lone Hawthorn.
// FightSide.state key: this enemy unit was killed by this side's Thorns.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct Thorns;
pub type ThornsRef=Rc<RefCell<Thorns>>;
impl ToState for Thorns {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Thorns {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn on_attacked(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, attacker: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/thorns.gd:on_attacked") }
}
impl Thorns {
 pub fn kill_key(attacker: &CombatUnitRef) -> String { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/thorns.gd:kill_key") }
}
