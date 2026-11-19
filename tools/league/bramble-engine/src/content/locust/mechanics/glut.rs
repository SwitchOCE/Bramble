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
// Source: src/content/locust/mechanics/glut.gd
// Granary Glutton. Whenever you sell a Locust (Hoppers too), this eats it, unless a Gorger that
// hasn't eaten this turn does; with two Gluttons the first in reading order eats. When this is
// sold itself it is off the board and eats nothing.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct Glut;
pub type GlutRef = Rc<RefCell<Glut>>;
impl ToState for Glut {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Glut {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_any_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        sold: &UnitRef,
        params: &MechanicParamsRef,
    ) {
        if unit.is_some() {
            Locust::eat(ctx, unit, sold, names::GLUT, params.borrow().num("times"));
        }
    }
}
