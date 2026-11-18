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
// Source: src/content/pigeon/mechanics/adjutant.gd
// Adjutant: after each fight, the units in the two slots in front of this on the recruit board
// each earn `medals` Medals, whether or not they lived. Any tribe.

use crate::content::pigeon::lib::medals::Medals;
#[derive(Clone, Default)]
pub struct Adjutant;
pub type AdjutantRef = Rc<RefCell<Adjutant>>;
impl ToState for Adjutant {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Adjutant {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("medals", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_fight(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        _report: &FightReportRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        let slot = unit.borrow().slot;
        if slot < 0 {
            return;
        }
        let front = Array::new();
        let slots = ctx.geometry().borrow().in_front_of(slot);
        for index in 0..slots.len() {
            let here = ctx
                .player
                .as_ref()
                .unwrap()
                .borrow()
                .board
                .get(slots.get(index).unwrap() as usize)
                .flatten();
            if let Some(here) = here {
                front.push(here);
            }
        }
        if front.is_empty() || !ctx.trigger(Some(unit), "pigeon_adjutant") {
            return;
        }
        let mut index = 0;
        while index < front.len() {
            let here = front.get(index).unwrap();
            index += 1;
            Medals::earn(ctx, Some(&here), params.borrow().num("medals"), Some(unit));
        }
    }
}
