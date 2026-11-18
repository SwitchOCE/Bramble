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
// Source: src/content/pigeon/mechanics/sergeant_major.gd
// Regimental Sergeant Major: at the end of your turn, give every slot +amount/+amount. While
// this is on the recruit board, every slot buff the player's effects give is doubled as it is
// given (Rules.SLOT_BUFF_PERCENT, read from the recruit board in fights too, so it still doubles
// if he died in that fight). Two don't stack: the core takes the bigger. A golden gives +4/+4
// and triples (`extra_percent` 200).

#[derive(Clone, Default)]
pub struct SergeantMajor;
pub type SergeantMajorRef = Rc<RefCell<SergeantMajor>>;
impl ToState for SergeantMajor {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for SergeantMajor {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out.insert("extra_percent", Variant::Int(Kind::Number as i64));
        out
    }
    fn modify_int(
        &self,
        query: &str,
        value: i64,
        _player: Option<&PlayerStateRef>,
        _unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/sergeant_major.gd:modify_int")
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/sergeant_major.gd:on_end_of_turn")
    }
}
