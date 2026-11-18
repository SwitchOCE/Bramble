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
// Source: src/content/pigeon/mechanics/campaigner.gd
// Old Campaigner: after each fight, earn `medals` Medals, or `survived` if its fight copy was
// alive at the end. Decorated (3+ Medals): Stiff Upper Lip, given to itself as an aura so it
// follows the Medal count in both phases.

use crate::content::pigeon::lib::medals::Medals;
#[derive(Clone, Default)]
pub struct Campaigner;
pub type CampaignerRef = Rc<RefCell<Campaigner>>;
impl ToState for Campaigner {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Campaigner {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("medals", Variant::Int(Kind::Number as i64));
        out.insert("survived", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_fight(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: &FightReportRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if !ctx.trigger(Some(unit), "pigeon_campaigner") {
            return;
        }
        let count = params
            .borrow()
            .num(if report.borrow().survived(Some(unit)) {
                "survived"
            } else {
                "medals"
            });
        Medals::earn(ctx, Some(unit), count, Some(unit));
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        let out = Array::new();
        if source_slot >= 0 && source_slot == target_slot && Medals::decorated(view, source_slot) {
            out.push("pigeon_stiff_upper_lip".to_string());
        }
        out
    }
}
