#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/locust/mechanics/gorge.gd
// Gorger. The first time you sell a unit each turn (any tribe), this eats it: it gains the sold
// unit's own stats times `times` permanently, then the sold unit's death effects resolve in the
// Recruit Phase. Each Gorger eats once a turn; each sale is eaten once (a Gorger before a
// Granary Glutton).

use crate::content::locust::lib::locust::Locust as Locust;
#[derive(Clone,Default)]
pub struct Gorge;
pub type GorgeRef=Rc<RefCell<Gorge>>;
impl ToState for Gorge {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Gorge {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("times",Variant::Int(Kind::Number as i64));out }
 fn on_any_sold(&self, ctx: &mut RecruitContext, unit: Option<&UnitRef>, sold: &UnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/locust/mechanics/gorge.gd:on_any_sold") }
}
