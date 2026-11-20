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
// Source: src/content/badger/mechanics/dame.gd
// Dame of the Old Sett: while she is on the board, every friendly unit whose type line says
// Knight, herself included, has +N Fury and Overrun. Two Dames add up. Her Fury is borrowed:
// Sword-heir doesn't take it.

use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct Dame;
pub type DameRef = Rc<RefCell<Dame>>;
impl ToState for Dame {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Dame {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("fury", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_parts(&self) -> u8 {
        AURA_KEYWORDS | AURA_GRANTS
    }
    fn aura_grants(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        if source_slot < 0 || !BadgerRules::is_knight(view.def_at(target_slot).as_ref()) {
            return Array::new();
        }
        let raw = Dictionary::new();
        raw.insert(
            "mechanic",
            Variant::from(crate::content::badger::lib::badger_rules::FURY),
        );
        raw.insert("fury", Variant::Int(params.borrow().num("fury")));
        Array::from([raw])
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        let out = Array::new();
        if source_slot >= 0 && BadgerRules::is_knight(view.def_at(target_slot).as_ref()) {
            out.push("badger_overrun".to_owned());
        }
        out
    }
}
