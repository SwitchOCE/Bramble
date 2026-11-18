#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/pigeon/mechanics/bugler.gd
// Bugler: after a friendly Pigeon joins the fight (summoned, or stepping in from Reserve; a
// return is its own event and is not heard here, SHARED-RULES 22), give every friendly Pigeon on
// the board +amount/+amount for this fight, the new one included.

#[derive(Clone,Default)]
pub struct Bugler;
pub type BuglerRef=Rc<RefCell<Bugler>>;
impl ToState for Bugler {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Bugler {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn on_fight_enter(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, entered: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/pigeon/mechanics/bugler.gd:on_fight_enter") }
}
