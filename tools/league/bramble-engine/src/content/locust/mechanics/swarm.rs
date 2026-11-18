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
// Source: src/content/locust/mechanics/swarm.gd
// Standing, every player (tribe.json): the Tide and the Hopper bonus as an aura from the player.
// Tide +N: every Locust on the board has +N Attack. Hopper bonus +N: every Hopper has +N/+N.
// Both are borrowed (SHARED-RULES 43): auras, never the unit's own stats.

use crate::content::locust::lib::locust::Locust;
#[derive(Clone, Default)]
pub struct Swarm;
pub type SwarmRef = Rc<RefCell<Swarm>>;
impl ToState for Swarm {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Swarm {
    fn has_aura(&self) -> bool {
        true
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> (i64, i64) {
        // TODO(port mechanics)
        todo!("port src/content/locust/mechanics/swarm.gd:aura")
    }
}
