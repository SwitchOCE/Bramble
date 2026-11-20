#![allow(unused_imports, unused_variables)]
use crate::core::combat::fight_side::FightSide;
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
// Swarm-lord. Each friendly Locust death in a fight raises the Tide. This includes Hoppers
// and each death of a returning Locust.
use crate::content::locust::lib::locust::{self as names, Locust};
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
        let Some(owner) = unit else {
            return;
        };
        if !dead
            .borrow()
            .def
            .as_ref()
            .unwrap()
            .borrow()
            .has_tribe(names::TRIBE)
        {
            return;
        }
        if combat.trigger(unit, "locust_swarm_lord") {
            let side_index = owner.borrow().side;
            let side = combat.bridge(side_index);
            FightSide::add_counter(
                &side,
                combat,
                names::TIDE,
                params.borrow().num("amount"),
                unit,
            );
        }
    }
}
