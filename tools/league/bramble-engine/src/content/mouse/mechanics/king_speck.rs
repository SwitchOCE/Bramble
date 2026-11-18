#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/king_speck.gd
// King Speck: whenever this attacks, fill your empty slots with Cousins, one at a time outward
// from the King (8.4.2), before any Pile on. Golden: golden Cousins (4/4).

use crate::content::mouse::lib::mouse_rules::MouseRules as MouseRules;
#[derive(Clone,Default)]
pub struct KingSpeck;
pub type KingSpeckRef=Rc<RefCell<KingSpeck>>;
impl ToState for KingSpeck {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for KingSpeck {
 fn on_attack(&self, combat: &mut Combat, unit: Option<&CombatUnitRef>, _defender: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/mechanics/king_speck.gd:on_attack") }
}
