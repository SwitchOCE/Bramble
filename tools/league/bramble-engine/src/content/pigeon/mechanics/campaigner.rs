//! Mirrors src/content/pigeon/mechanics/campaigner.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    mechanics::mechanic_params::MechanicParamsRef, recruit::recruit_context::RecruitContext,
    state::fight_report::FightReportRef, units::unit::UnitRef,
};
use crate::{Dictionary, ToState, Variant};

pub struct Campaigner;

impl ToState for Campaigner {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Mechanic for Campaigner {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "amount" => &(Kind::Number as i64), "survived" => &(Kind::Number as i64), }.as_dict()
    }

    fn after_fight(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: &FightReportRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else { return };
        let slot = unit.borrow().slot;
        if slot >= 0 && ctx.trigger(Some(unit), "pigeon_campaigner") {
            let amount = params
                .borrow()
                .num(if report.borrow().survived(Some(unit)) {
                    "survived"
                } else {
                    "amount"
                });
            ctx.add_renown(slot, amount, Some(unit));
        }
    }
}
