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
// Source: src/content/locust/mechanics/gorge.gd
// Gorger. The first time you sell a unit each turn (any tribe), this eats it: it gains the sold
// unit's own stats times `times` permanently, then the sold unit's death effects resolve in the
// Recruit Phase. Each Gorger eats once a turn; each sale is eaten once (a Gorger before a
// Granary Glutton).

use crate::content::locust::lib::locust::Locust;
#[derive(Clone, Default)]
pub struct Gorge;
pub type GorgeRef = Rc<RefCell<Gorge>>;
impl ToState for Gorge {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Gorge {
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
        // TODO(port mechanics)
        todo!("port src/content/locust/mechanics/gorge.gd:on_any_sold")
    }
}
