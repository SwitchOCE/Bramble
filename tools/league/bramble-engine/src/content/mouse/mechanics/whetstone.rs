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
// Source: src/content/mouse/mechanics/whetstone.gd
// Whetstone Vole: at the end of your turn, give this slot +attack Attack (a permanent slot buff).

#[derive(Clone, Default)]
pub struct Whetstone;
pub type WhetstoneRef = Rc<RefCell<Whetstone>>;
impl ToState for Whetstone {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Whetstone {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if let Some(unit) = unit {
            if ctx.trigger(Some(unit), "mouse_whetstone") {
                let slot = unit.borrow().slot;
                ctx.slot_buff(slot, params.borrow().num("attack"), 0, Some(unit), "");
            }
        }
    }
}
