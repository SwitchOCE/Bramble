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
// Source: src/content/locust/mechanics/tide_on_sell.gd
// Horde-runner. The first Locust sold each turn raises the Tide while this is on the board.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct TideOnSell;
pub type TideOnSellRef = Rc<RefCell<TideOnSell>>;
impl ToState for TideOnSell {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for TideOnSell {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"amount" => &(Kind::Number as i64)}.as_dict()
    }
    fn on_any_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        sold: &UnitRef,
        params: &MechanicParamsRef,
    ) {
        const MECHANIC: &str = "locust_tide_on_sell";
        let Some(unit) = unit else {
            return;
        };
        if !sold
            .borrow()
            .def
            .as_ref()
            .unwrap()
            .borrow()
            .has_tribe(names::TRIBE)
            || unit.borrow().turn_counter(MECHANIC) > 0
            || !ctx.trigger(Some(unit), MECHANIC)
        {
            return;
        }
        ctx.add_turn_counter(unit, MECHANIC, 1, Some(unit));
        ctx.add_counter(names::TIDE, params.borrow().num("amount"), Some(unit));
    }
}
