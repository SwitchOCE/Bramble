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
// Source: src/content/badger/mechanics/arms_master.gd
// Master-at-Arms: when played (7.2.3), give a friendly unit on the board (any tribe, this one
// included) +N Fury for good: a badger_fury of its own that adds to the Fury it has. A plain
// copy of the unit doesn't have it. The number is this card's; a golden target doesn't double it.

use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct ArmsMaster;
pub type ArmsMasterRef = Rc<RefCell<ArmsMaster>>;
impl ToState for ArmsMaster {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for ArmsMaster {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("fury", Variant::Int(Kind::Number as i64));
        out
    }
    fn play_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::FriendlyUnit
    }
    fn on_played(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        let chosen = target.or(unit).expect("played unit");
        if ctx.trigger(unit, "badger_arms_master") {
            let raw = Dictionary::new();
            raw.insert("fury", Variant::Int(params.borrow().num("fury")));
            ctx.give_effect(
                chosen,
                crate::content::badger::lib::badger_rules::FURY,
                &raw,
                unit,
            );
        }
    }
}
