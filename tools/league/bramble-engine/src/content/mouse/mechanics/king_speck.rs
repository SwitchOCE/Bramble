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
// Source: src/content/mouse/mechanics/king_speck.gd
// King Speck: whenever this attacks, fill your empty slots with Cousins, one at a time outward
// from the King (8.4.2), before any Pile on. Golden: golden Cousins (4/4).

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct KingSpeck;
pub type KingSpeckRef = Rc<RefCell<KingSpeck>>;
impl ToState for KingSpeck {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for KingSpeck {
    fn on_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if combat.trigger(unit, "mouse_king_speck") {
            let count = combat.geometry.as_ref().unwrap().borrow().slot_count;
            MouseRules::summon_cousins(combat, unit, count, params.borrow().golden);
        }
    }
}
