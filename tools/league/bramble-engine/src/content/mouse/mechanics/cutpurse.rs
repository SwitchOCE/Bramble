#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/mechanics/cutpurse.gd
// Shrew Cutpurse: the first time this piles on each fight, gain `gold` gold, paid at the start of
// your next turn. The pile-on itself is mouse_pile_on; MouseRules.after_pile_on pays the gold.

#[derive(Clone,Default)]
pub struct Cutpurse;
pub type CutpurseRef=Rc<RefCell<Cutpurse>>;
impl ToState for Cutpurse {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl Mechanic for Cutpurse {
 fn param_kinds(&self) -> Dictionary { let out=Dictionary::new();out.insert("gold",Variant::Int(Kind::Number as i64));out }
}
