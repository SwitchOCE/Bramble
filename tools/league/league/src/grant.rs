//! Tool-only (`league ghost-match --grant <card>@<round> [--keep <rounds>]`): the live seat is
//! handed one fresh copy of a card at the start of its shop turn in one round, before its bot
//! acts, and for `keep` rounds the bot is not shown the actions that would take that copy off
//! its board. The copy enters the way a bought card played from the hand does, through the
//! engine's own gain and play (`Recruit::_gain`, then a play action); only the price is not
//! paid. The engine's rules code is untouched. A record could not say what was handed over, so
//! `ghost-match --grant` writes no records.
use crate::game::Engine;
use bramble_engine::Array;
use bramble_engine::core::{
    recruit::{player_state::PlayerStateRef, recruit::Recruit},
    session::game_session::{GameSession, GameSessionRef},
    units::unit::UnitRef,
};
use league_api::{Action, BotView, harness};
use serde_json::{Value, json};
use std::collections::BTreeMap;

/// What to hand over, when, and for how many rounds to hold it in place.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Grant {
    pub card: String,
    /// The round whose shop turn starts with the copy on the board.
    pub round: i64,
    /// Rounds, counting the grant round, in which the bot is not shown actions that take the
    /// copy off its board (selling it, returning it to the hand, swapping a hand card into its
    /// slot). 0: the bot may do anything with it at once.
    pub keep: i64,
}

impl Grant {
    /// `<card id>@<round>`, with the keep given apart.
    pub fn parse(text: &str, keep: i64) -> Result<Self, String> {
        let (card, round) = text
            .rsplit_once('@')
            .ok_or_else(|| format!("usage: --grant {text}: want <card id>@<round>"))?;
        let round: i64 = round
            .parse()
            .map_err(|_| format!("usage: --grant {text}: {round} is not a round number"))?;
        if card.trim().is_empty() || round < 1 {
            return Err(format!(
                "usage: --grant {text}: want <card id>@<round>, round 1 or later"
            ));
        }
        if keep < 0 {
            return Err("usage: --keep must be 0 or more rounds".into());
        }
        Ok(Self {
            card: card.trim().to_owned(),
            round,
            keep,
        })
    }

    /// Is `round` inside the keep window?
    pub fn keeps(&self, round: i64) -> bool {
        round >= self.round && round < self.round + self.keep
    }
}

/// Every check that can be made before a game is played: a unit the shop draws (not unknown,
/// a spell or a token) whose own Recruit effect needs no target, and a round the game can reach.
pub(crate) fn check(engine: &Engine, grant: &Grant, without: &[String]) -> Result<(), String> {
    let id = &grant.card;
    if without.contains(id) {
        return Err(format!(
            "usage: --grant {id} is also left out with --without"
        ));
    }
    let game = engine.content.borrow().new_session(0, &Array::new());
    let odds = game.borrow().unit_odds.clone().expect("unit odds");
    let library = engine.content.borrow().library.clone();
    let registry = engine.content.borrow().registry.clone();
    let Some(card) = library.borrow().get_card(id) else {
        return Err(format!("usage: --grant {id}: no such card"));
    };
    if card.borrow().is_spell() {
        return Err(format!("usage: --grant {id}: a spell, not a unit"));
    }
    if card.borrow().token {
        return Err(format!("usage: --grant {id}: a token, never in the shop"));
    }
    if odds.weight_of(id) <= 0 {
        return Err(format!("usage: --grant {id}: never drawn for the shop"));
    }
    if Recruit::targeted_recruit(&card, &registry).is_some() {
        return Err(format!(
            "usage: --grant {id}: its Recruit effect needs a target, which the harness would \
             have to choose for the bot; not supported"
        ));
    }
    let limit = engine.library.config("round_limit").unwrap_or(50);
    if grant.round > limit {
        return Err(format!(
            "usage: --grant {id}@{}: the game ends by round {limit}",
            grant.round
        ));
    }
    Ok(())
}

/// One game's handed-over copy: where it is, and what became of it.
pub(crate) struct GrantState {
    pub grant: Grant,
    /// The copy, or the golden it merged into.
    uid: Option<i64>,
    granted: bool,
    reason: Option<String>,
    slot: Option<i64>,
    displaced: Option<String>,
    /// Rounds in which it stood on the board when the round's fights began.
    held: Vec<i64>,
    /// Rounds from the grant on in which the live seat was still in the game at the fights.
    fought: Vec<i64>,
    /// Each time it left the board (or merged), by what.
    left: Vec<Value>,
    merged_round: Option<i64>,
    /// Entries taken out of the bot's action lists while the copy was kept, summed over every
    /// view (each view lists selling it, returning it and a swap per hand card again).
    hidden: i64,
    /// Golden copies of the card before the bot's last action (to follow a triple).
    goldens: Vec<i64>,
    on_board: bool,
}

impl GrantState {
    pub fn new(grant: &Grant) -> Self {
        Self {
            grant: grant.clone(),
            uid: None,
            granted: false,
            reason: None,
            slot: None,
            displaced: None,
            held: Vec::new(),
            fought: Vec::new(),
            left: Vec::new(),
            merged_round: None,
            hidden: 0,
            goldens: Vec::new(),
            on_board: false,
        }
    }

    /// At the start of the live seat's turn in the grant round, before its first view.
    pub fn hand_over(&mut self, game: &GameSessionRef, id: i64) {
        let player = game.borrow().player(id);
        if !player.borrow().alive {
            self.reason = Some("out of the game".into());
            return;
        }
        let recruit = game.borrow().recruit.clone().expect("session recruit");
        if Recruit::gain_waits(&recruit, &player) {
            self.reason = Some("hand full".into());
            return;
        }
        let slots = player.borrow().board.len() as i64;
        let free =
            (0..slots).find(|&s| Recruit::play_slot_error(&recruit, &player, s, false).is_empty());
        let slot = match free {
            Some(slot) => slot,
            None => {
                // The side's weakest unit (lowest own Attack plus Health, the lower slot on a
                // tie) leaves the game, as for the fresh copy in `league refight`.
                let weakest = player
                    .borrow()
                    .board_units()
                    .to_vec()
                    .into_iter()
                    .min_by_key(|unit| {
                        let u = unit.borrow();
                        let stats = u.stats.as_ref().expect("unit stats").borrow();
                        (stats.own_attack() + stats.own_health(), u.slot)
                    });
                let Some(weakest) = weakest else {
                    self.reason = Some("no slot to play into".into());
                    return;
                };
                let slot = weakest.borrow().slot;
                self.displaced = Some(card_of(&weakest));
                player.borrow_mut().remove_from_board(&weakest);
                slot
            }
        };
        let def = game
            .borrow()
            .library
            .as_ref()
            .expect("session library")
            .borrow()
            .get_card(&self.grant.card)
            .expect("checked grant card");
        let goldens = self.golden_uids(&player);
        let unit = game.borrow_mut().new_unit(&def, false);
        // As `Recruit::_buy` marks a bought card.
        unit.borrow_mut().bought_copies = 1;
        let uid = unit.borrow().uid;
        Recruit::_gain(&recruit, &player, &unit, -2);
        Recruit::_settle(&recruit, &player);
        // A third copy merges at once; the golden it makes is then the one played.
        let (uid, merged) = match self.position(&player, uid) {
            Some(_) => (uid, false),
            None => match self.new_golden(&player, &goldens) {
                Some(golden) => (golden, true),
                None => {
                    self.reason = Some("not in the hand after the gain".into());
                    return;
                }
            },
        };
        let Some(Place::Hand(hand)) = self.position(&player, uid) else {
            self.reason = Some("not in the hand after the gain".into());
            return;
        };
        let play = Action::Play {
            hand,
            slot,
            target: -1,
        };
        let result = GameSession::act(game, id, &harness::action_dict_for(game, id, &play));
        if !result.is_empty() {
            self.reason = Some(format!("play refused: {result}"));
            return;
        }
        self.granted = true;
        self.uid = Some(uid);
        self.slot = Some(slot);
        self.on_board = true;
        if merged {
            self.merged_round = Some(self.grant.round);
        }
    }

    /// Hide the actions that would take the copy off the board, while it is kept.
    pub fn filter(&mut self, game: &GameSessionRef, id: i64, round: i64, view: &mut BotView) {
        let Some(uid) = self.uid else {
            return;
        };
        if !self.grant.keeps(round) {
            return;
        }
        let player = game.borrow().player(id);
        let removed = match self.position(&player, uid) {
            Some(Place::Board(at)) => harness::retain_legal(view, |action| {
                !matches!(*action,
                    Action::Sell { slot } | Action::ToHand { slot }
                    | Action::Swap { slot, .. } | Action::Play { slot, .. } if slot == at)
            }),
            Some(Place::Hand(at)) => harness::retain_legal(
                view,
                |action| !matches!(*action, Action::SellHand { hand } if hand == at),
            ),
            Some(Place::Waiting) | None => 0,
        };
        self.hidden += removed as i64;
    }

    /// Before each of the live seat's actions.
    pub fn before_act(&mut self, game: &GameSessionRef, id: i64) {
        if self.uid.is_some() {
            let player = game.borrow().player(id);
            self.goldens = self.golden_uids(&player);
        }
    }

    /// After each of the live seat's actions: follow the copy through a triple, and note when
    /// it leaves the board.
    pub fn after_act(&mut self, game: &GameSessionRef, id: i64, round: i64, how: &str) {
        let Some(uid) = self.uid else {
            return;
        };
        let player = game.borrow().player(id);
        let mut place = self.position(&player, uid);
        if place.is_none() {
            let goldens = std::mem::take(&mut self.goldens);
            if let Some(golden) = self.new_golden(&player, &goldens) {
                self.uid = Some(golden);
                self.merged_round.get_or_insert(round);
                self.left
                    .push(json!({"round": round, "how": "merged into a golden", "by": how}));
                place = self.position(&player, golden);
                // The golden is followed from where the merge put it.
                self.on_board = matches!(place, Some(Place::Board(_)));
                return;
            }
        }
        self.note(round, place, how);
    }

    /// When the round's fights begin (after every turn).
    pub fn at_fight(&mut self, game: &GameSessionRef, id: i64, round: i64) {
        let Some(uid) = self.uid else {
            return;
        };
        let player = game.borrow().player(id);
        if !player.borrow().alive {
            return;
        }
        let place = self.position(&player, uid);
        self.note(round, place, "not by the bot's action");
        self.fought.push(round);
        if self.on_board {
            self.held.push(round);
        }
    }

    fn note(&mut self, round: i64, place: Option<Place>, how: &str) {
        let now = matches!(place, Some(Place::Board(_)));
        if self.on_board && !now {
            let to = if place.is_some() {
                "to the hand"
            } else {
                "gone"
            };
            self.left
                .push(json!({"round": round, "how": how, "to": to}));
        }
        if !self.on_board && now {
            self.left
                .push(json!({"round": round, "how": "back on the board"}));
        }
        self.on_board = now;
    }

    /// The game line's `grant` entry. `kept_through`: on the board in every round of the keep
    /// window that the live seat played.
    pub fn line(&self) -> Value {
        // A seat out of the game before the grant round never takes that turn.
        let reason = match (&self.reason, self.granted) {
            (None, false) => Some("out of the game".to_owned()),
            (reason, _) => reason.clone(),
        };
        let window: Vec<i64> = (self.grant.round..self.grant.round + self.grant.keep)
            .filter(|r| self.fought.contains(r))
            .collect();
        json!({
            "card": self.grant.card, "round": self.grant.round, "keep": self.grant.keep,
            "granted": self.granted, "reason": reason, "slot": self.slot,
            "displaced": self.displaced, "held_rounds": self.held.len(), "held": self.held,
            "kept_through": self.granted && window.iter().all(|r| self.held.contains(r)),
            "left": self.left, "merged_round": self.merged_round, "hidden": self.hidden,
        })
    }

    fn position(&self, player: &PlayerStateRef, uid: i64) -> Option<Place> {
        let p = player.borrow();
        if let Some(unit) = p
            .board_units()
            .to_vec()
            .into_iter()
            .find(|u| u.borrow().uid == uid)
        {
            return Some(Place::Board(unit.borrow().slot));
        }
        if let Some(i) = p.hand.to_vec().iter().position(|u| u.borrow().uid == uid) {
            return Some(Place::Hand(i as i64));
        }
        // Gained with a full hand: waiting to join it.
        p.waiting_pile
            .to_vec()
            .iter()
            .any(|u| u.borrow().uid == uid)
            .then_some(Place::Waiting)
    }

    fn golden_uids(&self, player: &PlayerStateRef) -> Vec<i64> {
        let p = player.borrow();
        p.all_cards()
            .to_vec()
            .into_iter()
            .chain(p.waiting_pile.to_vec())
            .filter(|u| u.borrow().golden && card_of(u) == self.grant.card)
            .map(|u| u.borrow().uid)
            .collect()
    }

    fn new_golden(&self, player: &PlayerStateRef, before: &[i64]) -> Option<i64> {
        self.golden_uids(player)
            .into_iter()
            .find(|uid| !before.contains(uid))
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Place {
    Board(i64),
    Hand(i64),
    Waiting,
}

fn card_of(unit: &UnitRef) -> String {
    unit.borrow()
        .def
        .as_ref()
        .expect("unit definition")
        .borrow()
        .id
        .clone()
}

/// `summary.json`'s `grant_outcome`, per live colour, from the games' `grant` entries.
pub(crate) fn outcome(lines: &[(String, Value)]) -> Value {
    let mut by: BTreeMap<String, Value> = BTreeMap::new();
    for (colour, line) in lines {
        let entry = by.entry(colour.clone()).or_insert_with(|| {
            json!({"games": 0, "granted": 0, "not_granted": {}, "displaced": 0,
                   "kept_through": 0, "held_rounds_total": 0, "held_rounds": {},
                   "merged": 0, "left_by": {}, "hidden_actions": 0})
        });
        let add = |v: &mut Value, n: i64| *v = json!(v.as_i64().unwrap_or(0) + n);
        add(&mut entry["games"], 1);
        if line["granted"] != true {
            let reason = line["reason"].as_str().unwrap_or("unknown").to_owned();
            add(&mut entry["not_granted"][reason], 1);
            continue;
        }
        add(&mut entry["granted"], 1);
        let held = line["held_rounds"].as_i64().unwrap_or(0);
        add(&mut entry["held_rounds_total"], held);
        add(&mut entry["held_rounds"][held.to_string()], 1);
        add(
            &mut entry["displaced"],
            i64::from(!line["displaced"].is_null()),
        );
        add(
            &mut entry["kept_through"],
            i64::from(line["kept_through"] == true),
        );
        add(
            &mut entry["merged"],
            i64::from(!line["merged_round"].is_null()),
        );
        add(
            &mut entry["hidden_actions"],
            line["hidden"].as_i64().unwrap_or(0),
        );
        for left in line["left"].as_array().into_iter().flatten() {
            if let Some(how) = left["how"].as_str() {
                add(&mut entry["left_by"][how], 1);
            }
        }
    }
    for entry in by.values_mut() {
        let granted = entry["granted"].as_i64().unwrap_or(0);
        let total = entry["held_rounds_total"].as_i64().unwrap_or(0);
        entry["held_rounds_mean"] = if granted > 0 {
            json!(total as f64 / granted as f64)
        } else {
            Value::Null
        };
    }
    json!(by)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_card_and_round() {
        assert_eq!(
            Grant::parse("sword-heir@7", 3),
            Ok(Grant {
                card: "sword-heir".into(),
                round: 7,
                keep: 3
            })
        );
        for bad in [
            "sword-heir",
            "sword-heir@",
            "@7",
            "sword-heir@0",
            "sword-heir@x",
        ] {
            assert!(Grant::parse(bad, 0).is_err(), "{bad}");
        }
        assert!(Grant::parse("sword-heir@7", -1).is_err());
        let g = Grant::parse("a@5", 2).unwrap();
        assert!(!g.keeps(4) && g.keeps(5) && g.keeps(6) && !g.keeps(7));
        assert!(!Grant::parse("a@5", 0).unwrap().keeps(5));
        // A seat out before the grant round never takes that turn.
        let never = GrantState::new(&g).line();
        assert_eq!(
            (never["granted"].clone(), never["reason"].clone()),
            (json!(false), json!("out of the game"))
        );
    }

    #[test]
    fn check_takes_only_units_the_shop_draws_without_a_recruit_target() {
        let root = crate::default_root();
        let engine = crate::engine_for(&root, &|| crate::load_content(&root, None)).unwrap();
        let grant = |card: &str, round: i64| Grant {
            card: card.into(),
            round,
            keep: 0,
        };
        assert_eq!(check(&engine, &grant("sword-heir", 7), &[]), Ok(()));
        for (g, without, error) in [
            (grant("nosuch", 3), vec![], "no such card"),
            (grant("sp_sharpen", 3), vec![], "a spell"),
            (grant("cousin", 3), vec![], "a token"),
            (grant("master-at-arms", 3), vec![], "needs a target"),
            (grant("sword-heir", 999), vec![], "the game ends"),
            (
                grant("sword-heir", 3),
                vec!["sword-heir".to_owned()],
                "also left out",
            ),
        ] {
            let got = check(&engine, &g, &without).unwrap_err();
            assert!(got.contains(error), "{g:?}: {got}");
        }
    }

    /// A live session in its first recruit turn, and player 0.
    fn session() -> (GameSessionRef, PlayerStateRef) {
        let content = crate::load_content(&crate::default_root(), None).unwrap();
        let game = content.borrow().new_session(5, &Array::new());
        game.borrow_mut().record_recipe.clear();
        GameSession::start_round(&game);
        let player = game.borrow().player(0);
        (game, player)
    }

    fn put(game: &GameSessionRef, player: &PlayerStateRef, card: &str, slot: i64) -> UnitRef {
        let def = game
            .borrow()
            .library
            .as_ref()
            .unwrap()
            .borrow()
            .get_card(card)
            .unwrap();
        let unit = game.borrow_mut().new_unit(&def, false);
        player.borrow_mut().place(&unit, slot);
        unit
    }

    fn view(game: &GameSessionRef) -> BotView {
        let library = std::rc::Rc::new(harness::library_of_game(game));
        harness::view_typed(game, 0, &std::rc::Rc::new(Vec::new()), &library, i64::MAX)
    }

    fn grant(card: &str, keep: i64) -> GrantState {
        GrantState::new(&Grant {
            card: card.into(),
            round: 1,
            keep,
        })
    }

    #[test]
    fn the_copy_is_played_into_the_lowest_free_slot_as_a_bought_card() {
        let (game, player) = session();
        put(&game, &player, "brock-cub", 0);
        let mut state = grant("sword-heir", 0);
        state.hand_over(&game, 0);
        let line = state.line();
        assert_eq!(line["granted"], true, "{line}");
        assert_eq!(line["slot"], 1);
        assert!(line["displaced"].is_null());
        let unit = player.borrow().board.get(1).flatten().unwrap();
        assert_eq!(card_of(&unit), "sword-heir");
        assert_eq!(unit.borrow().bought_copies, 1);
        assert!(!unit.borrow().golden);
        assert!(player.borrow().hand.is_empty());
        state.at_fight(&game, 0, 1);
        assert_eq!(state.line()["held"], json!([1]));
        assert_eq!(state.line()["kept_through"], true);
    }

    #[test]
    fn on_a_full_board_the_weakest_unit_leaves_and_the_copy_takes_its_slot() {
        let (game, player) = session();
        let recruit = game.borrow().recruit.clone().unwrap();
        let slots = player.borrow().board.len() as i64;
        let free: Vec<i64> = (0..slots)
            .filter(|&s| Recruit::play_slot_error(&recruit, &player, s, false).is_empty())
            .collect();
        assert!(free.len() >= 3, "{free:?}");
        for &slot in &free {
            put(&game, &player, "hedge-knight", slot);
        }
        // The weakest: a 2/6 Brock Cub against 2/8 Hedge Knights.
        let weak_slot = free[2];
        put(&game, &player, "brock-cub", weak_slot);
        let mut state = grant("shrew-harrier", 0);
        state.hand_over(&game, 0);
        let line = state.line();
        assert_eq!(line["granted"], true, "{line}");
        assert_eq!(line["slot"], weak_slot);
        assert_eq!(line["displaced"], "brock-cub");
        let cards: Vec<String> = player
            .borrow()
            .board_units()
            .to_vec()
            .iter()
            .map(card_of)
            .collect();
        assert!(!cards.contains(&"brock-cub".to_owned()), "{cards:?}");
        assert_eq!(cards.iter().filter(|c| *c == "shrew-harrier").count(), 1);
    }

    #[test]
    fn a_third_copy_merges_and_the_golden_is_followed() {
        let (game, player) = session();
        put(&game, &player, "sword-heir", 0);
        put(&game, &player, "sword-heir", 1);
        let mut state = grant("sword-heir", 2);
        state.hand_over(&game, 0);
        let line = state.line();
        assert_eq!(line["granted"], true, "{line}");
        assert_eq!(line["merged_round"], 1);
        let goldens: Vec<UnitRef> = player
            .borrow()
            .board_units()
            .to_vec()
            .into_iter()
            .filter(|u| u.borrow().golden)
            .collect();
        assert_eq!(goldens.len(), 1);
        assert_eq!(state.uid, Some(goldens[0].borrow().uid));
    }

    #[test]
    fn while_kept_the_bot_is_not_shown_actions_that_take_the_copy_off_the_board() {
        let (game, player) = session();
        put(&game, &player, "brock-cub", 0);
        let mut state = grant("sword-heir", 1);
        state.hand_over(&game, 0);
        let slot = state.slot.unwrap();
        let removes = |a: &Action| matches!(*a, Action::Sell { slot: s } | Action::ToHand { slot: s } if s == slot);
        let shown = view(&game);
        assert!(
            shown.legal().iter().any(removes),
            "the engine offers selling it"
        );
        let mut kept = view(&game);
        state.filter(&game, 0, 1, &mut kept);
        assert!(!kept.legal().iter().any(removes));
        assert!(
            kept.legal().contains(&Action::Sell { slot: 0 }),
            "other units still sell"
        );
        assert!(kept.legal().contains(&Action::EndTurn));
        assert_eq!(
            state.hidden,
            (shown.legal().len() - kept.legal().len()) as i64
        );
        state.at_fight(&game, 0, 1);
        // After the keep window (round 2 on), nothing is hidden.
        let mut free = view(&game);
        state.filter(&game, 0, 2, &mut free);
        assert_eq!(free.legal(), shown.legal());
        // Selling it is then noted as how it left.
        state.before_act(&game, 0);
        let sell = harness::action_dict_for(&game, 0, &Action::Sell { slot });
        assert_eq!(GameSession::act(&game, 0, &sell), "");
        state.after_act(&game, 0, 2, "sell");
        state.at_fight(&game, 0, 2);
        let line = state.line();
        assert_eq!(
            line["left"],
            json!([{"round": 2, "how": "sell", "to": "gone"}]),
            "{line}"
        );
        // Held at round 1's fight, through its one-round keep; gone by round 2's.
        assert_eq!(line["held"], json!([1]));
        assert_eq!(line["kept_through"], true);
    }

    #[test]
    fn outcome_counts_by_colour() {
        let line = |granted: bool, held: i64, displaced: Option<&str>| {
            json!({"granted": granted, "reason": if granted { Value::Null } else { json!("hand full") },
                   "held_rounds": held, "displaced": displaced, "kept_through": held >= 2,
                   "merged_round": null, "hidden": 3, "left": [{"round": 9, "how": "sell"}]})
        };
        let got = outcome(&[
            ("red".into(), line(true, 2, Some("brock-cub"))),
            ("red".into(), line(true, 4, None)),
            ("red".into(), line(false, 0, None)),
            ("blue".into(), line(true, 1, None)),
        ]);
        assert_eq!(got["red"]["games"], 3);
        assert_eq!(got["red"]["granted"], 2);
        assert_eq!(got["red"]["not_granted"]["hand full"], 1);
        assert_eq!(got["red"]["held_rounds_mean"], 3.0);
        assert_eq!(got["red"]["displaced"], 1);
        assert_eq!(got["red"]["kept_through"], 2);
        assert_eq!(got["red"]["left_by"]["sell"], 2);
        assert_eq!(got["blue"]["held_rounds"]["1"], 1);
    }
}
