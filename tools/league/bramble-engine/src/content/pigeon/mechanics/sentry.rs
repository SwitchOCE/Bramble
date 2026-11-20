//! Mirrors src/content/pigeon/mechanics/sentry.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    mechanics::mechanic_params::MechanicParamsRef, recruit::recruit_context::RecruitContext,
    units::unit::UnitRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct Sentry;

impl ToState for Sentry {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Sentry {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "supply" => &(Kind::Threshold as i64), "amount" => &(Kind::Number as i64), }.as_dict()
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        const KEY: &str = "supply:pigeon_sentry";
        let Some(unit) = unit else { return };
        let (slot, left) = {
            let unit = unit.borrow();
            (unit.slot, unit.counter(KEY))
        };
        if slot < 0 || left <= 0 {
            return;
        }
        if ctx.trigger(Some(unit), "pigeon_sentry") {
            unit.borrow().counters.insert(KEY, (left - 1).into());
            ctx.add_renown(slot, params.borrow().num("amount"), Some(unit));
        }
    }
}
