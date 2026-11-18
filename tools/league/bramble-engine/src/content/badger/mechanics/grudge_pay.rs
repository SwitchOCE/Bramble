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
// Source: src/content/badger/mechanics/grudge_pay.gd
// Standing, hidden: Grudge after each fight, win or lose, alive or dead. Each unit on the board
// gains +N/+N x the fight's count, N being the biggest of its own Grudge and, for a Knight,
// the biggest Grudge-keeper's on the board. Never twice for one unit.
// The biggest `grudge` among the unit's own mechanics with this id. Aura copies aren't
// counted: the Grudge a keeper shows on a Knight is read from the keeper itself.
pub const KEEPER: &str = "badger_grudge_keeper";
use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct GrudgePay;
pub type GrudgePayRef = Rc<RefCell<GrudgePay>>;
impl ToState for GrudgePay {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for GrudgePay {
    fn after_fight(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: &FightReportRef,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/grudge_pay.gd:after_fight")
    }
}
impl GrudgePay {
    pub fn _biggest(unit: Option<&UnitRef>, mechanic_id: &str) -> i64 {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/grudge_pay.gd:_biggest")
    }
}
