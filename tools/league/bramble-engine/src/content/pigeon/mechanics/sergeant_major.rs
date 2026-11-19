//! Mirrors src/content/pigeon/mechanics/sergeant_major.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    mechanics::mechanic_params::MechanicParamsRef, recruit::recruit_context::RecruitContext,
    units::unit::UnitRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct SergeantMajor;

impl ToState for SergeantMajor {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for SergeantMajor {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "amount" => &(Kind::Number as i64), }.as_dict()
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else { return };
        if !ctx.trigger(Some(unit), "pigeon_sergeant_major") {
            return;
        }
        let slot_count = ctx.geometry().borrow().slot_count;
        for slot in 0..slot_count {
            ctx.add_renown(slot, params.borrow().num("amount"), Some(unit));
        }
    }
}
