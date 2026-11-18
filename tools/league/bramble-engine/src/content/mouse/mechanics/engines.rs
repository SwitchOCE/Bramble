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
// Source: src/content/mouse/mechanics/engines.gd
// Master of Engines: start of fight (main pass), each friendly back-row unit (B1, B2, B3, any
// tribe, the Master too) Hits the enemy with the least Health with its own Attack as it stands,
// choosing again each time; `times` Hits each (golden: twice). A Needle Pikeman Hits too.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct Engines;
pub type EnginesRef = Rc<RefCell<Engines>>;
impl ToState for Engines {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Engines {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/mouse/mechanics/engines.gd:on_start_of_combat")
    }
}
