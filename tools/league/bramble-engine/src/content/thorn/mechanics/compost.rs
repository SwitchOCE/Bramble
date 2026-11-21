#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::compost_rules::HEAP;
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
// Source: src/content/thorn/mechanics/compost.gd
// The Compost (standing, every player): a Bought unit sold goes in, one entry for each Bought
// copy in it (a golden adds one for each); Created units add nothing. It also gives an Elder
// Mother copy its bonus as it enters the fight.

use crate::content::thorn::lib::compost_rules::CompostRules as CompostLib;
#[derive(Clone, Default)]
pub struct Compost;
pub type CompostRef = Rc<RefCell<Compost>>;
impl ToState for Compost {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Compost {
    fn on_any_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        sold: &UnitRef,
        _params: &MechanicParamsRef,
    ) {
        if unit.is_some() || sold.borrow().is_spell() {
            return;
        }
        let copies = sold.borrow().bought_copies;
        for _copy in 0..copies {
            let card_id = sold.borrow().def.as_ref().unwrap().borrow().id.clone();
            ctx.heap_add(HEAP, &card_id, None);
        }
    }
    fn on_fight_enter(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        entered: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        if unit.is_none() && entered.borrow().side == combat.listening_side {
            CompostLib::elder_bonus(combat, entered);
        }
    }
}
