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
// Source: src/content/badger/mechanics/oakfeller.gd
// The Oakfeller: after this attacks and kills a unit with its own damage (the target, or one
// reached by Overrun), it attacks once more, at once. The extra attack never earns another. A
// kill a neighbour's pile-on makes is not its kill.
//
// State on the fight unit: SWING is 1 while a normal attack's deaths resolve and 2 for the
// extra attack's; a kill during a normal swing sets PENDING, and the extra attack is made
// after that round of deaths (once the dead have left the board).
pub const SWING: &str = "badger_oak_swing";
pub const PENDING: &str = "badger_oak_pending";
pub const EXTRA: &str = "badger_oak_extra";
#[derive(Clone, Default)]
pub struct Oakfeller;
pub type OakfellerRef = Rc<RefCell<Oakfeller>>;
impl ToState for Oakfeller {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Oakfeller {
    fn on_attack(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _defender: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/oakfeller.gd:on_attack")
    }
    fn on_attacked(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _attacker: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/oakfeller.gd:on_attacked")
    }
    fn on_kill(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _victim: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/oakfeller.gd:on_kill")
    }
    fn after_death_round(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/oakfeller.gd:after_death_round")
    }
}
