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
// Source: src/content/pigeon/mechanics/bugler.gd
// Bugler: after a friendly Pigeon joins the fight (summoned, or stepping in from Reserve; a
// return is its own event and is not heard here, SHARED-RULES 22), give every friendly Pigeon on
// the board +amount/+amount for this fight, the new one included.

#[derive(Clone, Default)]
pub struct Bugler;
pub type BuglerRef = Rc<RefCell<Bugler>>;
impl ToState for Bugler {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Bugler {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_fight_enter(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        entered: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        let side = unit.borrow().side;
        if entered.borrow().side != side {
            return;
        }
        if !entered
            .borrow()
            .def
            .as_ref()
            .unwrap()
            .borrow()
            .has_tribe("Pigeon")
            || !combat.trigger(Some(unit), "pigeon_bugler")
        {
            return;
        }
        let amount = params.borrow().num("amount");
        let friends = combat.units(side).duplicate();
        let mut index = 0;
        while index < friends.len() {
            let friend = friends.get(index).unwrap();
            index += 1;
            let pigeon = friend
                .borrow()
                .def
                .as_ref()
                .unwrap()
                .borrow()
                .has_tribe("Pigeon");
            if pigeon {
                combat.buff(Some(&friend), amount, amount, Some(unit), false);
            }
        }
    }
}
