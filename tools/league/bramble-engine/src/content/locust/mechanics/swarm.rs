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

use crate::content::locust::lib::locust::{self as names, Locust};
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
        if source_slot != -1 {
            return (0, 0);
        }
        let Some(def) = view.def_at(target_slot) else {
            return (0, 0);
        };
        let mut gain = (0_i32, 0_i32);
        if def.borrow().has_tribe(names::TRIBE) {
            gain.0 = gain.0.wrapping_add(view.counter(names::TIDE) as i32);
        }
        if def.borrow().id == names::HOPPER {
            let bonus = view.counter(names::HOPPER_BONUS) as i32;
            gain.0 = gain.0.wrapping_add(bonus);
            gain.1 = gain.1.wrapping_add(bonus);
        }
        (gain.0 as i64, gain.1 as i64)
    }
}
