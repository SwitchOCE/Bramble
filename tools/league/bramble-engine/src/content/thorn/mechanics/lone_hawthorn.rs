#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/thorn/mechanics/lone_hawthorn.gd
// Enemies your Thorns kill go into your Compost (Lone Hawthorn). While this is on the board, an
// enemy killed by Thorns damage from any of your units adds an entry for its card, plain and at
// its own tier, if that enemy was Bought. Tokens and other Created units add nothing. With two
// Lone Hawthorns a kill still adds one entry.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
use crate::content::thorn::mechanics::thorns::Thorns as Thorns;
#[derive(Clone,Default)]
pub struct LoneHawthorn;
pub type LoneHawthornRef=Rc<RefCell<LoneHawthorn>>;
impl ToState for LoneHawthorn {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for LoneHawthorn {
 fn on_any_death(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, dead: &CombatUnitRef, _params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/thorn/mechanics/lone_hawthorn.gd:on_any_death") }
}
