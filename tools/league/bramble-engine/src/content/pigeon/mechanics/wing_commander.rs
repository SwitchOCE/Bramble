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
// Source: src/content/pigeon/mechanics/wing_commander.gd
// Wing Commander (with pigeon_sortie): Start of fight (main pass): each friendly Pigeon that has
// Sortie, this one and those a Squadron Leader gives it included, makes `attacks` out-of-turn
// attacks (9.4.12) in reading order. A golden gives two each.
pub const SORTIE: &str = "pigeon_sortie";
#[derive(Clone, Default)]
pub struct WingCommander;
pub type WingCommanderRef = Rc<RefCell<WingCommander>>;
impl ToState for WingCommander {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for WingCommander {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attacks", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/wing_commander.gd:on_start_of_combat")
    }
}
