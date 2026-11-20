//! Mirrors src/content/mouse/mechanics/aunt.gd.
use crate::core::mechanics::{mechanic::Mechanic, mechanic_params::Kind};
use crate::core::{
    mechanics::mechanic_params::MechanicParamsRef, recruit::recruit_context::RecruitContext,
    units::unit::UnitRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct Aunt;

impl ToState for Aunt {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }

    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Aunt {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "count" => &(Kind::Number as i64), }.as_dict()
    }

    fn on_recruited(
        &self,
        ctx: &mut RecruitContext,
        unit: &UnitRef,
        _target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if ctx.trigger(Some(unit), "mouse_aunt") {
            for _ in 0..params.borrow().num("count") {
                ctx.give_card("cousin", Some(unit));
            }
        }
    }
}
