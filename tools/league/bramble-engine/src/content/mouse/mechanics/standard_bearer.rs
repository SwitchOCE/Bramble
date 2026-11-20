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
// Source: src/content/mouse/mechanics/standard_bearer.gd
// Count the Mice once at Start of fight and put the buff on those units.

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct StandardBearer;
pub type StandardBearerRef = Rc<RefCell<StandardBearer>>;
impl ToState for StandardBearer {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for StandardBearer {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("attack", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let Some(unit) = unit else {
            return;
        };
        if !combat.trigger(Some(unit), "mouse_standard_bearer") {
            return;
        }
        let side = unit.borrow().side;
        let mice: Vec<_> = combat
            .units(side)
            .iter_live()
            .filter(|friend| MouseRules::is_mouse(friend.borrow().def.as_ref()))
            .collect();
        let bonus = (mice.len() as i64).wrapping_mul(params.borrow().num("attack"));
        for friend in mice {
            combat.buff(Some(&friend), bonus, 0, Some(unit), false);
        }
    }
}
