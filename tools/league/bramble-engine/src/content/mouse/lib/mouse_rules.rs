#![allow(unused_imports, unused_variables)]
use std::{cell::RefCell, rc::Rc};
use crate::{Array, Dictionary, ToState, Variant};
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::recruit::{recruit_context::RecruitContext, player_state::PlayerStateRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::mechanics::{mechanic::*,mechanic_params::{MechanicParamsRef,Kind},bound_mechanic::BoundMechanicRef};
// Source: src/content/mouse/lib/mouse_rules.gd
// The Mice's shared rules (docs/ideation-track-2/tribes/mouse/units.json "rules"), used by the
// scripts in mechanics/. Not a mechanic itself, so it lives in lib/.
// side_query: percent of its Attack a pile-on hit deals (base 100; Dame Bodkin 200, golden 300).
// Fight count: how many times this unit has piled on this fight (a return carries it).
// Fight count, and the uses a screen shows: the Needle Pikeman's gains this fight.
// Hit the enemy with the least Health `times` times, choosing again for each (the core's
// weakest_enemy leaves out units already dying). False if none was hit.
// "After this piles on" effects, once `piler` has asked for its pile-on hit: its own (Needle
// Pikeman, Shrew Cutpurse) and its side's Fencing Masters. The hits land together after every
// friend has heard the attack, at the Attack each had when it asked, so a gain made here never
// counts for the hit that earned it, and every unit that piled on counts even when another's hit
// killed the target (rules.pile_on.together).
// Summons `count` Cousins from `source`'s slot (8.4.2), golden ones when `golden`. A Cousin
// never waits: with no room it is lost. Returns how many landed.
pub const TRIBE: &str = "Mouse";
pub const COUSIN: &str = "cousin";
pub const Q_PILE_PERCENT: &str = "mouse_pile_percent";
pub const PILES: &str = "mouse_piles";
pub const PIKE_GAINS: &str = "mouse_pikeman_gains";
#[derive(Clone,Default)]
pub struct MouseRules;
pub type MouseRulesRef=Rc<RefCell<MouseRules>>;
impl ToState for MouseRules {fn to_state(&self)->Variant{Variant::Dictionary(Dictionary::default())} fn field_names()->&'static [&'static str]{&[]}}
impl MouseRules {
 pub fn is_mouse(def: Option<&UnitDefRef>) -> bool { // TODO(port mechanics)
 todo!("port src/content/mouse/lib/mouse_rules.gd:is_mouse") }
 pub fn hit_weakest(combat: &mut Combat, unit: Option<&CombatUnitRef>, times: i64) -> bool { // TODO(port mechanics)
 todo!("port src/content/mouse/lib/mouse_rules.gd:hit_weakest") }
 pub fn after_pile_on(combat: &mut Combat, piler: &CombatUnitRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/lib/mouse_rules.gd:after_pile_on") }
 pub fn _pikeman_grows(combat: &mut Combat, piler: &CombatUnitRef, params: &MechanicParamsRef) { // TODO(port mechanics)
 todo!("port src/content/mouse/lib/mouse_rules.gd:_pikeman_grows") }
 pub fn summon_cousins(combat: &mut Combat, source: Option<&CombatUnitRef>, count: i64, golden: bool) -> i64 { // TODO(port mechanics)
 todo!("port src/content/mouse/lib/mouse_rules.gd:summon_cousins") }
}
