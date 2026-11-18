#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/glut.gd
// Granary Glutton. Whenever you sell a Locust (Hoppers too), this eats it, unless a Gorger that
// hasn't eaten this turn does; with two Gluttons the first in reading order eats. When this is
// sold itself it is off the board and eats nothing.

use crate::content::locust::lib::locust::Locust as Locust;
#[derive(Clone,Default)]
pub struct Glut;
pub type GlutRef=Rc<RefCell<Glut>>;
impl ToState for Glut {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Glut {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn on_any_sold(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, sold: &UnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/glut.gd:on_any_sold") }
}
