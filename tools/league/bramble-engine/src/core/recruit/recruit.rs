//! Port of `src/core/recruit/recruit.gd`.
#![allow(unused_variables)]
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::{Hook, HookArgs, Target},
    mechanic_spec::MechanicSpec,
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::rules::rules::RulesRef;
use crate::core::session::game_session::{GameSession, GameSessionRef};
use crate::core::state::{
    aura_context::{AuraContext, AuraContextRef},
    fight_report::FightReportRef,
};
use crate::core::units::{card_pool::CardPoolRef, unit::UnitRef};
use crate::core::util::rng::{Rng, RngRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};
pub type RecruitRef = Rc<RefCell<Recruit>>;
/// `session` is a GDScript computed property; both handles stay weak to avoid cycles.
pub struct Recruit {
    pub session: Weak<RefCell<GameSession>>,
    pub _session_ref: Weak<RefCell<GameSession>>,
    pub _shop_rng: Dictionary<RngRef, i64>,
    pub _discover_rng: Dictionary<RngRef, i64>,
    pub _effect_rng: Dictionary<RngRef, i64>,
}
impl Recruit {
    pub fn new(game: &GameSessionRef) -> Self {
        let weak = Rc::downgrade(game);
        Self {
            session: weak.clone(),
            _session_ref: weak,
            _shop_rng: Dictionary::new(),
            _discover_rng: Dictionary::new(),
            _effect_rng: Dictionary::new(),
        }
    }
    pub fn _stream(
        recruit: &RecruitRef,
        cache: &Dictionary<RngRef, i64>,
        label: &str,
        player: &PlayerStateRef,
    ) -> RngRef {
        let player_id = player.borrow().id;
        if !cache.borrow().contains_key(&player_id) {
            let seed_value = recruit
                .borrow()
                ._session_ref
                .upgrade()
                .expect("Recruit session")
                .borrow()
                .seed_value;
            cache.borrow_mut().insert(
                player_id,
                Rng::derive(seed_value, &format!("{label}:{player_id}")),
            );
        }
        cache.borrow()[&player_id].clone()
    }
    pub fn shop_rng(recruit: &RecruitRef, player: &PlayerStateRef) -> RngRef {
        let cache = recruit.borrow()._shop_rng.clone();
        Self::_stream(recruit, &cache, "shop", player)
    }
    pub fn discover_rng(recruit: &RecruitRef, player: &PlayerStateRef) -> RngRef {
        let cache = recruit.borrow()._discover_rng.clone();
        Self::_stream(recruit, &cache, "discover", player)
    }
    pub fn effect_rng(recruit: &RecruitRef, player: &PlayerStateRef) -> RngRef {
        let cache = recruit.borrow()._effect_rng.clone();
        Self::_stream(recruit, &cache, "recruit_effect", player)
    }
    pub fn _rules(recruit: &RecruitRef) -> RulesRef {
        recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session")
            .borrow()
            .rules
            .as_ref()
            .expect("session rules")
            .clone()
    }

    // 3.2.1 in order: gold, upgrade discount, refresh counter, shop refill, start-of-turn triggers.
    pub fn start_turn(recruit: &RecruitRef, player: &PlayerStateRef) {
        todo!("port src/core/recruit/recruit.gd:start_turn")
    }

    // 3.4.1 in order: End of Turn triggers, "this turn" ends, unfrozen shop returns to the pool.
    // Gold is kept (4.1.2). Every Discover still open or waiting, including one an End of Turn
    // trigger opens, is resolved with its first option.
    pub fn end_turn(recruit: &RecruitRef, player: &PlayerStateRef) {
        todo!("port src/core/recruit/recruit.gd:end_turn")
    }

    // --- Actions -------------------------------------------------------------------------------------
    pub fn act(recruit: &RecruitRef, player: &PlayerStateRef, action: &Dictionary) -> String {
        todo!("port src/core/recruit/recruit.gd:act")
    }
    pub fn _act_simple(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        kind: &str,
        action: &Dictionary,
    ) -> String {
        todo!("port src/core/recruit/recruit.gd:_act_simple")
    }

    // 4.2: buy a unit or spell from the shop into the hand.
    pub fn _buy(recruit: &RecruitRef, player: &PlayerStateRef, spell: bool, index: i64) -> String {
        todo!("port src/core/recruit/recruit.gd:_buy")
    }

    // 4.3: sell a board unit; its pool copies return (5.3.4-5.3.5).
    pub fn _sell(recruit: &RecruitRef, player: &PlayerStateRef, slot: i64) -> String {
        todo!("port src/core/recruit/recruit.gd:_sell")
    }

    // 7.2 play a unit into a chosen empty slot, or 6.1.5 cast a spell.
    pub fn _play(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        hand_index: i64,
        slot: i64,
        target_uid: i64,
    ) -> String {
        todo!("port src/core/recruit/recruit.gd:_play")
    }
    pub fn _cast(
        recruit: &RecruitRef,
        ctx: &mut RecruitContext,
        spell: &UnitRef,
        target: Option<&UnitRef>,
    ) {
        todo!("port src/core/recruit/recruit.gd:_cast")
    }

    // 7.2.1-7.2.2 a unit needs an empty slot; a card that aims needs a target of its kind when one
    // exists (a friendly unit, a slot, a shop unit), and a spell that aims can't be cast without.
    pub fn _play_error(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        card: &UnitRef,
        slot: i64,
        target: i64,
    ) -> String {
        todo!("port src/core/recruit/recruit.gd:_play_error")
    }

    // What playing this card aims at: the first of its mechanics that aims decides.
    pub fn play_target_of(recruit: &RecruitRef, card: &UnitRef) -> Target {
        todo!("port src/core/recruit/recruit.gd:play_target_of")
    }

    // The legal targets of a kind: friendly board uids (not `card`), board slots, or the indexes of
    // filled unit shop slots.
    // A unit played from hand may aim at itself: it is placed before its "when played" effect
    // resolves (7.2.3), so `card` itself is offered (its uid) when it is a unit in hand. A board
    // unit's ability never aims at its own unit.
    pub fn targets_for(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        kind: Target,
        card: Option<&UnitRef>,
    ) -> Array<i64> {
        todo!("port src/core/recruit/recruit.gd:targets_for")
    }

    // 3.3.1 use a board unit's ability: up to its uses this turn, paying its cost.
    pub fn _use_ability(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        uid: i64,
        mechanic_id: &str,
        target: i64,
    ) -> String {
        todo!("port src/core/recruit/recruit.gd:_use_ability")
    }

    // Why a board unit's ability can't be used now ("" when it can), before a target is chosen.
    pub fn ability_error(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        unit: &UnitRef,
        bound: &BoundMechanicRef,
    ) -> String {
        todo!("port src/core/recruit/recruit.gd:ability_error")
    }
    pub fn _ability_of(
        recruit: &RecruitRef,
        unit: Option<&UnitRef>,
        mechanic_id: &str,
    ) -> Option<BoundMechanicRef> {
        todo!("port src/core/recruit/recruit.gd:_ability_of")
    }
    pub fn _ability_key(mechanic_id: &str) -> String {
        format!("ability:{mechanic_id}")
    }

    // 8.3.3 move to an empty slot or swap, free.
    pub fn _move(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        from_slot: i64,
        to_slot: i64,
    ) -> String {
        todo!("port src/core/recruit/recruit.gd:_move")
    }

    // 4.4.1-4.4.3 paid refresh: new cards in every shop slot; unfreezes.
    pub fn _refresh(recruit: &RecruitRef, player: &PlayerStateRef) -> String {
        todo!("port src/core/recruit/recruit.gd:_refresh")
    }

    // 4.5.1 toggle the freeze, up to the limit per turn.
    pub fn _freeze(recruit: &RecruitRef, player: &PlayerStateRef) -> String {
        todo!("port src/core/recruit/recruit.gd:_freeze")
    }

    // 4.6 upgrade the shop tier; 4.6.4 the discount restarts; 4.6.5 the shop doesn't refill.
    pub fn _upgrade(recruit: &RecruitRef, player: &PlayerStateRef) -> String {
        todo!("port src/core/recruit/recruit.gd:_upgrade")
    }

    // 6.2 take one Discover option; the others return (5.3.3). The pick is Created (4.3.2).
    pub fn _pick(recruit: &RecruitRef, player: &PlayerStateRef, index: i64) -> String {
        todo!("port src/core/recruit/recruit.gd:_pick")
    }
    pub fn _resolve_discovers(recruit: &RecruitRef, player: &PlayerStateRef) {
        todo!("port src/core/recruit/recruit.gd:_resolve_discovers")
    }

    // 6.2.1-6.2.3: up to N different units, each drawn by 6.1.3 and out of the pool while shown.
    // With one already shown, this one waits its turn and is drawn when that one is picked.
    pub fn offer_discover(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        min_tier: i64,
        max_tier: i64,
    ) {
        todo!("port src/core/recruit/recruit.gd:offer_discover")
    }

    // 8.4.3, 8.4.7: a Recruit Phase summon, Created. Null and logged when the board is full.
    pub fn summon(
        recruit: &RecruitRef,
        ctx: &mut RecruitContext,
        card_id: &str,
        source_slot: i64,
        own_slot_first: bool,
        golden: bool,
    ) -> Option<UnitRef> {
        todo!("port src/core/recruit/recruit.gd:summon")
    }

    // Runs a listener hook for every board unit in reading order, then the player's standing
    // mechanics with unit = null. Arguments go between the unit and the params.
    pub fn notify(ctx: &mut RecruitContext, hook: Hook, args: &HookArgs) {
        todo!("port src/core/recruit/recruit.gd:notify")
    }

    // After this player's fight (GameSession): after_fight for the real board, then standing.
    pub fn after_fight(recruit: &RecruitRef, player: &PlayerStateRef, report: &FightReportRef) {
        todo!("port src/core/recruit/recruit.gd:after_fight")
    }

    // A death effect resolving in the Recruit Phase, from where the unit stands (Mechanic
    // .on_recruit_death), as many times as Q_DEATH_EFFECT_TIMES says (asked through modify_int).
    pub fn run_death_effects(recruit: &RecruitRef, ctx: &mut RecruitContext, unit: &UnitRef) {
        todo!("port src/core/recruit/recruit.gd:run_death_effects")
    }

    // 7.1.2: a card gained while the hand is full is lost (its pool copies go back).
    pub fn _gain(recruit: &RecruitRef, player: &PlayerStateRef, unit: &UnitRef) -> bool {
        todo!("port src/core/recruit/recruit.gd:_gain")
    }

    // Fills empty shop slots (4.5.2 a frozen shop keeps its cards), sized by 6.1.1's query.
    pub fn _fill_shop(recruit: &RecruitRef, player: &PlayerStateRef) {
        todo!("port src/core/recruit/recruit.gd:_fill_shop")
    }
    pub fn _fill(
        recruit: &RecruitRef,
        shop: &Array<String>,
        size: i64,
        pool: &CardPoolRef,
        player: &PlayerStateRef,
    ) {
        todo!("port src/core/recruit/recruit.gd:_fill")
    }

    // 5.3.2 shown cards go back to the pool.
    pub fn _return_shop(recruit: &RecruitRef, player: &PlayerStateRef) {
        todo!("port src/core/recruit/recruit.gd:_return_shop")
    }
    pub fn _shop_view(recruit: &RecruitRef, player: &PlayerStateRef) -> Dictionary {
        todo!("port src/core/recruit/recruit.gd:_shop_view")
    }

    // After every action: triples form (7.3.1-7.3.2, after all summons) and auras are recomputed.
    pub fn _settle(recruit: &RecruitRef, player: &PlayerStateRef) {
        todo!("port src/core/recruit/recruit.gd:_settle")
    }

    // 7.3.1 three copies of one non-golden unit across board and hand become one golden.
    pub fn _combine_one(recruit: &RecruitRef, player: &PlayerStateRef) -> bool {
        todo!("port src/core/recruit/recruit.gd:_combine_one")
    }
    pub fn _combine(recruit: &RecruitRef, player: &PlayerStateRef, three: &Array<UnitRef>) {
        todo!("port src/core/recruit/recruit.gd:_combine")
    }

    // 12.2.1 auras apply only from board units and standing mechanics, and are recalculated
    // whenever the board changes; slot effects (8.5) are recalculated with them. Public so a
    // mechanic that changes what an aura reads (a player number, a heap) can call it.
    pub fn refresh_auras(recruit: &RecruitRef, player: &PlayerStateRef) {
        for unit in player.borrow().all_cards().borrow().iter() {
            let mut unit = unit.borrow_mut();
            let mut stats = unit.stats.as_ref().expect("unit stats").borrow_mut();
            stats.aura_attack = 0;
            stats.aura_health = 0;
            stats.slot_attack = 0;
            stats.slot_health = 0;
            drop(stats);
            unit.aura_mechanics = Array::new();
        }
        let board = player.borrow().board_units();
        for unit in board.borrow().iter() {
            let slot = unit.borrow().slot;
            let here = player.borrow().slots.borrow()[slot as usize].clone();
            let stats = unit.borrow().stats.as_ref().expect("unit stats").clone();
            stats.borrow_mut().slot_attack = here.borrow().attack;
            stats.borrow_mut().slot_health = here.borrow().health;
        }
        // As in a fight (FightAuras): a second pass on the totals when an aura read a unit's numbers.
        let view = Self::_aura_pass(recruit, player, &board);
        if view.borrow().read_stats {
            Self::_aura_pass(recruit, player, &board);
        }
    }
    pub fn _aura_pass(
        recruit: &RecruitRef,
        player: &PlayerStateRef,
        board: &Array<UnitRef>,
    ) -> AuraContextRef {
        let game = recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session");
        let mut view = AuraContext::new();
        view.geometry = game.borrow().geometry.clone();
        view.counters = player.borrow().counters.clone();
        view.heaps = player.borrow().heaps.clone();
        let slot_count = game
            .borrow()
            .geometry
            .as_ref()
            .expect("session geometry")
            .borrow()
            .slot_count as usize;
        view.defs.borrow_mut().resize(slot_count, None);
        view.unit_counters
            .borrow_mut()
            .resize_with(slot_count, Dictionary::new);
        view.stats.borrow_mut().resize(slot_count, [0, 0, 0]);
        for unit in board.borrow().iter() {
            let unit = unit.borrow();
            let slot = unit.slot as usize;
            view.defs.borrow_mut()[slot] = unit.def.clone();
            view.unit_counters.borrow_mut()[slot] = unit.counters.clone();
            view.stats.borrow_mut()[slot] = [unit.attack(), unit.health(), unit.health()];
        }
        let view = Rc::new(RefCell::new(view));
        for unit in board.borrow().iter() {
            let stats = unit.borrow().stats.as_ref().expect("unit stats").clone();
            stats.borrow_mut().aura_attack = 0;
            stats.borrow_mut().aura_health = 0;
            unit.borrow_mut().aura_mechanics = Array::new();
            let slot = unit.borrow().slot as usize;
            let here = player.borrow().slots.borrow()[slot].clone();
            for keyword in here.borrow().keywords.borrow().iter() {
                Self::_give_aura_keyword(recruit, unit, keyword);
            }
        }
        let grants = Dictionary::<Array<Variant>, i64>::new();
        for source in board.borrow().iter() {
            let source_slot = source.borrow().slot;
            let mechanics = source.borrow().mechanics.clone();
            for bound in mechanics.borrow().iter() {
                let has_aura = bound
                    .borrow()
                    .mechanic
                    .as_ref()
                    .is_some_and(|mechanic| mechanic.has_aura());
                if has_aura {
                    Self::_apply_aura(recruit, &view, bound, source_slot, board, &grants);
                }
            }
        }
        for bound in player.borrow().standing.borrow().iter() {
            let has_aura = bound
                .borrow()
                .mechanic
                .as_ref()
                .is_some_and(|mechanic| mechanic.has_aura());
            if has_aura {
                Self::_apply_aura(recruit, &view, bound, -1, board, &grants);
            }
        }
        let registry = game
            .borrow()
            .registry
            .as_ref()
            .expect("session registry")
            .clone();
        for unit in board.borrow().iter() {
            let given = grants
                .borrow()
                .get(&unit.borrow().uid)
                .cloned()
                .unwrap_or_default();
            let bound = registry.borrow().bind_grants(&given);
            unit.borrow()
                .aura_mechanics
                .borrow_mut()
                .extend(bound.borrow().iter().cloned());
        }
        view
    }
    pub fn _apply_aura(
        recruit: &RecruitRef,
        view: &AuraContextRef,
        bound: &BoundMechanicRef,
        source_slot: i64,
        board: &Array<UnitRef>,
        grants: &Dictionary<Array<Variant>, i64>,
    ) {
        let (mechanic, params) = {
            let bound = bound.borrow();
            (
                bound.mechanic.as_ref().expect("bound mechanic").clone(),
                bound.params.clone(),
            )
        };
        for target in board.borrow().iter() {
            let target_slot = target.borrow().slot;
            let gain = mechanic.aura(&mut view.borrow_mut(), source_slot, target_slot, &params);
            let stats = target.borrow().stats.as_ref().expect("unit stats").clone();
            stats.borrow_mut().aura_attack += gain.0;
            stats.borrow_mut().aura_health += gain.1;
            let keywords =
                mechanic.aura_keywords(&mut view.borrow_mut(), source_slot, target_slot, &params);
            for keyword in keywords.borrow().iter() {
                Self::_give_aura_keyword(recruit, target, keyword);
            }
            let given =
                mechanic.aura_grants(&mut view.borrow_mut(), source_slot, target_slot, &params);
            if !given.borrow().is_empty() {
                let uid = target.borrow().uid;
                let list = grants.borrow().get(&uid).cloned().unwrap_or_default();
                list.borrow_mut()
                    .extend(given.borrow().iter().cloned().map(Variant::Dictionary));
                grants.borrow_mut().insert(uid, list);
            }
        }
    }
    pub fn _give_aura_keyword(recruit: &RecruitRef, unit: &UnitRef, keyword: &str) {
        let game = recruit
            .borrow()
            ._session_ref
            .upgrade()
            .expect("Recruit session");
        let registry = game
            .borrow()
            .registry
            .as_ref()
            .expect("session registry")
            .clone();
        if registry.borrow().has(keyword) && !unit.borrow().has_mechanic(keyword) {
            let bound = registry
                .borrow()
                .bind(&MechanicSpec::new(keyword, None), false, true);
            unit.borrow().aura_mechanics.borrow_mut().push(bound);
        }
    }
    pub fn _log(recruit: &RecruitRef, player: &PlayerStateRef, event: &Dictionary) {
        todo!("port src/core/recruit/recruit.gd:_log")
    }
}
impl ToState for Recruit {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "session"=> &self.session, "_session_ref"=> &self._session_ref, "_shop_rng"=> &self._shop_rng, "_discover_rng"=> &self._discover_rng, "_effect_rng"=> &self._effect_rng }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "session",
            "_session_ref",
            "_shop_rng",
            "_discover_rng",
            "_effect_rng",
        ]
    }
}

// Rule comments retained for the pending bodies:
// {"type": "buy", "spell": bool, "index": int}       4.2
// {"type": "sell", "slot": int}                      4.3
// {"type": "play", "hand": int, "slot": int, "target": int}   7.2, 6.1.5; "target" is a uid,
// {"type": "move", "from": int, "to": int}           8.3.3 (swaps when "to" is taken)
// {"type": "refresh"}  {"type": "freeze"}  {"type": "upgrade"}       4.4, 4.5, 4.6
// {"type": "pick", "index": int}                     6.2 (the only action while choosing)
// {"type": "ability", "uid": int, "mechanic": id, "target": int}   3.3.1 a unit's ability
// {"type": "end_turn"}                               3.4
// The spell's pool copy returns once cast (5.3.7 read for spells; see README).
// 4.4.5: a refresh made free by an effect doesn't advance the paid counter.
// 7.3.4 keeps every buff and debuff, and each stat is at least the golden base.
// 7.3.7 into the first vacated slot. It is never played, so its Triple Reward is gained
// now, into a full hand: lost by 7.1.2.
