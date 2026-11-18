#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/content/mouse/mechanics/pile_on.gd
// Pile on: whenever a neighbour (next to, in front of or behind: up to four, 8.2.3; any tribe)
// attacks, this hits the target first. Every pile-on hit lands together once all friends have
// heard the attack (Combat.hit while joining), so a later piler still lands when an earlier one's
// hit was enough; a target they kill ends the attack before the exchange (9.6.1), and the kill is
// the piler's. A unit with 0 Attack doesn't pile on. Dame Bodkin's percent applies.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct PileOn;
pub type PileOnRef = Rc<RefCell<PileOn>>;
impl ToState for PileOn {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for PileOn {
    fn on_friendly_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/mouse/mechanics/pile_on.gd:on_friendly_attack")
    }
}
