//! The baseline bots, ported line by line from GDScript and played through the same `BotView`
//! a team bot gets: `SimpleBot` (src/core/bots/simple_bot.gd), `FlowBot`
//! (src/game/flow_bot.gd), `RandomBot` (src/core/bots/random_bot.gd) and the tribe-locked
//! `TribeBot` (tools/league/gd/tribe_bot.gd).
//! With the same `Rng` stream they make the same choices as GDScript (floats are f64 in both).
//!
//! GDScript returns an action dictionary; here an index into `view.legal()`. `None` stands for
//! GDScript's literal `{"type": "end_turn"}`, which maps to the legal list's end_turn.
use league_api::{Action, Bot, BotSetup, BotView, CardInfo, Rng, Sim, UnitView};

/// Index of `choice`, or of the legal end_turn for `None`.
fn index_of(view: &BotView, choice: Option<usize>) -> usize {
    choice.unwrap_or_else(|| {
        view.legal()
            .iter()
            .position(|a| *a == Action::EndTurn)
            .unwrap_or(0)
    })
}

fn kind_of(view: &BotView, choice: Option<usize>) -> &'static str {
    choice.map_or("end_turn", |i| view.legal()[i].kind())
}

// ---- SimpleBot ----

pub struct SimpleBot {
    #[allow(dead_code)]
    rng: Rng,
}

impl SimpleBot {
    pub const MAX_REFRESHES: i64 = 3;
    pub fn new(rng: Rng) -> Self {
        Self { rng }
    }

    fn pick(&self, view: &BotView) -> Option<usize> {
        let me = view.me();
        let mut best: Option<usize> = None;
        let mut best_score = 0.0_f64;
        let mut refresh: Option<usize> = None;
        let mut will_buy = false;
        for (i, action) in view.legal().iter().enumerate() {
            if *action == Action::Refresh {
                refresh = Some(i);
                continue;
            }
            let score = score(view, action);
            will_buy = will_buy || (action.kind() == "buy" && score > 0.0);
            if score > best_score {
                best_score = score;
                best = Some(i);
            }
        }
        let may_refresh = me.refreshes_paid < Self::MAX_REFRESHES && me.gold >= 3;
        if best_score <= 0.0 && refresh.is_some() && !will_buy && may_refresh {
            return refresh;
        }
        best
    }
}

impl Bot for SimpleBot {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        index_of(view, self.pick(view))
    }
}

pub fn score(view: &BotView, action: &Action) -> f64 {
    let me = view.me();
    let lib = view.library();
    match action {
        Action::RecruitTarget { target } => {
            100.0 + unit_worth(me.find_uid(*target).expect("recruit target"))
        }
        Action::Pick { index } | Action::PickTarget { index, .. } => {
            let option = lib
                .get(&me.discover_options[*index as usize])
                .expect("discover card");
            100.0 + worth(option)
        }
        Action::Upgrade => upgrade_score(view),
        Action::Play { hand, slot, target } => play_score(view, *hand, *slot, *target),
        Action::Buy { spell, index } | Action::BuyTarget { spell, index, .. } => {
            buy_score(view, *spell, *index)
        }
        Action::Sell { slot } => sell_score(view, *slot),
        Action::Ability { .. } => 2.0, // an ability a card offers is worth using
        _ => -1.0,
    }
}

/// Tier first, stats second.
pub fn worth(card: &CardInfo) -> f64 {
    card.tier as f64 * 10.0 + (card.attack + card.health) as f64 * 0.1
}

pub fn unit_worth(unit: &UnitView) -> f64 {
    (unit.tier + if unit.golden { 2 } else { 0 }) as f64 * 10.0
        + (unit.attack + unit.health) as f64 * 0.1
}

fn upgrade_score(view: &BotView) -> f64 {
    let me = view.me();
    let cost = me.upgrade_cost;
    if cost == 0 {
        return 90.0;
    }
    let goal = 1 + (view.round() + 1) / 2;
    if me.tier < goal { 60.0 } else { -1.0 }
}

fn play_score(view: &BotView, hand: i64, slot: i64, target: i64) -> f64 {
    let me = view.me();
    let card = &me.hand[hand as usize];
    let mut score = if card.spell {
        45.0
    } else {
        50.0 + card.tier as f64
    };
    if slot >= 0 {
        score -= slot as f64 * 0.1;
    }
    if let Some(target) = me.find_uid(target) {
        score += target.attack as f64 * 0.001;
    }
    score
}

fn buy_score(view: &BotView, spell: bool, index: i64) -> f64 {
    let me = view.me();
    if spell {
        return if me.board_count() > 0 { 20.0 } else { -1.0 };
    }
    let card = view
        .library()
        .get(&me.shop_units[index as usize])
        .expect("shop card");
    let mut held = 0;
    let mut units_in_hand = 0;
    for unit in me.all_cards() {
        if unit.def == card.id && !unit.golden {
            held += 1;
        }
        if unit.slot < 0 && !unit.spell {
            units_in_hand += 1;
        }
    }
    let room = me.board_count() + units_in_hand < view.library().slot_count();
    let weakest = weakest(view);
    if !room && weakest.is_none_or(|w| worth(card) <= unit_worth(w) + 5.0) {
        return if held > 0 { 15.0 * held as f64 } else { -1.0 };
    }
    40.0 + worth(card) * 0.1 + 15.0 * held as f64
}

fn sell_score(view: &BotView, slot: i64) -> f64 {
    let me = view.me();
    if !me.empty_slots().is_empty() {
        return -1.0;
    }
    let Some(weakest) = weakest(view) else {
        return -1.0;
    };
    if weakest.slot != slot {
        return -1.0;
    }
    for unit in &me.hand {
        if !unit.spell && unit_worth(unit) > unit_worth(weakest) {
            return 35.0;
        }
    }
    -1.0
}

fn weakest(view: &BotView) -> Option<&UnitView> {
    let mut weakest: Option<&UnitView> = None;
    for unit in view.me().board_units() {
        if weakest.is_none_or(|w| unit_worth(unit) < unit_worth(w)) {
            weakest = Some(unit);
        }
    }
    weakest
}

// ---- FlowBot ----

pub struct FlowBot {
    simple: SimpleBot,
    rng: Rng,
    abilities_used: i64,
    round_seen: i64,
}

impl FlowBot {
    pub const MAX_ABILITIES: i64 = 4;
    pub const MAX_SPARE_REFRESHES: i64 = 30;
    pub fn new(rng: Rng) -> Self {
        Self {
            simple: SimpleBot::new(Rng::new(0)),
            rng,
            abilities_used: 0,
            round_seen: -1,
        }
    }

    fn pick(&mut self, view: &BotView) -> Option<usize> {
        if view.round() != self.round_seen {
            self.round_seen = view.round();
            self.abilities_used = 0;
        }
        let mut best = self.simple.pick(view);
        let mut kind = kind_of(view, best);
        if kind == "ability" {
            if self.abilities_used < Self::MAX_ABILITIES {
                self.abilities_used += 1;
                return best;
            }
            best = None;
            kind = "end_turn";
        }
        if kind != "end_turn" && kind != "refresh" {
            return best;
        }
        self.spare(view, best)
    }

    fn spare(&mut self, view: &BotView, best: Option<usize>) -> Option<usize> {
        let legal = view.legal();
        let ability = first(legal, "ability");
        let mut out = best;
        if let Some(ability) = ability.filter(|_| self.abilities_used < Self::MAX_ABILITIES) {
            self.abilities_used += 1;
            out = Some(self.random_target(legal, ability));
        } else if let Some(upgrade) = first(legal, "upgrade") {
            out = Some(upgrade);
        } else if kind_of(view, best) == "end_turn" {
            let refresh = first(legal, "refresh");
            if refresh.is_some() && view.me().refreshes_paid < Self::MAX_SPARE_REFRESHES {
                out = refresh;
            }
        }
        out
    }

    /// One of the legal targets of the same unit's same ability, at random.
    fn random_target(&mut self, legal: &[Action], ability: usize) -> usize {
        let Action::Ability { uid, mechanic, .. } = &legal[ability] else {
            unreachable!()
        };
        let same: Vec<usize> = legal
            .iter()
            .enumerate()
            .filter(|(_, a)| matches!(a, Action::Ability { uid: u, mechanic: m, .. } if u == uid && m == mechanic))
            .map(|(i, _)| i)
            .collect();
        same[self.rng.index(same.len() as i64) as usize]
    }
}

fn first(legal: &[Action], kind: &str) -> Option<usize> {
    legal.iter().position(|a| a.kind() == kind)
}

impl Bot for FlowBot {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        let choice = self.pick(view);
        index_of(view, choice)
    }
}

// ---- RandomBot ----

pub struct RandomBot {
    rng: Rng,
}

impl RandomBot {
    pub const END_CHANCE: i64 = 8;
    pub fn new(rng: Rng) -> Self {
        Self { rng }
    }
}

impl Bot for RandomBot {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        let legal = view.legal();
        let mut types: Vec<&'static str> = Vec::new();
        let mut by_type: Vec<Vec<usize>> = Vec::new();
        for (i, action) in legal.iter().enumerate() {
            let kind = action.kind();
            if kind == "end_turn" {
                continue;
            }
            match types.iter().position(|t| *t == kind) {
                Some(k) => by_type[k].push(i),
                None => {
                    types.push(kind);
                    by_type.push(vec![i]);
                }
            }
        }
        let must_pick = types.contains(&"pick") || types.contains(&"recruit_target");
        if types.is_empty() || (!must_pick && self.rng.index(Self::END_CHANCE) == 0) {
            return index_of(view, None);
        }
        let options = &by_type[self.rng.index(types.len() as i64) as usize];
        options[self.rng.index(options.len() as i64) as usize]
    }
}

// ---- TribeBot (Pigeon and Mouse reworks) ----

pub const TRIBES: [&str; 5] = ["Badger", "Mouse", "Pigeon", "Locust", "Briar"];

pub struct TribeBot {
    #[allow(dead_code)]
    rng: Rng,
    pub tribe: String,
}

impl TribeBot {
    pub fn new(rng: Rng, wanted: &str) -> Self {
        Self {
            rng,
            tribe: wanted.to_owned(),
        }
    }

    fn pick(&self, view: &BotView) -> Option<usize> {
        let me = view.me();
        let lib = view.library();
        let mut best: Option<usize> = None;
        let mut best_score = 0.0_f64;
        let mut refresh: Option<usize> = None;
        let actions = view.legal();
        let held = held_reserves(view);
        let guard_post = me.slots.iter().position(|slot| {
            slot.keywords
                .iter()
                .any(|keyword| keyword == "pigeon_guard_post")
        });
        for (i, action) in actions.iter().enumerate() {
            if *action == Action::Refresh {
                refresh = Some(i);
                continue;
            }
            let mut score = score(view, action);
            if let Action::Buy {
                spell: false,
                index,
            }
            | Action::BuyTarget {
                spell: false,
                index,
                ..
            } = action
            {
                let card = lib.get(&me.shop_units[*index as usize]).expect("shop card");
                if !card.has_tribe(&self.tribe) {
                    score = -1.0;
                }
            }
            if matches!(
                action,
                Action::Buy { spell: true, .. } | Action::BuyTarget { spell: true, .. }
            ) {
                score = -1.0;
            }
            if let Action::Pick { index } | Action::PickTarget { index, .. } = action {
                let option = lib
                    .get(&me.discover_options[*index as usize])
                    .expect("discover card");
                if !option.has_tribe(&self.tribe) {
                    score = 1.0;
                }
            }
            if let Action::Play { hand, slot, .. } = action {
                if held.contains(&(*hand as usize)) {
                    continue;
                }
                score += row_pref(view, *hand, *slot);
            }
            if let Action::Sell { slot } = action
                && score > 0.0
                && !held.is_empty()
            {
                let sold = me.board[*slot as usize].as_ref().expect("sold unit");
                if !has_replacement(view, &held, sold) {
                    score = -1.0;
                }
            }
            if let Action::Ability {
                mechanic, target, ..
            } = action
            {
                match mechanic.as_str() {
                    "pigeon_lance_corporal" => score = 95.0,
                    "pigeon_grenadier" => {
                        // Keep the existing post, or choose the first legal slot to establish it.
                        score = if guard_post.is_none_or(|post| *target == post as i64) {
                            95.0
                        } else {
                            -1.0
                        };
                    }
                    _ => {}
                }
            }
            if score > best_score {
                best_score = score;
                best = Some(i);
            }
        }
        let mut keep = 0;
        let goal = 1 + (view.round() + 1) / 2;
        if me.tier < goal && me.tier < 6 {
            keep = me.upgrade_cost;
        }
        let may_refresh = me.refreshes_paid < 8 && me.gold >= 3 + keep;
        if best_score <= 0.0 && refresh.is_some() && may_refresh {
            return refresh;
        }
        if let Some(i) = best
            && matches!(actions[i], Action::Play { slot: 0.., .. })
        {
            return Some(play_at_best_renown(view, actions, i, best_score));
        }
        best
    }
}

fn held_reserves(view: &BotView) -> Vec<usize> {
    let me = view.me();
    let mut held = Vec::new();
    if me.board_count() < 5 {
        return held;
    }
    for (i, card) in me.hand.iter().enumerate() {
        if held.len() as i64 >= me.reserve_limit {
            break;
        }
        if !card.spell && card.mechanics.iter().any(|id| id == "pigeon_reserve") {
            held.push(i);
        }
    }
    held
}

#[cfg(test)]
mod tests {
    use super::*;
    use bramble_engine::Array;
    use league_api::harness;
    use std::rc::Rc;

    #[test]
    fn tribe_bot_holds_three_reservists_with_a_quartermaster() {
        let root = crate::default_root();
        let engine = crate::engine_for(&root, &|| crate::load_content(&root, None)).unwrap();
        let game = engine.content.borrow().new_session(1, &Array::new());
        let player = game.borrow().player(0);
        let library = game.borrow().library.as_ref().unwrap().clone();
        let new_unit = |id| {
            let card = library.borrow().get_card(id).unwrap();
            game.borrow_mut().new_unit(&card, false)
        };
        for slot in 0..5 {
            let unit = new_unit(if slot == 0 { "quartermaster" } else { "sentry" });
            unit.borrow_mut().slot = slot as i64;
            player.borrow().board.borrow_mut()[slot] = Some(unit);
        }
        for _ in 0..4 {
            player.borrow().hand.push(new_unit("territorial"));
        }
        let view = harness::view_typed(&game, 0, &Rc::new(Vec::new()), &engine.library, i64::MAX);
        assert_eq!(view.me().reserve_limit, 3);
        assert_eq!(held_reserves(&view), [0, 1, 2]);
    }
}

fn has_replacement(view: &BotView, held: &[usize], sold: &UnitView) -> bool {
    for (i, card) in view.me().hand.iter().enumerate() {
        if !held.contains(&i) && !card.spell && unit_worth(card) > unit_worth(sold) {
            return true;
        }
    }
    false
}

fn play_at_best_renown(
    view: &BotView,
    actions: &[Action],
    mut best: usize,
    mut best_score: f64,
) -> usize {
    // Keep the unit chosen by the usual scores; use those scores again for equal Renown.
    let Action::Play { hand, slot, .. } = actions[best] else {
        unreachable!()
    };
    let slots = &view.me().slots;
    let mut best_renown = slots[slot as usize].renown;
    for (i, action) in actions.iter().enumerate() {
        let Action::Play {
            hand: candidate,
            slot,
            target,
        } = *action
        else {
            continue;
        };
        if candidate != hand {
            continue;
        }
        let renown = slots[slot as usize].renown;
        let score = play_score(view, hand, slot, target) + row_pref(view, hand, slot);
        if renown > best_renown || (renown == best_renown && score > best_score) {
            best = i;
            best_renown = renown;
            best_score = score;
        }
    }
    best
}

fn row_pref(view: &BotView, hand: i64, slot: i64) -> f64 {
    let card = &view.me().hand[hand as usize];
    if card.spell {
        return 0.0;
    }
    if slot < 0 {
        return 0.0;
    }
    let def = view.library().get(&card.def).expect("hand card");
    let t = &def.text;
    let mut back = t.contains("in front of this")
        || t.contains("Squire")
        || t.contains("Can't attack")
        || t.contains("Pile on {")
        || t.contains("Your Hand-me-downs")
        || t.contains("more reservist")
        || t.contains("Reservists from your hand")
        || t.contains("Your reservists have")
        || t.contains("After a reservist steps in");
    if def.keywords.iter().any(|k| k == "taunt") {
        back = false;
    }
    if back {
        return if slot >= 4 { 1.0 } else { -1.0 };
    }
    if slot < 4 { 0.5 } else { 0.0 }
}

impl Bot for TribeBot {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        index_of(view, self.pick(view))
    }
}

// ---- TribeBotV1 (frozen at 0d74b43c) ----

pub struct TribeBotV1 {
    #[allow(dead_code)]
    rng: Rng,
    pub tribe: String,
}

impl TribeBotV1 {
    pub fn new(rng: Rng, wanted: &str) -> Self {
        Self {
            rng,
            tribe: wanted.to_owned(),
        }
    }

    fn pick(&self, view: &BotView) -> Option<usize> {
        let me = view.me();
        let lib = view.library();
        let mut best: Option<usize> = None;
        let mut best_score = 0.0_f64;
        let mut refresh: Option<usize> = None;
        for (i, action) in view.legal().iter().enumerate() {
            if *action == Action::Refresh {
                refresh = Some(i);
                continue;
            }
            let mut score = score(view, action);
            if let Action::Buy {
                spell: false,
                index,
            }
            | Action::BuyTarget {
                spell: false,
                index,
                ..
            } = action
            {
                let card = lib.get(&me.shop_units[*index as usize]).expect("shop card");
                if !card.has_tribe(&self.tribe) {
                    score = -1.0;
                }
            }
            if matches!(
                action,
                Action::Buy { spell: true, .. } | Action::BuyTarget { spell: true, .. }
            ) {
                score = -1.0;
            }
            if let Action::Pick { index } | Action::PickTarget { index, .. } = action {
                let option = lib
                    .get(&me.discover_options[*index as usize])
                    .expect("discover card");
                if !option.has_tribe(&self.tribe) {
                    score = 1.0;
                }
            }
            if let Action::Play { hand, slot, .. } = action {
                score += row_pref_v1(view, *hand, *slot);
            }
            if score > best_score {
                best_score = score;
                best = Some(i);
            }
        }
        let mut keep = 0;
        let goal = 1 + (view.round() + 1) / 2;
        if me.tier < goal && me.tier < 6 {
            keep = me.upgrade_cost;
        }
        let may_refresh = me.refreshes_paid < 8 && me.gold >= 3 + keep;
        if best_score <= 0.0 && refresh.is_some() && may_refresh {
            return refresh;
        }
        best
    }
}

fn row_pref_v1(view: &BotView, hand: i64, slot: i64) -> f64 {
    let card = &view.me().hand[hand as usize];
    if card.spell {
        return 0.0;
    }
    if slot < 0 {
        return 0.0;
    }
    let def = view.library().get(&card.def).expect("hand card");
    let t = &def.text;
    let mut back = t.contains("in front of this")
        || t.contains("Squire")
        || t.contains("Instead of")
        || t.contains("Can't attack")
        || t.contains("Start of fight: Hit");
    if def.keywords.iter().any(|k| k == "taunt") {
        back = false;
    }
    if back {
        return if slot >= 4 { 1.0 } else { -1.0 };
    }
    if slot < 4 { 0.5 } else { 0.0 }
}

impl Bot for TribeBotV1 {
    fn choose(&mut self, view: &BotView, _sim: &mut Sim) -> usize {
        index_of(view, self.pick(view))
    }
}

/// A bot's stream from its u64 seed (the engine's Rng seeds from 32 bits).
pub fn stream(seed: u64) -> Rng {
    Rng::new((seed ^ (seed >> 32)) as i64)
}

pub fn new_simple(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(SimpleBot::new(stream(seed)))
}
pub fn new_flow(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(FlowBot::new(stream(seed)))
}
pub fn new_random(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    Box::new(RandomBot::new(stream(seed)))
}
/// TribeBot with its tribe drawn from its seed. `league match` doesn't use this for the name
/// `tribe`: it gives each seat `tribe_of_seat`, as the balance pass did.
pub fn new_tribe(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    let tribe = TRIBES[((seed >> 40) % TRIBES.len() as u64) as usize];
    Box::new(TribeBot::new(stream(seed), tribe))
}
/// The balance pass's lobby (`tribe_lobby.gd`): seat `id` plays `TRIBES[(id + game_seed) % 5]`,
/// so five neighbouring seats always hold all five tribes.
pub fn tribe_of_seat(seat: usize, game_seed: i64) -> &'static str {
    TRIBES[(seat as i64 + game_seed).rem_euclid(TRIBES.len() as i64) as usize]
}
/// TribeBot of a given tribe, with its own stream from `seed`.
pub fn new_tribe_as(seed: u64, tribe: &'static str) -> Box<dyn Bot> {
    Box::new(TribeBot::new(stream(seed), tribe))
}
pub fn new_tribe_v1(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
    let tribe = TRIBES[((seed >> 40) % TRIBES.len() as u64) as usize];
    new_tribe_v1_as(seed, tribe)
}

pub fn new_tribe_v1_as(seed: u64, tribe: &'static str) -> Box<dyn Bot> {
    Box::new(TribeBotV1::new(stream(seed), tribe))
}

macro_rules! tribe_factory {
    ($name:ident, $bot:ident, $tribe:expr) => {
        pub fn $name(seed: u64, _setup: &BotSetup) -> Box<dyn Bot> {
            Box::new($bot::new(stream(seed), $tribe))
        }
    };
}
tribe_factory!(new_tribe_badger, TribeBot, "Badger");
tribe_factory!(new_tribe_mouse, TribeBot, "Mouse");
tribe_factory!(new_tribe_pigeon, TribeBot, "Pigeon");
tribe_factory!(new_tribe_locust, TribeBot, "Locust");
tribe_factory!(new_tribe_briar, TribeBot, "Briar");
tribe_factory!(new_tribe_v1_badger, TribeBotV1, "Badger");
tribe_factory!(new_tribe_v1_mouse, TribeBotV1, "Mouse");
tribe_factory!(new_tribe_v1_pigeon, TribeBotV1, "Pigeon");
tribe_factory!(new_tribe_v1_locust, TribeBotV1, "Locust");
tribe_factory!(new_tribe_v1_briar, TribeBotV1, "Briar");
