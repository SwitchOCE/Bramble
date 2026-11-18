#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/compost.gd
// The Compost (standing, every player): a Bought unit sold goes in, one entry for each Bought
// copy in it (a golden adds one for each); Created units add nothing. It also gives an Elder
// Mother copy its bonus when it lands (a summon, at once or after waiting), even after the Elder
// Mother has died. on_fight_enter hears summons only, never a return, which is all this needs.

use crate::content::thorn::lib::compost_rules::CompostRules as CompostLib;
#[derive(Clone,Default)]
pub struct Compost;
pub type CompostRef=Rc<RefCell<Compost>>;
impl ToState for Compost {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Compost {
 fn on_any_sold(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, sold: &UnitRef, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/compost.gd:on_any_sold") }
 fn on_fight_enter(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, entered: &CombatUnitRef, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/compost.gd:on_fight_enter") }
}
