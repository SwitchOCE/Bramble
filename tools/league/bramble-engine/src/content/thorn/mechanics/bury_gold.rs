#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::{bury_base::BuryBase, compost_rules::CompostRules as Compost};
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
// Source: src/content/thorn/mechanics/bury_gold.gd
// Bury: Gain N gold (Hedge Layer).

#[derive(Clone, Default)]
pub struct BuryGold;
pub type BuryGoldRef = Rc<RefCell<BuryGold>>;
impl ToState for BuryGold {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for BuryGold {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
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
        BuryBase::run_ability(
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
impl BuryGold {
    pub fn mechanic_id(&self) -> String {
        "thorn_bury_gold".to_owned()
    }
    pub fn bury_effect(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        ctx.gain_gold(params.borrow().num("amount"), unit);
    }
}
