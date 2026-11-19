//! Deep copies between live engine objects and owned JSON-shaped data. Nothing returned here
//! shares storage with a live game: every Array and Dictionary is rebuilt.
use bramble_engine::core::{
    mechanics::{bound_mechanic::BoundMechanic, mechanic_params::MechanicParams},
    records::fight_snapshot::FightSnapshot,
    recruit::player_state::PlayerState,
    session::game_session::GameSession,
    state::card_heap::CardHeap,
};
use bramble_engine::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};

/// A recursive copy: no Array or Dictionary in the result is shared with `value`.
pub fn deep(value: &Variant) -> Variant {
    match value {
        Variant::Array(items) => Variant::array(items.borrow().iter().map(deep).collect()),
        Variant::Dictionary(dict) => Variant::Dictionary(deep_dict(dict)),
        other => other.clone(),
    }
}

pub fn deep_dict(dict: &Dictionary) -> Dictionary {
    dict.borrow()
        .iter()
        .map(|(key, value)| (key.clone(), deep(value)))
        .collect()
}

/// `RecordState.fight_players`' entry for one living player. `ToState` and `FightSnapshot`
/// build new containers all the way down, so nothing in it is shared with the player.
pub fn fight_payload(player: &PlayerState) -> Dictionary {
    let entry = Dictionary::new();
    entry.insert("id", player.id.into());
    entry.insert("tier", player.tier.into());
    entry.insert("slots", player.slots.to_state());
    entry.insert("counters", player.counters.to_state());
    entry.insert("heaps", player.heaps.to_state());
    entry.insert("standing", player.standing.to_state());
    entry.insert("board", Variant::Array(FightSnapshot::units(&player.board)));
    let hand: Array<Option<_>> = player.hand.borrow().iter().cloned().map(Some).collect();
    entry.insert("hand", Variant::Array(FightSnapshot::units(&hand)));
    entry
}

/// Every field of a player a full copy needs: the fight payload plus the recruit fields.
pub fn full_player(player: &PlayerState) -> Dictionary {
    let entry = fight_payload(player);
    for (key, value) in [
        ("health", player.health),
        ("armor", player.armor),
        ("gold", player.gold),
        ("gold_next_turn", player.gold_next_turn),
        ("turns_waited", player.turns_waited),
        ("refreshes_paid", player.refreshes_paid),
        ("freezes_used", player.freezes_used),
        ("eliminated_round", player.eliminated_round),
        ("placement", player.placement),
    ] {
        entry.insert(key, value.into());
    }
    entry.insert("frozen", player.frozen.into());
    entry.insert("alive", player.alive.into());
    entry.insert("turn_ended", player.turn_ended.into());
    entry.insert("shop_units", player.shop_units.to_state());
    entry.insert("shop_spells", player.shop_spells.to_state());
    entry.insert("discover_options", player.discover_options.to_state());
    entry.insert("discover_queue", player.discover_queue.to_state());
    entry.insert("opponents", player.opponents.to_state());
    entry
}

/// Restores a fight payload onto `game`'s player `saved.id`, as FORMAT.md's runner does
/// (mirrors `bramble-fight`'s `restore_player`). `saved` must be a private deep copy: restored
/// units keep references to its counter dictionaries.
pub fn restore_payload(game: &mut GameSession, saved: &Dictionary) {
    let owner = game.player(saved.get("id").as_i64());
    owner.borrow_mut().tier = saved.get("tier").as_i64();
    owner.borrow_mut().counters = deep_dict(&saved.get("counters").as_dict());
    for (slot, raw) in saved
        .get("board")
        .as_array()
        .to_vec()
        .into_iter()
        .enumerate()
    {
        if raw != Variant::Nil {
            let card = FightSnapshot::restore_unit(&raw.as_dict(), game, slot as i64);
            game._next_uid = game._next_uid.max(card.borrow().uid + 1);
            owner.borrow().board.borrow_mut()[slot] = Some(card);
        }
    }
    for raw in saved.get("hand").as_array().to_vec() {
        let card = FightSnapshot::restore_unit(&raw.as_dict(), game, -1);
        game._next_uid = game._next_uid.max(card.borrow().uid + 1);
        owner.borrow().hand.push(card);
    }
    for (i, raw) in saved
        .get("slots")
        .as_array()
        .to_vec()
        .into_iter()
        .enumerate()
    {
        let saved_slot = raw.as_dict();
        let slot = owner.borrow().slots.get(i).expect("slot state");
        slot.borrow_mut().attack = saved_slot.get("attack").as_i64();
        slot.borrow_mut().health = saved_slot.get("health").as_i64();
        slot.borrow_mut().renown = saved_slot.get("renown").as_i64();
        slot.borrow().keywords.clear();
        for keyword in saved_slot.get("keywords").as_array().to_vec() {
            slot.borrow().keywords.push(keyword.as_text());
        }
    }
    owner.borrow().heaps.clear();
    for (key, raw) in saved.get("heaps").as_dict().borrow().iter() {
        let raw = raw.as_dict();
        let mut heap = CardHeap::new();
        heap._next_n = raw.get("_next_n").as_i64();
        for raw in raw.get("entries").as_array().to_vec() {
            let entry = raw.as_dict();
            let restored = Dictionary::new();
            restored.insert("id", entry.get("id").as_text().into());
            restored.insert("tier", entry.get("tier").as_i64().into());
            restored.insert("n", entry.get("n").as_i64().into());
            heap.entries.push(restored);
        }
        owner
            .borrow()
            .heaps
            .borrow_mut()
            .insert(key.clone(), Rc::new(RefCell::new(heap)));
    }
    owner.borrow().standing.clear();
    for raw in saved.get("standing").as_array().to_vec() {
        let raw = raw.as_dict();
        let fields = raw.get("params").as_dict();
        let params = MechanicParams::new();
        {
            let mut params = params.borrow_mut();
            params.golden = matches!(fields.get("golden"), Variant::Bool(true));
            params._ints = integer_fields(&fields.get("_ints").as_dict());
            params._kinds = integer_fields(&fields.get("_kinds").as_dict());
            params._golden_ints = integer_fields(&fields.get("_golden_ints").as_dict());
            params._texts = fields
                .get("_texts")
                .as_dict()
                .borrow()
                .iter()
                .map(|(key, value)| (key.clone(), value.as_text()))
                .collect();
        }
        let id = raw.get("id").as_text();
        let registry = game.registry.as_ref().expect("session registry");
        owner.borrow().standing.push(BoundMechanic::new(
            &id,
            registry.borrow().get_mechanic(&id),
            params,
            matches!(raw.get("granted"), Variant::Bool(true)),
        ));
    }
}

/// Restores a `full_player` copy: the payload, then every recruit field.
pub fn restore_full(game: &mut GameSession, saved: &Dictionary) {
    restore_payload(game, saved);
    let owner = game.player(saved.get("id").as_i64());
    let mut p = owner.borrow_mut();
    let int = |key: &str| saved.get(key).as_i64();
    let flag = |key: &str| matches!(saved.get(key), Variant::Bool(true));
    let texts = |key: &str| -> Array<String> {
        saved
            .get(key)
            .as_array()
            .borrow()
            .iter()
            .map(Variant::as_text)
            .collect()
    };
    p.health = int("health");
    p.armor = int("armor");
    p.gold = int("gold");
    p.gold_next_turn = int("gold_next_turn");
    p.turns_waited = int("turns_waited");
    p.refreshes_paid = int("refreshes_paid");
    p.freezes_used = int("freezes_used");
    p.eliminated_round = int("eliminated_round");
    p.placement = int("placement");
    p.frozen = flag("frozen");
    p.alive = flag("alive");
    p.turn_ended = flag("turn_ended");
    p.shop_units = texts("shop_units");
    p.shop_spells = texts("shop_spells");
    p.discover_options = texts("discover_options");
    p.discover_queue = saved
        .get("discover_queue")
        .as_array()
        .borrow()
        .iter()
        .map(|pair| {
            let pair = pair.as_array();
            (
                pair.get(0).unwrap_or_default().as_i64(),
                pair.get(1).unwrap_or_default().as_i64(),
            )
        })
        .collect();
    p.opponents = saved
        .get("opponents")
        .as_array()
        .borrow()
        .iter()
        .map(Variant::as_i64)
        .collect();
}

fn integer_fields(raw: &Dictionary) -> Dictionary<i64> {
    raw.borrow()
        .iter()
        .map(|(key, value)| (key.clone(), value.as_i64()))
        .collect()
}
