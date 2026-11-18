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
// Source: src/content/badger/mechanics/marshal.gd
// Marshal of the Red Mist: while this is on the board, every friendly unit's Fury counts double
// (golden: triple), applied after everything that adds Fury. Two Marshals don't stack: the
// biggest applies. `extra` is what it adds to the multiplier (1, or 2 on a golden).

use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct Marshal;
pub type MarshalRef = Rc<RefCell<Marshal>>;
impl ToState for Marshal {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Marshal {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("extra", Variant::Int(Kind::Number as i64));
        out
    }
    fn side_query(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        if unit.is_none() || query != crate::content::badger::lib::badger_rules::Q_FURY_TIMES {
            return value;
        }
        value.max(1 + params.borrow().num("extra"))
    }
}
