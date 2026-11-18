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
// Source: src/content/mouse/mechanics/bodkin.gd
// Dame Bodkin: while she is on the board, every pile-on hit by your units deals double damage
// (golden: three times). Other Hits are not doubled. Two don't stack: the bigger applies.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct Bodkin;
pub type BodkinRef = Rc<RefCell<Bodkin>>;
impl ToState for Bodkin {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Bodkin {
    fn side_query(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        // TODO(port mechanics)
        todo!("port src/content/mouse/mechanics/bodkin.gd:side_query")
    }
}
