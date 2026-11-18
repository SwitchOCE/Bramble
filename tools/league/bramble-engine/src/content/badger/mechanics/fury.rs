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
// Source: src/content/badger/mechanics/fury.gd
// Fury N: whenever this attacks or is attacked, gain +N Attack for each unit you're outnumbered
// by (this fight). Fury from every source adds into one N (BadgerRules.fury); the Marshal
// multiplies it last.

use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct Fury;
pub type FuryRef = Rc<RefCell<Fury>>;
impl ToState for Fury {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Fury {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("fury", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_attacked(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/fury.gd:on_attacked")
    }
    fn on_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/fury.gd:on_attack")
    }
}
