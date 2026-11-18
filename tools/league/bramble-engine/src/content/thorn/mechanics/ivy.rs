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
// Source: src/content/thorn/mechanics/ivy.gd
// The units in front of this have Grow N (Ivy Climber): an aura from a back-row slot onto the
// two front slots it sits between (8.2.1), whatever the units' tribe. In the front row it does
// nothing.

#[derive(Clone, Default)]
pub struct Ivy;
pub type IvyRef = Rc<RefCell<Ivy>>;
impl ToState for Ivy {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Ivy {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_grants(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        if source_slot < 0
            || !view
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .in_front_of(source_slot)
                .has(&target_slot)
        {
            return Array::new();
        }
        let grant = Dictionary::new();
        grant.insert("mechanic", Variant::String("thorn_grow".into()));
        grant.insert("amount", Variant::Int(params.borrow().num("amount")));
        Array::from([grant])
    }
}
