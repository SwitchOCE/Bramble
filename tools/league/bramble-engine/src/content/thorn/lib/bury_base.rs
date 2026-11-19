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
// Source: src/content/thorn/lib/bury_base.gd
// Bury (SHARED-RULES, Briars): once a turn for each Bury unit on the board, a shop unit (not a
// spell) leaves the shop and adds an entry to the Compost. Then the unit's effect resolves
// as many times as "Your Bury effects happen" says
// (Old Mother Midden). The thorn_bury_* mechanics extend this and write bury_effect.
// Rules.ask query: how many times a Bury's effect resolves (base 1).
// The mechanic's id, for its trigger.
// What follows the Bury.
pub const Q_BURY_TIMES: &str = "thorn_bury_times";
use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct BuryBase;
pub type BuryBaseRef = Rc<RefCell<BuryBase>>;
impl ToState for BuryBase {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for BuryBase {
    fn has_ability(&self) -> bool {
        true
    }
    fn ability_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::ShopUnit
    }
    fn on_ability(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        _target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        Self::run_ability(
            ctx,
            unit,
            params,
            &self.mechanic_id(),
            |ctx, unit, params| {
                self.bury_effect(ctx, unit, params);
            },
        );
    }
}
impl BuryBase {
    pub fn run_ability(
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
        mechanic_id: &str,
        bury_effect: impl Fn(&mut RecruitContext, Option<&UnitRef>, &MechanicParamsRef),
    ) {
        if !ctx.trigger(unit, mechanic_id) {
            return;
        }
        let card_id = ctx.take_from_shop(ctx.target_index, unit);
        if card_id.is_empty() {
            return;
        }
        ctx.heap_add(HEAP, &card_id, unit);
        let times = ctx.ask(Q_BURY_TIMES, 1).max(1);
        for _time in 0..times {
            bury_effect(ctx, unit, params);
        }
    }

    pub fn mechanic_id(&self) -> String {
        "thorn_bury".to_owned()
    }
    pub fn bury_effect(
        &self,
        _ctx: &mut RecruitContext,
        _unit: Option<&UnitRef>,
        _params: &MechanicParamsRef,
    ) {
    }
}
