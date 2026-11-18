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
// Source: src/content/locust/mechanics/shed.gd
// Skin-shedder. Start of fight, set-up pass (ruling 41): the units next to this (8.2.2, same
// row, any tribe) get `charges` more Molt charges for this fight (one; two on a golden); one
// without Molt is given it. This unit doesn't Molt itself.

use crate::content::locust::lib::locust::Locust;
#[derive(Clone, Default)]
pub struct Shed;
pub type ShedRef = Rc<RefCell<Shed>>;
impl ToState for Shed {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Shed {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("charges", Variant::Int(Kind::Number as i64));
        out
    }
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/locust/mechanics/shed.gd:on_start_of_combat")
    }
}
