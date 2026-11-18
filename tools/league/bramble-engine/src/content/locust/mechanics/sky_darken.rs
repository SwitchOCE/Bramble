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
// Source: src/content/locust/mechanics/sky_darken.gd
// Sky-darkener. Start of fight (main pass): summon `count` Hoppers in the empty slots nearest
// this unit (8.4.2); the rest wait.

use crate::content::locust::lib::locust::Locust;
#[derive(Clone, Default)]
pub struct SkyDarken;
pub type SkyDarkenRef = Rc<RefCell<SkyDarken>>;
impl ToState for SkyDarken {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for SkyDarken {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("count", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/locust/mechanics/sky_darken.gd:on_start_of_combat")
    }
}
