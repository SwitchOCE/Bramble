//! Refight-only tool: a copy of the session's mechanic registry in which chosen mechanics are
//! wrapped. The engine's rules code is untouched; a wrapped mechanic answers every hook by
//! asking the real one, except that a mechanic switched off for one side does nothing for the
//! units of that side.
//!
//! A wrapper can also note each attack made by a unit that holds the mechanic (the Overrun
//! swing count). It notes and then asks the real mechanic, so the fight is unchanged.
use bramble_engine::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use bramble_engine::core::mechanics::{
    mechanic::{Combine, Mechanic, Target},
    mechanic_params::MechanicParamsRef,
    mechanic_registry::{MechanicRegistry, MechanicRegistryRef},
};
use bramble_engine::core::recruit::{
    player_state::PlayerStateRef, recruit_context::RecruitContext,
};
use bramble_engine::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use bramble_engine::core::units::unit::UnitRef;
use bramble_engine::{Array, Dictionary, ToState, Variant};
use std::cell::RefCell;
use std::rc::Rc;

/// One attack by a unit holding the noted mechanic, as it reached the "on attack" step.
#[derive(Debug, Clone)]
pub(super) struct Swing {
    pub uid: i64,
    pub side: i64,
    pub card: String,
    pub golden: bool,
    /// Index in the fight's event log just after this attack's `attack` event.
    pub event_index: usize,
    /// Enemy units standing (not dying) when the attack reached the "on attack" step.
    pub enemy_standing: usize,
}

pub(super) type Swings = Rc<RefCell<Vec<Swing>>>;

struct Switched {
    inner: Rc<dyn Mechanic>,
    off_side: Option<i64>,
    swings: Option<Swings>,
}

/// Checks that a mechanic can be switched off for one side by gating its unit hooks: one with an
/// aura, a death effect or an ability acts through hooks that don't say which side asks.
pub(super) fn check_switchable(registry: &MechanicRegistryRef, id: &str) -> Result<(), String> {
    let mechanic = registry
        .borrow()
        .get_mechanic(id)
        .ok_or_else(|| format!("unknown mechanic {id:?}"))?;
    if mechanic.has_aura() || mechanic.has_death_effect() || mechanic.has_ability() {
        return Err(format!(
            "mechanic {id:?} has an aura, a death effect or an ability; switching it off for one side is not supported"
        ));
    }
    Ok(())
}

/// A fresh registry with the same scripts as `base`, where `off` (mechanic ids) do nothing for
/// units of `off_side`, and `noted` (mechanic id) records its holders' attacks into `swings`.
pub(super) fn registry(
    base: &MechanicRegistryRef,
    off: &[String],
    off_side: i64,
    noted: Option<(&str, &Swings)>,
) -> MechanicRegistryRef {
    let out = MechanicRegistry::new();
    {
        let base = base.borrow();
        let mut copy = out.borrow_mut();
        for prefix in base.prefixes.to_vec() {
            copy.prefixes.push(prefix);
        }
        for (id, script) in base._scripts.borrow().iter() {
            let is_off = off.iter().any(|o| o == id);
            let swings = noted.filter(|(n, _)| *n == id).map(|(_, s)| s.clone());
            let script: Rc<dyn Mechanic> = if is_off || swings.is_some() {
                Rc::new(Switched {
                    inner: script.clone(),
                    off_side: is_off.then_some(off_side),
                    swings,
                })
            } else {
                script.clone()
            };
            copy.register(id, script);
        }
    }
    out
}

/// Every mechanic wrapped and none switched off: for the test that wrapping alone changes nothing.
#[cfg(test)]
pub(super) fn pass_through(base: &MechanicRegistryRef) -> MechanicRegistryRef {
    let out = MechanicRegistry::new();
    for (id, script) in base.borrow()._scripts.borrow().iter() {
        out.borrow_mut().register(
            id,
            Rc::new(Switched {
                inner: script.clone(),
                off_side: None,
                swings: None,
            }),
        );
    }
    out
}

impl Switched {
    fn off(&self, unit: Option<&CombatUnitRef>) -> bool {
        match (self.off_side, unit) {
            (Some(side), Some(unit)) => unit.borrow().side == side,
            _ => false,
        }
    }
}

impl ToState for Switched {
    fn to_state(&self) -> Variant {
        self.inner.to_state()
    }
}

impl Mechanic for Switched {
    fn param_kinds(&self) -> Dictionary {
        self.inner.param_kinds()
    }
    fn text_params(&self, params: &MechanicParamsRef) -> Dictionary {
        self.inner.text_params(params)
    }
    fn play_target(&self, params: &MechanicParamsRef) -> Target {
        self.inner.play_target(params)
    }
    fn recruit_target(&self, params: &MechanicParamsRef) -> Target {
        self.inner.recruit_target(params)
    }
    fn accepts_recruit_target(&self, unit: &UnitRef, source: Option<&UnitRef>) -> bool {
        self.inner.accepts_recruit_target(unit, source)
    }
    // Recruit-phase hooks never run in a refight; they pass through.
    fn on_recruited(
        &self,
        ctx: &mut RecruitContext,
        unit: &UnitRef,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_recruited(ctx, unit, target, params)
    }
    fn on_played(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_played(ctx, unit, target, params)
    }
    fn on_start_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        report: Option<&FightReportRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_start_of_turn(ctx, unit, report, params)
    }
    fn on_end_of_turn(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_end_of_turn(ctx, unit, params)
    }
    fn on_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_sold(ctx, unit, params)
    }
    fn on_recruit_death(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_recruit_death(ctx, unit, params)
    }
    fn has_ability(&self) -> bool {
        self.inner.has_ability()
    }
    fn ability_cost(&self, params: &MechanicParamsRef) -> i64 {
        self.inner.ability_cost(params)
    }
    fn ability_uses(&self, params: &MechanicParamsRef) -> i64 {
        self.inner.ability_uses(params)
    }
    fn ability_target(&self, params: &MechanicParamsRef) -> Target {
        self.inner.ability_target(params)
    }
    fn ability_usable(
        &self,
        player: Option<&PlayerStateRef>,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) -> bool {
        self.inner.ability_usable(player, unit, params)
    }
    fn on_ability(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_ability(ctx, unit, target, params)
    }
    fn on_any_sold(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        sold: &UnitRef,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_any_sold(ctx, unit, sold, params)
    }
    fn on_heap_added(
        &self,
        ctx: &mut RecruitContext,
        unit: Option<&UnitRef>,
        heap: &str,
        card_id: &str,
        params: &MechanicParamsRef,
    ) {
        self.inner.on_heap_added(ctx, unit, heap, card_id, params)
    }
    // Fight hooks: gated by the side of the unit the hook runs for.
    fn on_combat_begin(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_combat_begin(combat, unit, params)
        }
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_start_of_combat(combat, unit, params)
        }
    }
    fn start_of_combat_priority(&self, params: &MechanicParamsRef) -> i64 {
        self.inner.start_of_combat_priority(params)
    }
    fn has_death_effect(&self) -> bool {
        self.inner.has_death_effect()
    }
    fn instead_of_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) -> bool {
        !self.off(unit) && self.inner.instead_of_attack(combat, unit, params)
    }
    fn protect_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) -> bool {
        !self.off(unit) && self.inner.protect_attack(combat, unit, params)
    }
    fn on_friendly_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        killer: &CombatUnitRef,
        victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner
                .on_friendly_kill(combat, unit, killer, victim, params)
        }
    }
    fn on_attacked(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_attacked(combat, unit, attacker, params)
        }
    }
    fn on_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if let (Some(swings), Some(attacker)) = (&self.swings, unit) {
            let index = combat.events.len();
            let attacker = attacker.borrow();
            // A unit with the mechanic twice notes one swing per attack.
            let repeat = swings
                .borrow()
                .last()
                .is_some_and(|s| s.event_index == index && s.uid == attacker.uid);
            if !repeat {
                let enemy = 1 - attacker.side;
                let standing = combat
                    .sides
                    .get(enemy as usize)
                    .expect("enemy side")
                    .borrow()
                    .iter()
                    .flatten()
                    .filter(|u| !u.borrow().should_die())
                    .count();
                swings.borrow_mut().push(Swing {
                    uid: attacker.uid,
                    side: attacker.side,
                    card: attacker
                        .def
                        .as_ref()
                        .map_or_else(String::new, |d| d.borrow().id.clone()),
                    golden: attacker.golden,
                    event_index: index,
                    enemy_standing: standing,
                });
            }
        }
        if !self.off(unit) {
            self.inner.on_attack(combat, unit, defender, params)
        }
    }
    fn after_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.after_attack(combat, unit, defender, params)
        }
    }
    fn on_damage_dealt(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        target: Option<&CombatUnitRef>,
        amount: i64,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner
                .on_damage_dealt(combat, unit, target, amount, params)
        }
    }
    fn absorb_damage(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        amount: i64,
        from_attack: bool,
        params: &MechanicParamsRef,
    ) -> i64 {
        if self.off(unit) {
            amount
        } else {
            self.inner
                .absorb_damage(combat, unit, amount, from_attack, params)
        }
    }
    fn on_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_kill(combat, unit, victim, params)
        }
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_death(combat, unit, params)
        }
    }
    fn return_offer(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        if self.off(unit) {
            0
        } else {
            self.inner.return_offer(combat, unit, params)
        }
    }
    fn return_priority(&self, params: &MechanicParamsRef) -> i64 {
        self.inner.return_priority(params)
    }
    fn return_as_recruit(&self, params: &MechanicParamsRef) -> bool {
        self.inner.return_as_recruit(params)
    }
    fn pay_return(
        &self,
        combat: &mut Combat,
        gone: &CombatUnitRef,
        back: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(Some(back)) {
            self.inner.pay_return(combat, gone, back, params)
        }
    }
    fn on_returned(
        &self,
        combat: &mut Combat,
        gone: &CombatUnitRef,
        back: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(Some(back)) {
            self.inner.on_returned(combat, gone, back, params)
        }
    }
    fn combat_query(
        &self,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        if self.off(unit) {
            value
        } else {
            self.inner.combat_query(unit, query, value, params)
        }
    }
    fn side_query(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        if self.off(unit) {
            value
        } else {
            self.inner.side_query(combat, unit, query, value, params)
        }
    }
    fn on_friendly_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner
                .on_friendly_attack(combat, unit, attacker, defender, params)
        }
    }
    fn on_any_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_any_death(combat, unit, dead, params)
        }
    }
    fn on_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_friendly_death(combat, unit, dead, params)
        }
    }
    fn after_friendly_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        dead: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.after_friendly_death(combat, unit, dead, params)
        }
    }
    fn after_friendly_return(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        back: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.after_friendly_return(combat, unit, back, params)
        }
    }
    fn on_fight_enter(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        entered: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.on_fight_enter(combat, unit, entered, params)
        }
    }
    fn after_death_round(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner.after_death_round(combat, unit, params)
        }
    }
    fn on_heap_added_in_fight(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        heap: &str,
        card_id: &str,
        params: &MechanicParamsRef,
    ) {
        if !self.off(unit) {
            self.inner
                .on_heap_added_in_fight(combat, unit, heap, card_id, params)
        }
    }
    // Auras pass through: check_switchable refuses a mechanic with an aura.
    fn has_aura(&self) -> bool {
        self.inner.has_aura()
    }
    fn aura_parts(&self) -> u8 {
        self.inner.aura_parts()
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> (i64, i64) {
        self.inner.aura(view, source_slot, target_slot, params)
    }
    fn aura_grants(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        self.inner
            .aura_grants(view, source_slot, target_slot, params)
    }
    fn grant_combine(&self, param: &str) -> Combine {
        self.inner.grant_combine(param)
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<String> {
        self.inner
            .aura_keywords(view, source_slot, target_slot, params)
    }
    fn modify_int(
        &self,
        query: &str,
        value: i64,
        player: Option<&PlayerStateRef>,
        unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        self.inner.modify_int(query, value, player, unit, params)
    }
}
