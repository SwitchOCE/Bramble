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
// Source: src/content/locust/mechanics/swarm_lord.gd
// Swarm-lord. A death counter (9.7.4): at every `every`th friendly Locust death in a fight
// (Hoppers are Locusts; a returning Locust counts each death), Tide +`amount`. Eaten or drummed
// units didn't die and don't count. The count is a fight count, so a Swarm-lord that returns
// (a Skin-shedder's Molt) keeps it.
pub const SEEN: &str = "locust_swarm_lord_seen";
use crate::content::locust::lib::locust::Locust;
#[derive(Clone, Default)]
pub struct SwarmLord;
pub type SwarmLordRef = Rc<RefCell<SwarmLord>>;
impl ToState for SwarmLord {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for SwarmLord {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("every", Variant::Int(Kind::Threshold as i64));
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/locust/mechanics/swarm_lord.gd:on_friendly_death")
    }
}
