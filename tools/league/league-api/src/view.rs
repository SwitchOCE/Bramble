//! What a bot may know, as owned copies. Nothing here holds a reference into a live game.
use crate::{action::Action, copy};
use bramble_engine::core::{
    records::record_state::RecordState,
    recruit::{legal_actions::LegalActions, player_state::PlayerStateRef},
    session::game_session::GameSessionRef,
    units::{unit::UnitRef, unit_library::UnitLibraryRef},
};
use bramble_engine::util::godot_json;
use bramble_engine::{Array, Dictionary, ToState, Variant};
use std::collections::BTreeMap;
use std::rc::Rc;

/// One card's data, as the card JSON gives it.
#[derive(Clone, Debug, PartialEq)]
pub struct CardInfo {
    pub id: String,
    pub name: String,
    pub tier: i64,
    pub attack: i64,
    pub health: i64,
    pub spell: bool,
    pub types: Vec<String>,
    pub tribes: Vec<String>,
    pub keywords: Vec<String>,
    /// Mechanic ids in the card's text, in order.
    pub mechanics: Vec<String>,
    pub token: bool,
    pub combines: bool,
    pub cost: i64,
    pub offered: bool,
    pub text: String,
    pub golden_text: String,
}

impl CardInfo {
    /// `UnitDef.has_tribe`: the card is of `tribe` ("Badger", "Briar", ...) or of every tribe.
    pub fn has_tribe(&self, tribe: &str) -> bool {
        self.tribes.iter().any(|t| t == tribe || t == "All")
    }
    /// Whether this card can be drawn, as in `UnitDef.can_be_drawn`.
    pub fn in_pool(&self) -> bool {
        !self.token && self.offered
    }
}

/// Every card in the game, and the rules numbers (`GameConfig`).
#[derive(Clone, Debug)]
pub struct Library {
    cards: Vec<CardInfo>,
    by_id: BTreeMap<String, usize>,
    ints: BTreeMap<String, i64>,
    lists: BTreeMap<String, Vec<i64>>,
    slot_count: i64,
}

impl Library {
    pub fn cards(&self) -> &[CardInfo] {
        &self.cards
    }
    pub fn get(&self, id: &str) -> Option<&CardInfo> {
        self.by_id.get(id).map(|&i| &self.cards[i])
    }
    /// A scalar `GameConfig` number by its field name (`"hand_limit"`, `"round_limit"`, ...).
    pub fn config(&self, name: &str) -> Option<i64> {
        self.ints.get(name).copied()
    }
    /// A list `GameConfig` field (`"unit_weights_by_tier"`, ...).
    pub fn config_list(&self, name: &str) -> Option<&[i64]> {
        self.lists.get(name).map(Vec::as_slice)
    }
    /// Board slots (front plus back).
    pub fn slot_count(&self) -> i64 {
        self.slot_count
    }
}

/// One card a player holds, as it is now.
#[derive(Clone, Debug)]
pub struct UnitView {
    pub uid: i64,
    pub def: String,
    pub tier: i64,
    pub golden: bool,
    pub spell: bool,
    /// Board slot, or -1 in hand.
    pub slot: i64,
    pub attack: i64,
    pub health: i64,
    /// One of this unit's own effects did Recruit Phase work this turn, so it can't move to hand.
    pub worked_this_turn: bool,
    /// Copies represented by this card. A triple has three, and a newly created card has one.
    pub copies: i64,
    pub bought_copies: i64,
    /// Compatibility field. Always zero.
    pub pool_copies: i64,
    /// Keyword mechanics it has now (own, aura and slot), as `Unit.keyword_ids`.
    pub keywords: Vec<String>,
    /// Every mechanic whose hooks run for it (`Unit.hooks`), by id.
    pub mechanics: Vec<String>,
    pub counters: Vec<(String, i64)>,
    /// Remaining Supply across this unit's effects. Zero when there is none left.
    pub supply_left: i64,
    pub turn_counters: Vec<(String, i64)>,
    /// What selling it gives (`Rules.sell_value`).
    pub sell_value: i64,
    /// The unit as a fight payload stores it.
    pub snapshot: SnapUnit,
}

/// A unit as `FightSnapshot.unit` stores it. Clone is a deep copy.
#[derive(Debug)]
pub struct SnapUnit {
    raw: Dictionary,
}

impl Clone for SnapUnit {
    fn clone(&self) -> Self {
        Self {
            raw: copy::deep_dict(&self.raw),
        }
    }
}

impl SnapUnit {
    /// A fresh copy of a card as a payload unit (no buffs), with the given uid.
    pub fn fresh(def: &str, uid: i64, golden: bool) -> Self {
        let raw = Dictionary::new();
        raw.insert("def", def.into());
        raw.insert("uid", uid.into());
        raw.insert("golden", golden.into());
        Self { raw }
    }
    pub(crate) fn from_raw(raw: Dictionary) -> Self {
        Self { raw }
    }
    pub fn def(&self) -> String {
        self.raw.get("def").as_text()
    }
    pub fn uid(&self) -> i64 {
        self.raw.get("uid").as_i64()
    }
    pub fn golden(&self) -> bool {
        matches!(self.raw.get("golden"), Variant::Bool(true))
    }
    pub fn set_uid(&mut self, uid: i64) {
        self.raw.insert("uid", uid.into());
    }
    /// A stat layer that differs from the card's default (`FightSnapshot.LAYERS`).
    pub fn stat(&self, layer: &str) -> Option<i64> {
        let stats = self.raw.get("stats");
        let Variant::Dictionary(stats) = stats else {
            return None;
        };
        stats.borrow().get(layer).map(Variant::as_i64)
    }
    /// Compatibility accessor. Always zero.
    pub fn pool_copies(&self) -> i64 {
        0
    }
    /// The snapshot as JSON text.
    pub fn to_json(&self) -> String {
        godot_json::stringify(&Variant::Dictionary(self.raw.clone()))
    }
}

/// A slot's buff (rulebook 8.5) and permanent Renown.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SlotView {
    pub attack: i64,
    pub health: i64,
    pub renown: i64,
    pub keywords: Vec<String>,
}

/// A named card heap: entries (card id, tier, n), oldest first.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HeapView {
    pub name: String,
    pub entries: Vec<(String, i64, i64)>,
    pub next_n: i64,
}

/// A standing effect a player has (a tribe-wide rule).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StandingView {
    pub id: String,
    pub granted: bool,
}

/// What every player shows: health, armor, tier, alive, placement.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PlayerSummary {
    pub id: i64,
    pub health: i64,
    pub armor: i64,
    pub tier: i64,
    pub alive: bool,
    /// Final place, 0 while still playing.
    pub placement: i64,
}

/// A player's fight payload (`RecordState.fight_players` shape): board, hand, slots, counters,
/// heaps, standing effects and tier. Ghosts have id -1. Clone is a deep copy.
#[derive(Debug)]
pub struct Payload {
    raw: Dictionary,
}

impl Clone for Payload {
    fn clone(&self) -> Self {
        Self {
            raw: copy::deep_dict(&self.raw),
        }
    }
}

impl Payload {
    pub(crate) fn from_raw(raw: Dictionary) -> Self {
        Self { raw }
    }
    pub(crate) fn raw(&self) -> &Dictionary {
        &self.raw
    }
    pub fn id(&self) -> i64 {
        self.raw.get("id").as_i64()
    }
    pub fn is_ghost(&self) -> bool {
        self.id() < 0
    }
    pub fn tier(&self) -> i64 {
        self.raw.get("tier").as_i64()
    }
    pub fn board(&self) -> Vec<Option<SnapUnit>> {
        self.raw
            .get("board")
            .as_array()
            .borrow()
            .iter()
            .map(|raw| match raw {
                Variant::Dictionary(d) => Some(SnapUnit::from_raw(copy::deep_dict(d))),
                _ => None,
            })
            .collect()
    }
    pub fn hand(&self) -> Vec<SnapUnit> {
        self.raw
            .get("hand")
            .as_array()
            .borrow()
            .iter()
            .map(|raw| SnapUnit::from_raw(copy::deep_dict(&raw.as_dict())))
            .collect()
    }
    pub fn slots(&self) -> Vec<SlotView> {
        self.raw
            .get("slots")
            .as_array()
            .borrow()
            .iter()
            .map(|s| slot_view(&s.as_dict()))
            .collect()
    }
    pub fn counters(&self) -> Vec<(String, i64)> {
        int_pairs(&self.raw.get("counters").as_dict())
    }
    pub fn heaps(&self) -> Vec<HeapView> {
        heap_views(&self.raw.get("heaps").as_dict())
    }
    pub fn standing(&self) -> Vec<StandingView> {
        standing_views(&self.raw.get("standing").as_array())
    }
    /// Sets the payload's seat id (0..7; -1 for a ghost).
    pub fn set_id(&mut self, id: i64) {
        self.raw.insert("id", id.into());
    }
    pub fn set_tier(&mut self, tier: i64) {
        self.raw.insert("tier", tier.into());
    }
    /// Puts `unit` (or nothing) on board position `slot` (0..6).
    pub fn set_board(&mut self, slot: usize, unit: Option<SnapUnit>) {
        let board = self.raw.get("board").as_array();
        if let Some(entry) = board.borrow_mut().get_mut(slot) {
            *entry = unit.map_or(Variant::Nil, |u| Variant::Dictionary(u.raw));
        }
    }
    pub fn set_hand(&mut self, hand: Vec<SnapUnit>) {
        self.raw.insert(
            "hand",
            Variant::array(
                hand.into_iter()
                    .map(|u| Variant::Dictionary(u.raw))
                    .collect(),
            ),
        );
    }
    pub fn set_slot(&mut self, slot: usize, view: &SlotView) {
        let slots = self.raw.get("slots").as_array();
        if let Some(entry) = slots.borrow_mut().get_mut(slot) {
            let out = Dictionary::new();
            out.insert("attack", view.attack.into());
            out.insert("health", view.health.into());
            out.insert(
                "keywords",
                Variant::array(view.keywords.iter().map(|k| k.as_str().into()).collect()),
            );
            *entry = Variant::Dictionary(out);
        }
    }
    /// The payload as JSON text, as a record's `fight_boards` entry holds it.
    pub fn to_json(&self) -> String {
        godot_json::stringify(&Variant::Dictionary(self.raw.clone()))
    }
    /// A payload from JSON text in the record shape (for bots' own stored boards).
    pub fn from_json(text: &str) -> Option<Self> {
        match godot_json::parse_string(text) {
            Variant::Dictionary(d) => Some(Self { raw: d }),
            _ => None,
        }
    }
}

/// A past opponent as it was when it fought this bot.
#[derive(Clone, Debug)]
pub struct PastFight {
    pub round: i64,
    /// The opponent's player id (-1: the ghost).
    pub opponent: i64,
    pub payload: Payload,
}

/// The bot's own player, in full.
#[derive(Clone, Debug)]
pub struct Me {
    pub id: i64,
    pub health: i64,
    pub armor: i64,
    pub gold: i64,
    pub gold_next_turn: i64,
    pub tier: i64,
    pub turns_waited: i64,
    pub refreshes_paid: i64,
    pub freezes_used: i64,
    pub frozen: bool,
    /// Shop card ids by slot; "" is an empty slot.
    pub shop_units: Vec<String>,
    pub shop_spells: Vec<String>,
    /// Price of each shop slot now (-1 for an empty slot).
    pub unit_prices: Vec<i64>,
    pub spell_prices: Vec<i64>,
    pub hand: Vec<UnitView>,
    /// One entry per board slot.
    pub board: Vec<Option<UnitView>>,
    pub discover_options: Vec<String>,
    pub discover_queue: Vec<(i64, i64)>,
    pub counters: Vec<(String, i64)>,
    pub heaps: Vec<HeapView>,
    pub slots: Vec<SlotView>,
    pub standing: Vec<StandingView>,
    pub alive: bool,
    pub turn_ended: bool,
    /// Opponents faced, latest last (-1: the ghost).
    pub opponents: Vec<i64>,
    pub placement: i64,
    pub refresh_cost: i64,
    pub refreshes_left: i64,
    /// Upgrade cost now; -1 at the top tier.
    pub upgrade_cost: i64,
    pub hand_limit: i64,
    pub freeze_limit: i64,
    /// Base hand Reserve limit, before modifiers from the combat board.
    pub reserve_limit: i64,
    /// Options a Discover shows.
    pub discover_count: i64,
    payload: Payload,
}

impl Me {
    /// Board units in slot order (`PlayerState.board_units`).
    pub fn board_units(&self) -> impl Iterator<Item = &UnitView> {
        self.board.iter().flatten()
    }
    pub fn board_count(&self) -> i64 {
        self.board_units().count() as i64
    }
    pub fn empty_slots(&self) -> Vec<i64> {
        (0..self.board.len() as i64)
            .filter(|&i| self.board[i as usize].is_none())
            .collect()
    }
    /// Board units then hand (`PlayerState.all_cards`).
    pub fn all_cards(&self) -> impl Iterator<Item = &UnitView> {
        self.board_units().chain(self.hand.iter())
    }
    /// Hand first, then board (`PlayerState.find_uid`).
    pub fn find_uid(&self, uid: i64) -> Option<&UnitView> {
        self.hand
            .iter()
            .chain(self.board_units())
            .find(|u| u.uid == uid)
    }
    pub fn counter(&self, key: &str) -> i64 {
        self.counters
            .iter()
            .find(|(k, _)| k == key)
            .map_or(0, |(_, v)| *v)
    }
    /// This player as a fight payload, as it stands now.
    pub fn payload(&self) -> &Payload {
        &self.payload
    }
}

/// Everything a bot may know at one decision. Built fresh by the harness for every call.
#[derive(Clone, Debug)]
pub struct BotView {
    pub(crate) round: i64,
    pub(crate) me: Me,
    pub(crate) players: Vec<PlayerSummary>,
    pub(crate) opponent: i64,
    pub(crate) past: Rc<Vec<PastFight>>,
    pub(crate) library: Rc<Library>,
    pub(crate) legal: Vec<Action>,
    pub(crate) clock_left_ns: i64,
}

impl BotView {
    pub fn round(&self) -> i64 {
        self.round
    }
    pub fn me(&self) -> &Me {
        &self.me
    }
    /// Every player's public numbers, by id.
    pub fn players(&self) -> &[PlayerSummary] {
        &self.players
    }
    /// Who this player fights this round (-1: the ghost, -2: nobody).
    pub fn opponent(&self) -> i64 {
        self.opponent
    }
    /// Each past opponent's payload as it was when they fought, oldest first.
    pub fn past(&self) -> &[PastFight] {
        &self.past
    }
    /// The latest payload seen of player `id` (from a fight against it), if any.
    pub fn last_payload_of(&self, id: i64) -> Option<&PastFight> {
        self.past.iter().rev().find(|f| f.opponent == id)
    }
    pub fn library(&self) -> &Library {
        &self.library
    }
    /// The legal actions, in `LegalActions.of` order. `Bot::choose` returns an index into this.
    pub fn legal(&self) -> &[Action] {
        &self.legal
    }
    /// CPU time left on this seat's clock for this game, at the start of this call, in ns.
    /// `Sim::clock_left_ns` reads it live.
    pub fn clock_left_ns(&self) -> i64 {
        self.clock_left_ns
    }
}

// ---- builders (harness side) ----

fn int_pairs(dict: &Dictionary) -> Vec<(String, i64)> {
    dict.borrow()
        .iter()
        .map(|(k, v)| (k.clone(), v.as_i64()))
        .collect()
}

fn slot_view(raw: &Dictionary) -> SlotView {
    SlotView {
        attack: raw.get("attack").as_i64(),
        health: raw.get("health").as_i64(),
        renown: raw.get("renown").as_i64(),
        keywords: raw
            .get("keywords")
            .as_array()
            .borrow()
            .iter()
            .map(Variant::as_text)
            .collect(),
    }
}

fn heap_views(raw: &Dictionary) -> Vec<HeapView> {
    raw.borrow()
        .iter()
        .map(|(name, heap)| {
            let heap = heap.as_dict();
            HeapView {
                name: name.clone(),
                entries: heap
                    .get("entries")
                    .as_array()
                    .borrow()
                    .iter()
                    .map(|e| {
                        let e = e.as_dict();
                        (
                            e.get("id").as_text(),
                            e.get("tier").as_i64(),
                            e.get("n").as_i64(),
                        )
                    })
                    .collect(),
                next_n: heap.get("_next_n").as_i64(),
            }
        })
        .collect()
}

fn standing_views(raw: &Array<Variant>) -> Vec<StandingView> {
    raw.borrow()
        .iter()
        .map(|s| {
            let s = s.as_dict();
            StandingView {
                id: s.get("id").as_text(),
                granted: matches!(s.get("granted"), Variant::Bool(true)),
            }
        })
        .collect()
}

pub(crate) fn library_of(
    library: &UnitLibraryRef,
    config: &Dictionary,
    slot_count: i64,
) -> Library {
    let mut cards = Vec::new();
    let mut by_id = BTreeMap::new();
    let lib = library.borrow();
    for id in lib.ids().borrow().iter() {
        let Some(card) = lib.get_card(id) else {
            continue;
        };
        let c = card.borrow();
        let texts = |a: &Array<String>| a.borrow().clone();
        by_id.insert(c.id.clone(), cards.len());
        cards.push(CardInfo {
            id: c.id.clone(),
            name: c.name.clone(),
            tier: c.tier,
            attack: c.attack,
            health: c.health,
            spell: c.is_spell(),
            types: texts(&c.types),
            tribes: texts(&c.tribes),
            keywords: texts(&c.keywords),
            mechanics: c
                .mechanics
                .borrow()
                .iter()
                .map(|m| m.borrow().id.clone())
                .collect(),
            token: c.token,
            combines: c.combines,
            cost: c.cost,
            offered: c.offered,
            text: c.text.clone(),
            golden_text: c.golden_text.clone(),
        });
    }
    let mut ints = BTreeMap::new();
    let mut lists = BTreeMap::new();
    for (key, value) in config.borrow().iter() {
        match value {
            Variant::Array(items) => {
                lists.insert(
                    key.clone(),
                    items.borrow().iter().map(Variant::as_i64).collect(),
                );
            }
            other => {
                ints.insert(key.clone(), other.as_i64());
            }
        }
    }
    Library {
        cards,
        by_id,
        ints,
        lists,
        slot_count,
    }
}

/// The library and rules numbers of a session.
pub(crate) fn library_of_game(game: &GameSessionRef) -> Library {
    let g = game.borrow();
    let config = RecordState::fields(&*g.config.as_ref().expect("config").borrow(), &[]);
    let slots = g.geometry.as_ref().expect("geometry").borrow().slot_count;
    library_of(g.library.as_ref().expect("library"), &config, slots)
}

fn unit_view(game: &GameSessionRef, player: &PlayerStateRef, unit: &UnitRef) -> UnitView {
    let rules = game.borrow().rules.as_ref().expect("rules").clone();
    let sell_value = rules.borrow().sell_value(player, unit);
    // FightSnapshot.unit builds every container new.
    let snapshot = SnapUnit::from_raw(
        bramble_engine::core::records::fight_snapshot::FightSnapshot::unit(unit),
    );
    let u = unit.borrow();
    let def = u.def.as_ref().expect("unit def").borrow();
    UnitView {
        uid: u.uid,
        def: def.id.clone(),
        tier: def.tier,
        golden: u.golden,
        spell: def.is_spell(),
        slot: u.slot,
        attack: u.attack(),
        health: u.health(),
        worked_this_turn: u.worked_this_turn,
        copies: u.copies,
        bought_copies: u.bought_copies,
        pool_copies: 0,
        keywords: u.keyword_ids().borrow().clone(),
        mechanics: u
            .hooks()
            .borrow()
            .iter()
            .map(|b| b.borrow().id.clone())
            .collect(),
        counters: int_pairs(&u.counters),
        supply_left: u
            .counters
            .borrow()
            .iter()
            .filter(|(key, _)| key.starts_with("supply:"))
            .map(|(_, left)| left.as_i64())
            .sum(),
        turn_counters: int_pairs(&u.turn_counters),
        sell_value,
        snapshot,
    }
}

pub(crate) fn me_of(game: &GameSessionRef, player: &PlayerStateRef) -> Me {
    let rules = game.borrow().rules.as_ref().expect("rules").clone();
    let library = game.borrow().library.as_ref().expect("library").clone();
    let prices = |spell: bool| -> Vec<i64> {
        let p = player.borrow();
        let shop = if spell {
            p.shop_spells.clone()
        } else {
            p.shop_units.clone()
        };
        drop(p);
        shop.borrow()
            .iter()
            .map(|id| {
                if id.is_empty() {
                    return -1;
                }
                let Some(card) = library.borrow().get_card(id) else {
                    return -1;
                };
                if spell {
                    rules.borrow().spell_price(player, &card, None)
                } else {
                    rules.borrow().unit_price(player, &card, None)
                }
            })
            .collect()
    };
    let unit_prices = prices(false);
    let spell_prices = prices(true);
    let hand_units = player.borrow().hand.to_vec();
    let board_units = player.borrow().board.to_vec();
    let hand: Vec<UnitView> = hand_units
        .iter()
        .map(|u| unit_view(game, player, u))
        .collect();
    let board: Vec<Option<UnitView>> = board_units
        .iter()
        .map(|u| u.as_ref().map(|u| unit_view(game, player, u)))
        .collect();
    let r = rules.borrow();
    let (refresh_cost, refreshes_left, upgrade_cost, hand_limit, freeze_limit, discover_count) = (
        r.refresh_cost(player, None),
        r.refreshes_left(player),
        r.upgrade_cost(player, None),
        r.hand_limit(player),
        r.freeze_limit(player),
        r.discover_options(player),
    );
    drop(r);
    let p = player.borrow();
    let texts = |a: &Array<String>| a.borrow().clone();
    // The payload shares the unit snapshots just made (read-only inside this Me; every
    // clone a bot makes is deep).
    let raw = Dictionary::new();
    raw.insert("id", p.id.into());
    raw.insert("tier", p.tier.into());
    raw.insert("slots", p.slots.to_state());
    raw.insert("counters", p.counters.to_state());
    raw.insert("heaps", p.heaps.to_state());
    raw.insert("standing", p.standing.to_state());
    let snap = |u: &UnitView| Variant::Dictionary(u.snapshot.raw.clone());
    raw.insert(
        "board",
        Variant::array(
            board
                .iter()
                .map(|u: &Option<UnitView>| u.as_ref().map_or(Variant::Nil, snap))
                .collect(),
        ),
    );
    raw.insert("hand", Variant::array(hand.iter().map(snap).collect()));
    let payload = Payload::from_raw(raw);
    Me {
        id: p.id,
        health: p.health,
        armor: p.armor,
        gold: p.gold,
        gold_next_turn: p.gold_next_turn,
        tier: p.tier,
        turns_waited: p.turns_waited,
        refreshes_paid: p.refreshes_paid,
        freezes_used: p.freezes_used,
        frozen: p.frozen,
        shop_units: texts(&p.shop_units),
        shop_spells: texts(&p.shop_spells),
        unit_prices,
        spell_prices,
        hand,
        board,
        discover_options: texts(&p.discover_options),
        discover_queue: p.discover_queue.borrow().clone(),
        counters: int_pairs(&p.counters),
        // Reuse the newly serialized payload containers; these views own their
        // scalar/string copies and neither representation aliases the live player.
        heaps: payload.heaps(),
        slots: payload.slots(),
        standing: payload.standing(),
        alive: p.alive,
        turn_ended: p.turn_ended,
        opponents: p.opponents.borrow().clone(),
        placement: p.placement,
        refresh_cost,
        refreshes_left,
        upgrade_cost,
        hand_limit,
        freeze_limit,
        reserve_limit: game
            .borrow()
            .config
            .as_ref()
            .unwrap()
            .borrow()
            .reserve_limit,
        discover_count,
        payload,
    }
}

pub(crate) fn summaries_of(game: &GameSessionRef) -> Vec<PlayerSummary> {
    game.borrow()
        .players
        .borrow()
        .iter()
        .map(|p| {
            let p = p.borrow();
            PlayerSummary {
                id: p.id,
                health: p.health,
                armor: p.armor,
                tier: p.tier,
                alive: p.alive,
                placement: p.placement,
            }
        })
        .collect()
}

/// The legal actions as the engine gives them (dictionaries) and typed.
pub(crate) fn legal_of(game: &GameSessionRef, player_id: i64) -> (Vec<Dictionary>, Vec<Action>) {
    let player = game.borrow().player(player_id);
    let raw = LegalActions::of(game, &player).to_vec();
    let typed = raw.iter().map(Action::from_dict).collect();
    (raw, typed)
}

pub(crate) fn typed_legal_of(game: &GameSessionRef, player_id: i64) -> Vec<Action> {
    let player = game.borrow().player(player_id);
    // Same engine loops as legal_of; dictionaries are only needed when recording actions.
    LegalActions::of_into(game, &player).to_vec()
}

pub(crate) fn payload_list(game: &GameSessionRef) -> Vec<Payload> {
    RecordState::fight_players(&game.borrow())
        .borrow()
        .iter()
        .map(|p| Payload::from_raw(p.as_dict()))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use bramble_engine::core::session::game_session::GameSession;
    use bramble_engine::game::game_content::GameContent;
    use std::path::Path;

    #[test]
    fn typed_legal_actions_match_dictionary_order_for_every_card() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../..");
        let content = GameContent::load_default(&root);
        let game = content.borrow().new_session(42, &Array::new());
        game.borrow_mut().record_recipe.clear();
        GameSession::start_round(&game);
        let player = game.borrow().player(0);
        let ids = content.borrow().library.borrow().ids();
        for id in ids.borrow().iter() {
            let card = content.borrow().library.borrow().get_card(id).unwrap();
            let unit = game.borrow_mut().new_unit(&card, false);
            {
                let mut p = player.borrow_mut();
                p.gold = 100;
                p.tier = 6;
                p.hand.clear();
                p.board.borrow_mut().fill(None);
                p.hand.push(unit.clone());
            }
            let (raw, parsed) = legal_of(&game, 0);
            let direct = typed_legal_of(&game, 0);
            assert_eq!(direct, parsed, "hand {id}");
            for (dict, action) in raw.iter().zip(&direct) {
                let rebuilt = action.to_dict();
                assert_eq!(
                    dict.borrow().keys().collect::<Vec<_>>(),
                    rebuilt.borrow().keys().collect::<Vec<_>>()
                );
                assert_eq!(
                    godot_json::stringify(&Variant::Dictionary(dict.clone())),
                    godot_json::stringify(&Variant::Dictionary(rebuilt))
                );
            }
            if !unit.borrow().is_spell() {
                player.borrow().hand.clear();
                player.borrow_mut().place(&unit, 0);
                assert_eq!(typed_legal_of(&game, 0), legal_of(&game, 0).1, "board {id}");
            }
        }
        let option = content
            .borrow()
            .library
            .borrow()
            .drawable_cards(false)
            .get(0)
            .unwrap();
        player
            .borrow()
            .discover_options
            .push(option.borrow().id.clone());
        assert_eq!(typed_legal_of(&game, 0), legal_of(&game, 0).1);
        player.borrow_mut().turn_ended = true;
        assert_eq!(typed_legal_of(&game, 0), legal_of(&game, 0).1);
    }
}
