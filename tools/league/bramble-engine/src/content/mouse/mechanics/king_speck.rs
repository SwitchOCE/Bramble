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
// Source: src/content/mouse/mechanics/king_speck.gd
// King Speck replaces a fallen Mouse with a Cousin carrying that Mouse's own Attack.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct KingSpeck;
pub type KingSpeckRef = Rc<RefCell<KingSpeck>>;
impl ToState for KingSpeck {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for KingSpeck {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! {"limit" => &(Kind::Number as i64)}.as_dict()
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
        let side = unit.borrow().side;
        let slot = dead.borrow().slot;
        if Rc::ptr_eq(unit, dead)
            || !MouseRules::is_mouse(dead.borrow().def.as_ref())
            || combat.unit_at(side, slot).is_some()
        {
            return;
        }
        if MouseRules::charge(
            combat,
            unit,
            "mouse_king_speck",
            params.borrow().num("limit"),
        ) {
            let attack = dead.borrow().stats.as_ref().unwrap().borrow().own_attack();
            combat.summon(
                side,
                crate::content::mouse::lib::mouse_rules::COUSIN,
                slot,
                true,
                Some(unit),
                &Dictionary::new(),
                params.borrow().golden,
                attack,
            );
        }
    }
}
