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
// Source: src/content/mouse/mechanics/piper.gd
// Harvest Piper: on recruit, give your other Mice +attack Attack permanently (golden: double).

#[derive(Clone, Default)]
pub struct Piper;
pub type PiperRef = Rc<RefCell<Piper>>;
impl ToState for Piper {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Piper {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_recruited(
        &self,
        ctx: &mut RecruitContext,
        unit: &UnitRef,
        _target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !ctx.trigger(Some(unit), "mouse_piper") {
            return;
        }
        let others = ctx.player.as_ref().unwrap().borrow().board_units();
        let mut i = 0;
        while i < others.len() {
            let other = others.get(i).unwrap();
            if !Rc::ptr_eq(&other, unit)
                && other
                    .borrow()
                    .def
                    .as_ref()
                    .unwrap()
                    .borrow()
                    .has_tribe("Mouse")
            {
                ctx.buff(&other, params.borrow().num("attack"), 0, true, Some(unit));
            }
            i += 1;
        }
    }
}
