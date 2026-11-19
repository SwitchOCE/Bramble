//! Port of `src/core/recruit/recruit_context.gd`.
#![allow(unused_variables)]
use crate::core::board::{board_geometry::BoardGeometryRef, selectors::Selectors};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::{Hook, HookArgs},
    mechanic_spec::MechanicSpec,
};
use crate::core::recruit::{
    player_state::PlayerStateRef,
    recruit::{Recruit, RecruitRef},
};
use crate::core::session::game_session::GameSessionRef;
use crate::core::units::unit::UnitRef;
use crate::core::util::rng::RngRef;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type RecruitContextRef = Rc<RefCell<RecruitContext>>;
pub struct RecruitContext {
    pub session: Option<GameSessionRef>,
    pub player: Option<PlayerStateRef>,
    pub rng: Option<RngRef>,
    pub target_index: i64,
    /// Recruit effects are exempt, including a full-hand golden placed on the board.
    pub recruit_source: Option<UnitRef>,
    pub track_work: bool,
    pub _source: Option<UnitRef>,
    pub _modifiers: Array<UnitRef>,
    pub _recruit: Option<RecruitRef>,
    pub _triggers: i64,
    pub _limit: i64,
}
impl Default for RecruitContext {
    fn default() -> Self {
        Self {
            session: None,
            player: None,
            rng: None,
            target_index: -1,
            recruit_source: None,
            track_work: true,
            _source: None,
            _modifiers: Array::new(),
            _recruit: None,
            _triggers: 0,
            _limit: 1000,
        }
    }
}
macro_rules! event {
    ($($key:expr => $value:expr),* $(,)?) => {{
        let out = Dictionary::new();
        $(out.insert($key, ($value).to_state());)*
        out
    }};
}
impl RecruitContext {
    pub fn new(game: &GameSessionRef, recruit: &RecruitRef, who: &PlayerStateRef) -> Self {
        let rng = Recruit::effect_rng(recruit, who);
        let limit = game
            .borrow()
            .config
            .as_ref()
            .expect("session config")
            .borrow()
            .action_trigger_limit;
        Self {
            session: Some(game.clone()),
            player: Some(who.clone()),
            rng: Some(rng),
            _recruit: Some(recruit.clone()),
            _limit: limit,
            ..Self::default()
        }
    }
    // Source scope survives nested listeners and sold-unit death effects.
    pub fn invoke(
        &mut self,
        unit: Option<&UnitRef>,
        bound: &BoundMechanicRef,
        hook: Hook,
        args: &HookArgs,
    ) {
        let previous = std::mem::replace(&mut self._source, unit.cloned());
        let scoped = self._modifiers.duplicate();
        let previous_modifiers = std::mem::replace(&mut self._modifiers, scoped);
        let (mechanic, params) = Recruit::_hook(bound);
        match (hook, args) {
            (Hook::OnSold, HookArgs::None) => mechanic.on_sold(self, unit, &params),
            (Hook::OnRecruitDeath, HookArgs::None) => {
                mechanic.on_recruit_death(self, unit, &params)
            }
            (Hook::OnAbility, HookArgs::Ability { target }) => {
                mechanic.on_ability(self, unit, target.as_ref(), &params)
            }
            (Hook::OnRecruited, HookArgs::Recruited { target }) => {
                mechanic.on_recruited(
                    self,
                    unit.expect("recruited unit"),
                    target.as_ref(),
                    &params,
                );
            }

            (Hook::OnStartOfTurn, HookArgs::None) => mechanic.on_start_of_turn(self, unit, &params),
            (Hook::OnEndOfTurn, HookArgs::None) => mechanic.on_end_of_turn(self, unit, &params),
            (Hook::OnAnySold, HookArgs::AnySold { sold }) => {
                mechanic.on_any_sold(self, unit, sold, &params)
            }
            (Hook::OnHeapAdded, HookArgs::HeapAdded { heap, card_id }) => {
                mechanic.on_heap_added(self, unit, heap, card_id, &params)
            }
            (Hook::AfterFight, HookArgs::AfterFight { report }) => {
                mechanic.after_fight(self, unit, report, &params)
            }
            _ => panic!("invalid recruit listener arguments: {}", hook.as_str()),
        }
        self._source = previous;
        self._modifiers = previous_modifiers;
    }

    // Read a modifier for this effect. Contributors commit only if a mutation follows.
    pub fn ask(&self, query: &str, base: i64) -> i64 {
        let rules = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .rules
            .clone()
            .expect("rules");
        rules.borrow().ask(
            query,
            base,
            self.player.as_ref(),
            None,
            Some(&self._modifiers),
        )
    }

    fn _worked(&self, source: Option<&UnitRef>) {
        if !self.track_work {
            return;
        }
        let player = self.player.as_ref().unwrap().borrow();
        if let Some(owner) = source.or(self._source.as_ref())
            && !self
                .recruit_source
                .as_ref()
                .is_some_and(|unit| Rc::ptr_eq(owner, unit))
        {
            player.mark_worked(Some(owner));
        }
        for modifier in self._modifiers.iter_live() {
            if !self
                .recruit_source
                .as_ref()
                .is_some_and(|unit| Rc::ptr_eq(&modifier, unit))
            {
                player.mark_worked(Some(&modifier));
            }
        }
    }

    pub fn geometry(&self) -> BoardGeometryRef {
        self.session
            .as_ref()
            .expect("RecruitContext session")
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .clone()
    }

    // Call before a hook acts: logs the trigger. False once the action's trigger limit is reached,
    // and the hook must then do nothing.
    pub fn trigger(&mut self, unit: Option<&UnitRef>, mechanic_id: &str) -> bool {
        if self._triggers >= self._limit {
            return false;
        }
        self._triggers += 1;
        let event = event! { "type" => "trigger", "player" => self.player.as_ref().unwrap().borrow().id,
        "uid" => unit.map(|u| u.borrow().uid).unwrap_or(-1), "mechanic" => mechanic_id };
        self.session
            .as_ref()
            .unwrap()
            .borrow_mut()
            .log_event(&event);
        true
    }
    pub fn triggers_used(&self) -> i64 {
        self._triggers
    }

    // 12.1.1: `permanent` for the rest of the game, otherwise this turn.
    pub fn buff(
        &mut self,
        unit: &UnitRef,
        attack: i64,
        health: i64,
        permanent: bool,
        source: Option<&UnitRef>,
    ) {
        if attack != 0 || health != 0 {
            self._worked(source);
        }
        let stats = unit.borrow().stats.as_ref().unwrap().clone();
        {
            let mut stats = stats.borrow_mut();
            if permanent {
                stats.perm_attack += attack;
                stats.perm_health += health;
            } else {
                stats.turn_attack += attack;
                stats.turn_health += health;
            }
        }
        let event = event! { "type" => "buff", "player" => self.player.as_ref().unwrap().borrow().id,
        "uid" => unit.borrow().uid, "attack" => unit.borrow().attack(), "health" => unit.borrow().health(),
        "source_uid" => source.map(|u| u.borrow().uid).unwrap_or(-1),
        "duration" => if permanent { "permanent" } else { "turn" } };
        self.session
            .as_ref()
            .unwrap()
            .borrow_mut()
            .log_event(&event);
    }
    pub fn gain_gold(&mut self, amount: i64, source: Option<&UnitRef>) {
        let player = self.player.as_ref().unwrap();
        let before = player.borrow().gold;
        let gold = (before + amount).max(0);
        player.borrow_mut().gold = gold;
        if gold != before {
            self._worked(source);
        }
        let event = event! { "type" => "gold", "player" => player.borrow().id, "amount" => amount,
        "gold" => gold, "source_uid" => source.map(|u| u.borrow().uid).unwrap_or(-1) };
        self.session
            .as_ref()
            .unwrap()
            .borrow_mut()
            .log_event(&event);
    }

    // 8.4.7 a summon in the Recruit Phase: placed by 8.4, Created (4.3.1). Null when it fails.
    // `own_slot_first` for a unit's own effect that summons into its own slot when that is empty (an
    // eaten unit's death effect: the slot the sold unit left, 8.4.1); `golden` for a golden token.
    pub fn summon(
        &mut self,
        card_id: &str,
        source_slot: i64,
        own_slot_first: bool,
        golden: bool,
    ) -> Option<UnitRef> {
        let recruit = self._recruit.as_ref().unwrap().clone();
        let made = Recruit::summon(&recruit, self, card_id, source_slot, own_slot_first, golden);
        if made.is_some() {
            self._worked(None);
        }
        made
    }

    // 6.2 Discover a unit with a tier in [min_tier, max_tier].
    pub fn discover(&mut self, min_tier: i64, max_tier: i64) {
        let player = self.player.as_ref().unwrap();
        let before = player.borrow().discover_options.len() + player.borrow().discover_queue.len();
        Recruit::offer_discover(self._recruit.as_ref().unwrap(), player, min_tier, max_tier);
        if player.borrow().discover_options.len() + player.borrow().discover_queue.len() > before {
            self._worked(None);
        }
    }

    // The units on this player's board for a selector (Selectors), in reading order.
    pub fn select(&self, unit: &UnitRef, selector: &str) -> Array<UnitRef> {
        let out = Array::new();
        let player = self.player.as_ref().unwrap();
        let slots = Selectors::slots(
            &self.geometry(),
            unit.borrow().slot,
            &player.borrow().occupied(),
            selector,
        );
        for slot in slots.borrow().iter() {
            out.push(
                player.borrow().board.borrow()[*slot as usize]
                    .as_ref()
                    .unwrap()
                    .clone(),
            );
        }
        out
    }
    pub fn random_of(&self, units: &Array<UnitRef>) -> Option<UnitRef> {
        if units.is_empty() {
            return None;
        }
        let index = self
            .rng
            .as_ref()
            .unwrap()
            .borrow_mut()
            .index(units.len() as i64);
        units.get(index as usize)
    }

    // A player-level number that lasts the game (PlayerState.counters).
    pub fn add_counter(&mut self, key: &str, amount: i64, source: Option<&UnitRef>) {
        if amount != 0 {
            self._worked(source);
        }
        let registry = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .registry
            .as_ref()
            .unwrap()
            .clone();
        registry.borrow_mut().check_name(key, "player counter");
        let player = self.player.as_ref().unwrap().clone();
        let value = player.borrow().counter(key) + amount;
        player.borrow().counters.insert(key, Variant::Int(value));
        self._log(&event! { "type" => "player_counter", "key" => key, "value" => player.borrow().counter(key) }, source);
        Recruit::refresh_auras(self._recruit.as_ref().unwrap(), &player);
    }

    // A number on a unit for this turn only (Unit.turn_counters; "ate this turn"), logged as
    // `turn_counter`. Cleared at the start of each turn.
    pub fn add_turn_counter(
        &mut self,
        unit: &UnitRef,
        key: &str,
        amount: i64,
        source: Option<&UnitRef>,
    ) {
        if amount != 0 {
            self._worked(source);
        }
        let registry = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .registry
            .as_ref()
            .unwrap()
            .clone();
        registry.borrow_mut().check_name(key, "turn counter");
        let value = unit.borrow().turn_counter(key) + amount;
        unit.borrow().turn_counters.insert(key, Variant::Int(value));
        self._log(
            &event! { "type" => "turn_counter", "uid" => unit.borrow().uid, "key" => key,
            "value" => unit.borrow().turn_counter(key) },
            source,
        );
    }

    // A number on a unit that lasts the game (Unit.counters).
    pub fn add_unit_counter(
        &mut self,
        unit: &UnitRef,
        key: &str,
        amount: i64,
        source: Option<&UnitRef>,
    ) {
        if amount != 0 {
            self._worked(source);
        }
        let registry = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .registry
            .as_ref()
            .unwrap()
            .clone();
        registry.borrow_mut().check_name(key, "unit counter");
        let value = unit.borrow().counter(key) + amount;
        unit.borrow().counters.insert(key, Variant::Int(value));
        self._log(
            &event! { "type" => "counter", "uid" => unit.borrow().uid, "key" => key,
            "value" => unit.borrow().counter(key), "permanent" => true },
            source,
        );
    }

    // An entry into one of the player's heaps; "whenever an entry goes in" listeners hear it.
    pub fn heap_add(&mut self, heap_name: &str, card_id: &str, source: Option<&UnitRef>) {
        let game = self.session.as_ref().unwrap().clone();
        let registry = game.borrow().registry.as_ref().unwrap().clone();
        registry.borrow_mut().check_name(heap_name, "heap");
        let library = game.borrow().library.as_ref().unwrap().clone();
        let tier = if library.borrow().has(card_id) {
            library
                .borrow()
                .get_card(card_id)
                .expect("library card")
                .borrow()
                .tier
        } else {
            1
        };
        let player = self.player.as_ref().unwrap().clone();
        let heap = player.borrow_mut().heap(heap_name);
        heap.borrow_mut().add(card_id, tier);
        self._worked(source);
        self._log(&event! { "type" => "heap_add", "heap" => heap_name, "id" => card_id, "size" => heap.borrow().size() }, source);
        Recruit::notify(
            self,
            Hook::OnHeapAdded,
            &HookArgs::HeapAdded {
                heap: heap_name.to_owned(),
                card_id: card_id.to_owned(),
            },
        );
        Recruit::refresh_auras(self._recruit.as_ref().unwrap(), &player);
    }

    // Spends the `count` lowest entries; false, and nothing spent, when there are fewer.
    pub fn heap_spend(&mut self, heap_name: &str, count: i64, source: Option<&UnitRef>) -> bool {
        let heap = self.player.as_ref().unwrap().borrow_mut().heap(heap_name);
        let spent = heap.borrow_mut().spend_lowest(count);
        if spent.is_empty() {
            return false;
        }
        self._heap_removed(heap_name, &spent, source);
        true
    }

    // Takes the highest entry; &"" when the heap is empty.
    pub fn heap_take(&mut self, heap_name: &str, source: Option<&UnitRef>) -> String {
        let heap = self.player.as_ref().unwrap().borrow_mut().heap(heap_name);
        let card_id = heap.borrow_mut().take_highest();
        if !card_id.is_empty() {
            self._heap_removed(heap_name, &Array::from([card_id.clone()]), source);
        }
        card_id
    }
    pub fn _heap_removed(
        &mut self,
        heap_name: &str,
        ids: &Array<String>,
        source: Option<&UnitRef>,
    ) {
        self._worked(source);
        let player = self.player.as_ref().unwrap().clone();
        let heap = player.borrow_mut().heap(heap_name);
        self._log(&event! { "type" => "heap_remove", "heap" => heap_name, "ids" => ids, "size" => heap.borrow().size() }, source);
        Recruit::refresh_auras(self._recruit.as_ref().unwrap(), &player);
    }

    // Gives a slot a lasting keyword (8.5.3).
    pub fn slot_keyword(&mut self, slot: i64, keyword: &str, source: Option<&UnitRef>) {
        let player = self.player.as_ref().unwrap();
        let here = player.borrow().slots.get(slot as usize).unwrap();
        let keywords = here.borrow().keywords.clone();
        if !keyword.is_empty() && !keywords.has(&keyword.to_owned()) {
            self._worked(source);
            keywords.push(keyword.to_owned());
        }
        self._log_slot(slot, source);
    }

    /// Permanent Recruit Phase Renown gain, without scaling.
    pub fn add_renown(&mut self, slot: i64, amount: i64, source: Option<&UnitRef>) {
        if amount == 0 {
            return;
        }
        let player = self.player.as_ref().unwrap().clone();
        let here = player.borrow().slots.get(slot as usize).unwrap();
        self._worked(source);
        let total = {
            let mut here = here.borrow_mut();
            here.renown = here.renown.wrapping_add(amount);
            here.renown
        };
        self._log(
            &event! { "type" => "renown", "slot" => slot, "amount" => amount, "total" => total },
            source,
        );
        Recruit::refresh_auras(self._recruit.as_ref().unwrap(), &player);
    }

    // Clears a keyword from a slot for good (moving a Guard post).
    pub fn slot_clear_keyword(&mut self, slot: i64, keyword: &str, source: Option<&UnitRef>) {
        let player = self.player.as_ref().unwrap().clone();
        let here = player.borrow().slots.get(slot as usize).unwrap();
        let keywords = here.borrow().keywords.clone();
        let index = keywords.borrow().iter().position(|value| value == keyword);
        if let Some(index) = index {
            self._worked(source);
            keywords.borrow_mut().remove(index);
        }
        self._log_slot(slot, source);
    }

    fn _log_slot(&mut self, slot: i64, source: Option<&UnitRef>) {
        let player = self.player.as_ref().unwrap().clone();
        let here = player.borrow().slots.get(slot as usize).unwrap();
        self._log(
            &event! { "type" => "slot", "slot" => slot,
            "total" => here.borrow().view(), "permanent" => true },
            source,
        );
        Recruit::refresh_auras(self._recruit.as_ref().unwrap(), &player);
    }

    // A new copy of a card into the hand (a Created card, 4.3.1).
    // Lost if the hand is full (7.1.2). Returns it, or null.
    pub fn give_card(&mut self, card_id: &str, source: Option<&UnitRef>) -> Option<UnitRef> {
        let game = self.session.as_ref().unwrap().clone();
        let library = game.borrow().library.as_ref().unwrap().clone();
        if !library.borrow().has(card_id) {
            return None;
        }
        let card = library.borrow().get_card(card_id).expect("library card");
        let made = game.borrow_mut().new_unit(&card, false);
        self._log(
            &event! { "type" => "give_card", "uid" => made.borrow().uid, "id" => card_id },
            source,
        );
        if Recruit::_gain(
            self._recruit.as_ref().unwrap(),
            self.player.as_ref().unwrap(),
            &made,
            -2,
        ) {
            self._worked(source);
            Some(made)
        } else {
            None
        }
    }

    // 11.1.1 a unit gains a keyword for good. False if it had it or the keyword is unknown.
    pub fn give_keyword(
        &mut self,
        unit: &UnitRef,
        keyword: &str,
        source: Option<&UnitRef>,
    ) -> bool {
        let registry = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .registry
            .as_ref()
            .unwrap()
            .clone();
        if !unit.borrow_mut().grant(&registry, keyword) {
            return false;
        }
        self._worked(source);
        self._log(&event! { "type" => "keyword", "uid" => unit.borrow().uid, "keyword" => keyword, "on" => true }, source);
        true
    }

    // A unit gains a mechanic with parameters for good ('Give a unit "+1 Fury"', Master-at-Arms):
    // `raw` holds its parameters as card data does. The numbers are the giver's: a golden target
    // never doubles them (pass the giver's params.num value). Logged as `effect`. False when the
    // mechanic is unknown or the parameters are wrong.
    pub fn give_effect(
        &mut self,
        unit: &UnitRef,
        mechanic_id: &str,
        raw: &Dictionary,
        source: Option<&UnitRef>,
    ) -> bool {
        let registry = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .registry
            .as_ref()
            .unwrap()
            .clone();
        if !unit.borrow_mut().grant_effect(&registry, mechanic_id, raw) {
            return false;
        }
        self._worked(source);
        self._log(&event! { "type" => "effect", "uid" => unit.borrow().uid, "mechanic" => mechanic_id, "params" => raw.duplicate() }, source);
        Recruit::refresh_auras(
            self._recruit.as_ref().unwrap(),
            self.player.as_ref().unwrap(),
        );
        true
    }

    // Clears a unit slot and returns the card id (&"" for an invalid or empty slot).
    // The mechanic can use the id to add a heap entry.
    pub fn take_from_shop(&mut self, index: i64, source: Option<&UnitRef>) -> String {
        let player = self.player.as_ref().unwrap().clone();
        let shop = player.borrow().shop_units.clone();
        if index < 0 || index >= shop.len() as i64 {
            return String::new();
        }
        let card_id = shop.get(index as usize).unwrap();
        if card_id == crate::core::recruit::player_state::PlayerState::NO_CARD {
            return String::new();
        }
        self._worked(source);
        shop.borrow_mut()[index as usize] = String::new();
        self._log(
            &event! { "type" => "shop_take", "index" => index, "id" => card_id },
            source,
        );
        card_id
    }

    // A unit's death effects in the Recruit Phase, without a death (Mechanic.on_recruit_death).
    pub fn run_death_effects(&mut self, unit: &UnitRef) {
        let recruit = self._recruit.as_ref().unwrap().clone();
        Recruit::run_death_effects(&recruit, self, unit);
    }

    // Gives the player a standing mechanic (no unit) once; false if it has it or it's unknown.
    pub fn add_standing(&mut self, mechanic_id: &str) -> bool {
        let player = self.player.as_ref().unwrap().clone();
        let registry = self
            .session
            .as_ref()
            .unwrap()
            .borrow()
            .registry
            .as_ref()
            .unwrap()
            .clone();
        if player.borrow().has_standing(mechanic_id) || !registry.borrow().has(mechanic_id) {
            return false;
        }
        self._worked(None);
        let bound = registry
            .borrow()
            .bind(&MechanicSpec::new(mechanic_id, None), false, false);
        player.borrow().standing.push(bound);
        Recruit::refresh_auras(self._recruit.as_ref().unwrap(), &player);
        true
    }
    pub fn _log(&mut self, event: &Dictionary, source: Option<&UnitRef>) {
        event.insert(
            "player",
            Variant::Int(self.player.as_ref().unwrap().borrow().id),
        );
        event.insert(
            "source_uid",
            Variant::Int(source.map(|u| u.borrow().uid).unwrap_or(-1)),
        );
        self.session.as_ref().unwrap().borrow_mut().log_event(event);
    }
}
impl ToState for RecruitContext {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "session"=> &self.session, "player"=> &self.player, "rng"=> &self.rng, "target_index"=> &self.target_index, "recruit_source"=> &self.recruit_source, "track_work"=> &self.track_work, "_source"=> &self._source, "_modifiers"=> &self._modifiers, "_recruit"=> &self._recruit, "_triggers"=> &self._triggers, "_limit"=> &self._limit }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "session",
            "player",
            "rng",
            "target_index",
            "recruit_source",
            "track_work",
            "_source",
            "_modifiers",
            "_recruit",
            "_triggers",
            "_limit",
        ]
    }
}

// Rule comments retained for the pending bodies:
// limit (9.10.2).
// --- Lasting state (12.1.1 "this game") -----------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{records::record_state::RecordState, recruit::legal_actions::LegalActions};
    use crate::game::game_content::GameContent;
    use crate::util::godot_json;
    use sha2::{Digest, Sha256};

    // Oracle: the same operations run on pinned Godot 4.7.2, seed 42, first drawable card.
    // Checks two session states plus the JSON player view and ordered legal actions.
    #[test]
    fn recruit_context_matches_godot_state_view_and_actions() {
        let oracle =
            godot_json::parse_string(include_str!("../../../../gd/recruit_context_vectors.json"))
                .as_dict();
        let hashes = oracle.get("hashes").as_array();
        let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let content = GameContent::load_default(&root);
        assert!(content.borrow().errors.is_empty());
        let game = content.borrow().new_session(42, &Array::new());
        let player = game.borrow().player(0);
        let card = content
            .borrow()
            .library
            .borrow()
            .drawable_cards(false)
            .get(0)
            .unwrap();
        let first = game.borrow_mut().new_unit(&card, false);
        let second = game.borrow_mut().new_unit(&card, true);
        player.borrow_mut().place(&first, 0);
        player.borrow_mut().place(&second, 1);
        let recruit = game.borrow().recruit.as_ref().unwrap().clone();
        let mut ctx = RecruitContext::new(&game, &recruit, &player);
        assert_eq!(
            RecordState::state_hash(&game.borrow()),
            hashes.get(0).unwrap().as_text()
        );
        ctx.buff(&first, 3, -2, true, Some(&second));
        ctx.buff(&second, -1, 4, false, None);
        ctx.gain_gold(7, Some(&first));
        ctx.gain_gold(-20, None);
        ctx.add_turn_counter(&first, "badger_proof_turn", 2, Some(&second));
        ctx.add_unit_counter(&second, "badger_proof_unit", 3, None);
        ctx._limit = 1;
        assert!(ctx.trigger(Some(&first), "proof"));
        assert!(!ctx.trigger(None, "proof"));
        let chosen = ctx.random_of(&ctx.select(&first, "others")).unwrap();
        assert_eq!(chosen.borrow().uid, 2);
        assert_eq!(
            RecordState::state_hash(&game.borrow()),
            hashes.get(1).unwrap().as_text()
        );
        let view = godot_json::stringify(&player.borrow().view().to_state());
        assert_eq!(
            format!("{:x}", Sha256::digest(view.as_bytes())),
            oracle.get("view_hash").as_text()
        );
        let actions = godot_json::stringify(&LegalActions::of(&game, &player).to_state());
        assert_eq!(
            format!("{:x}", Sha256::digest(actions.as_bytes())),
            oracle.get("actions_hash").as_text()
        );
    }
}
