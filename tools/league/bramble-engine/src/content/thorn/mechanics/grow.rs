#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/grow.gd
// Grow N: Start of fight (main pass): gain +N/+N for every 2 units in your Compost, this fight.
// Grow from several sources adds up before the trigger: the first Grow on the unit gains the
// total. Units that arrive later don't Grow (the core runs only units there when it began).

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone,Default)]
pub struct Grow;
pub type GrowRef=Rc<RefCell<Grow>>;
impl ToState for Grow {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Grow {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("amount",Variant::Int(Kind::Number as i64));out }
 fn on_start_of_combat(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/grow.gd:on_start_of_combat") }
}
