#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/catapult.gd
// Spoon Catapult: instead of attacking, Hit the enemy with the least Health. That uses its turn
// and counts toward the attack limit. Golden, or with "attacks twice" (Kettle-drummer), it Hits
// twice, choosing again. Told to attack out of turn, it makes an ordinary attack (the core's
// attack_now doesn't ask instead_of_attack).

use crate::content::mouse::lib::mouse_rules::MouseRules as MouseRules;
#[derive(Clone,Default)]
pub struct Catapult;
pub type CatapultRef=Rc<RefCell<Catapult>>;
impl ToState for Catapult {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Catapult {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn instead_of_attack(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) -> bool { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/catapult.gd:instead_of_attack") }
}
