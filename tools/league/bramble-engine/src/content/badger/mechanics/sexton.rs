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
// Source: src/content/badger/mechanics/sexton.gd
// Sett Sexton: after another friendly Badger dies (9.7.2 step 3), every friendly Badger on the
// board at that moment, this one included, has +N Fury for the rest of this fight (a Badger with
// no Fury now has Fury N). Badgers that arrive later don't get it; the outnumbered count doesn't
// change.

use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct Sexton;
pub type SextonRef = Rc<RefCell<Sexton>>;
impl ToState for Sexton {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Sexton {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("fury", Variant::Int(Kind::Number as i64));
        out
    }
    fn after_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if Rc::ptr_eq(dead, unit) || dead.borrow().side != unit.borrow().side {
            return;
        }
        if !dead
            .borrow()
            .def
            .as_ref()
            .unwrap()
            .borrow()
            .has_tribe(crate::content::badger::lib::badger_rules::BADGER)
        {
            return;
        }
        if !combat.trigger(Some(unit), "badger_sexton") {
            return;
        }
        let side = unit.borrow().side;
        let friends = combat.units(side);
        let mut i = 0;
        while i < friends.len() {
            let friend = friends.get(i).unwrap();
            let badger = friend
                .borrow()
                .def
                .as_ref()
                .unwrap()
                .borrow()
                .has_tribe(crate::content::badger::lib::badger_rules::BADGER);
            if badger {
                BadgerRules::give_fight_fury(
                    combat,
                    Some(&friend),
                    params.borrow().num("fury"),
                    Some(unit),
                );
            }
            i += 1;
        }
    }
}
