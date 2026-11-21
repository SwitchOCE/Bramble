//! Deep copies between live engine objects and owned JSON-shaped data. Nothing returned here
//! shares storage with a live game: every Array and Dictionary is rebuilt.
use bramble_engine::core::{
    records::fight_snapshot::FightSnapshot, recruit::player_state::PlayerState,
    session::game_session::GameSession,
};
use bramble_engine::{Array, Dictionary, ToState, Variant};

/// A recursive copy: no Array or Dictionary in the result is shared with `value`.
pub fn deep(value: &Variant) -> Variant {
    value.duplicate_deep()
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
    add_waiting_pile(player, &entry);
    entry
}

pub(crate) fn add_waiting_pile(player: &PlayerState, entry: &Dictionary) {
    if !player.waiting_pile.is_empty() {
        let pile = player.waiting_pile.iter_live().map(Some).collect();
        entry.insert("waiting_pile", Variant::Array(FightSnapshot::units(&pile)));
    }
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
    let choices: Array<_> = player
        .recruit_choices
        .iter_live()
        .map(|u| u.borrow().uid)
        .collect();
    entry.insert("recruit_choices", choices.to_state());
    entry.insert("opponents", player.opponents.to_state());
    entry
}

/// Restores a fight payload onto the player identified by its saved seat.
pub fn restore_payload(game: &mut GameSession, saved: &Dictionary) {
    let player = game.player(saved.get("id").as_i64());
    FightSnapshot::restore_player(saved, &mut player.borrow_mut(), game, 0);
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
    p.recruit_choices = saved
        .get("recruit_choices")
        .as_array()
        .iter_live()
        .filter_map(|uid| p.find_uid(uid.as_i64()))
        .collect();
    p.opponents = saved
        .get("opponents")
        .as_array()
        .borrow()
        .iter()
        .map(Variant::as_i64)
        .collect();
}
