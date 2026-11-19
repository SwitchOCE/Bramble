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
// Source: src/content/pigeon/mechanics/colour_sergeant.gd
// Colour Sergeant: at the end of your turn, if every slot of this row holds a Pigeon (this one
// included), give each slot of the row +amount/+amount permanently.

#[derive(Clone, Default)]
pub struct ColourSergeant;
pub type ColourSergeantRef = Rc<RefCell<ColourSergeant>>;
impl ToState for ColourSergeant {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for ColourSergeant {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        let slot = unit.borrow().slot;
        if slot < 0 {
            return;
        }
        let row = ctx.geometry().borrow().row_of(slot);
        for index in 0..row.len() {
            let here = ctx
                .player
                .as_ref()
                .unwrap()
                .borrow()
                .board
                .get(row.get(index).unwrap() as usize)
                .flatten();
            if here.is_none_or(|here| {
                !here
                    .borrow()
                    .def
                    .as_ref()
                    .unwrap()
                    .borrow()
                    .has_tribe("Pigeon")
            }) {
                return;
            }
        }
        if !ctx.trigger(Some(unit), "pigeon_colour_sergeant") {
            return;
        }
        for index in 0..row.len() {
            ctx.add_renown(
                row.get(index).unwrap(),
                params.borrow().num("amount"),
                Some(unit),
            );
        }
    }
}
