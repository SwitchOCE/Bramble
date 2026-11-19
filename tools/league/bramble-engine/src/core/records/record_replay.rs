//! Mirrors src/core/records/record_replay.gd. Session-bearing dictionaries become typed results.
use crate::core::{
    content::content_set::ContentSet,
    records::{game_record::GameRecord, record_build::RecordBuild, record_state::RecordState},
    rules::game_config::GameConfig,
    session::game_session::{GameSession, GameSessionRef},
    util::core_util::CoreUtil,
};
use crate::game::game_content::GameContent;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, path::Path, rc::Rc};
pub struct RecordReplay;
#[derive(Default)]
pub struct ReplayResult {
    pub ok: bool,
    pub turn: i64,
    pub message: String,
    pub session: Option<GameSessionRef>,
    pub turns: i64,
    pub checkpoints: i64,
    pub complete: bool,
}
impl ReplayResult {
    pub fn to_dict(&self) -> Dictionary {
        if !self.ok {
            return crate::state_dict! {"ok"=>&false,"turn"=>&self.turn,"message"=>&self.message}
                .as_dict();
        }
        crate::state_dict!{"ok"=>&true,"turns"=>&self.turns,"checkpoints"=>&self.checkpoints,"complete"=>&self.complete}.as_dict()
    }
}
impl RecordReplay {
    pub fn read(repo_root: &Path, path: &Path) -> ReplayResult {
        match Self::read_entries(path) {
            Ok(entries) => Self::rebuild(repo_root, &entries),
            Err(e) => e,
        }
    }
    pub fn read_entries(path: &Path) -> Result<Array<Dictionary>, ReplayResult> {
        let text = std::fs::read_to_string(path)
            .map_err(|_| Self::_failure(0, &format!("cannot open {}", path.display())))?;
        let entries = Array::new();
        for (i, line) in text.lines().enumerate() {
            let v = crate::util::godot_json::parse_string(line);
            if !matches!(v, Variant::Dictionary(_)) {
                return Err(Self::_failure(
                    0,
                    &format!("invalid JSON at line {}", i + 1),
                ));
            }
            entries.push(v.as_dict());
        }
        Ok(entries)
    }
    pub fn rebuild(repo_root: &Path, entries: &Array<Dictionary>) -> ReplayResult {
        Self::rebuild_to(repo_root, entries, None)
    }
    /// Inclusive operation index, with the header at zero. Used by both dump drivers.
    pub fn rebuild_to(
        repo_root: &Path,
        entries: &Array<Dictionary>,
        stop_at: Option<usize>,
    ) -> ReplayResult {
        if entries.is_empty() {
            return Self::_failure(0, "empty record");
        }
        let header = entries.borrow()[0].clone();
        if header.get("op") != Variant::from("header")
            || CoreUtil::to_int(&header.get_or("format", 0.into())) != GameRecord::FORMAT
        {
            return Self::_failure(0, "unsupported record format");
        }
        let build = header.get("build").as_dict();
        if build.get("rules_hash") != RecordBuild::identity(repo_root).get("rules_hash") {
            return Self::_failure(0, "build differs; use the build that wrote the record");
        }
        let game = match Self::_create(repo_root, &header) {
            Ok(g) => g,
            Err(e) => return e,
        };
        if header.get("initial_hash").as_text() != RecordState::state_hash(&game.borrow()) {
            return Self::_failure(0, "initial state differs");
        }
        let mut phase = String::from("between");
        let mut checkpoints = 0;
        for index in 1..entries.len() {
            if stop_at.is_some_and(|stop| index > stop) {
                break;
            }
            let entry = entries.borrow()[index].clone();
            phase = match Self::_step(&game, &entry, &phase) {
                Ok(next) => next,
                Err(e) => return e,
            };
            if entry.has("hash") {
                checkpoints += 1;
            }
        }
        let turns = game.borrow().round_number;
        let complete = game.borrow().over && phase == "between";
        ReplayResult {
            ok: true,
            session: Some(game),
            turns,
            checkpoints,
            complete,
            ..ReplayResult::default()
        }
    }
    pub fn _create(repo_root: &Path, header: &Dictionary) -> Result<GameSessionRef, ReplayResult> {
        let recipe = header.get("recipe").as_dict();
        let paths: Array<String> = recipe
            .get("paths")
            .as_array()
            .borrow()
            .iter()
            .map(Variant::as_text)
            .collect();
        let tribes: Array<String> = recipe
            .get("tribes")
            .as_array()
            .borrow()
            .iter()
            .map(Variant::as_text)
            .collect();
        let config = GameConfig::from_dict(&header.get("config").as_dict())
            .map_err(|m| Self::_failure(0, &m))?;
        let config = Rc::new(RefCell::new(config));
        let seed_text = header.get_or("seed", "".into()).as_text();
        let seed = seed_text
            .parse::<i64>()
            .map_err(|_| Self::_failure(0, "invalid seed"))?;
        let game = match recipe.get("kind").as_text().as_str() {
            "game" => {
                let content = GameContent::load_folders(repo_root, &paths);
                let c = content.borrow();
                if !c.errors.is_empty() {
                    return Err(Self::_failure(
                        0,
                        &format!("content failed to load: {:?}", c.errors),
                    ));
                }
                let game =
                    GameSession::create(seed, &c.library, &c.registry, Some(config), &tribes);
                for standing in c.standing_for(&tribes).borrow().iter() {
                    game.borrow_mut().give_standing(standing);
                }
                game
            }
            "core" => {
                let content = ContentSet::load_folders(repo_root, &paths);
                let c = content.borrow();
                if !c.errors.is_empty() {
                    return Err(Self::_failure(
                        0,
                        &format!("content failed to load: {:?}", c.errors),
                    ));
                }
                let game = c.session(seed, Some(config), &tribes);
                game.borrow_mut().record_recipe = Dictionary::new();
                game
            }
            _ => return Err(Self::_failure(0, "unknown content recipe")),
        };
        game.borrow_mut().keep_fight_events = false;
        Ok(game)
    }
    pub fn _step(
        game: &GameSessionRef,
        entry: &Dictionary,
        phase: &str,
    ) -> Result<String, ReplayResult> {
        let op = entry.get_or("op", "".into()).as_text();
        let turn = CoreUtil::to_int(&entry.get_or("turn", (-1).into()));
        if !["start", "act", "end", "fight_boards", "finish"].contains(&op.as_str()) {
            return Err(Self::_failure(turn, &format!("unknown operation {op}")));
        }
        let expected = game.borrow().round_number + i64::from(op == "start");
        if turn != expected || game.borrow().over {
            return Err(Self::_failure(turn, &format!("unexpected turn at {op}")));
        }
        let next = match op.as_str() {
            "start" => {
                if phase != "between" {
                    return Err(Self::_failure(turn, "start before previous turn finished"));
                }
                GameSession::start_round(game);
                "recruit"
            }
            "act" | "end" => {
                if phase != "recruit" {
                    return Err(Self::_failure(turn, "action outside recruit"));
                }
                let player = CoreUtil::to_int(&entry.get_or("player", (-1).into()));
                if player < 0 || player >= game.borrow().players.len() as i64 {
                    return Err(Self::_failure(turn, "invalid player"));
                }
                if op == "end" {
                    GameSession::end_turn(game, player);
                } else {
                    let result = GameSession::act(game, player, &entry.get("action").as_dict());
                    if result != entry.get_or("result", "".into()).as_text() {
                        return Err(Self::_failure(
                            turn,
                            &format!("action result differs for player {player}: {result}"),
                        ));
                    }
                }
                phase
            }
            "fight_boards" => {
                if phase != "recruit" {
                    return Err(Self::_failure(turn, "fight boards outside recruit"));
                }
                let players = game.borrow().alive_players();
                for p in players.borrow().iter() {
                    let player_id = p.borrow().id;
                    GameSession::end_turn(game, player_id);
                }
                if crate::util::godot_json::stringify(&RecordState::value(&entry.get("players")))
                    != crate::util::godot_json::stringify(&Variant::Array(
                        RecordState::fight_players(&game.borrow()),
                    ))
                {
                    return Err(Self::_failure(turn, "fight boards differ"));
                }
                "fight"
            }
            "finish" => {
                if phase != "fight" {
                    return Err(Self::_failure(turn, "finish without fight boards"));
                }
                GameSession::finish_round(game);
                if game.borrow().over != CoreUtil::to_bool(&entry.get_or("over", false.into())) {
                    return Err(Self::_failure(turn, "game completion differs"));
                }
                "between"
            }
            _ => unreachable!(),
        };
        if ["start", "fight_boards", "finish"].contains(&op.as_str())
            && entry.get_or("hash", "".into()).as_text() != RecordState::state_hash(&game.borrow())
        {
            return Err(Self::_failure(turn, &format!("state hash differs at {op}")));
        }
        Ok(next.into())
    }
    pub fn _failure(turn: i64, message: &str) -> ReplayResult {
        ReplayResult {
            turn,
            message: format!("first differing turn {turn}: {message}"),
            ..ReplayResult::default()
        }
    }
}
impl ToState for RecordReplay {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
}
